# Task Manager — Flutter + Firebase Example App

An example application for the **Mobile Development Summer School (208.1)**.

This app is a small but complete **task manager**: users sign in, then create,
edit, complete, and delete personal tasks — optionally with an attached image.
It is intended as a **learning project** that shows how to combine Flutter with
Firebase using a clean, testable architecture.

---

## Table of contents

1. [What the app does](#what-the-app-does)
2. [Tech stack](#tech-stack)
3. [Architecture overview](#architecture-overview)
4. [Project structure](#project-structure)
5. [How the layers work together](#how-the-layers-work-together)
6. [State management with Provider](#state-management-with-provider)
7. [Data model & Firestore structure](#data-model--firestore-structure)
8. [Getting started](#getting-started)
9. [Configuration (Firebase & Cloudinary)](#configuration-firebase--cloudinary)
10. [Running the app](#running-the-app)
11. [Running the tests](#running-the-tests)
12. [Key concepts to learn from this project](#key-concepts-to-learn-from-this-project)

---

## What the app does

- **Authentication**: register and log in with email + password (Firebase Auth).
- **Tasks**: each logged-in user has their own list of tasks.
- **CRUD**: create, read, update, complete, and delete tasks.
- **Real-time**: the task list updates live via Firestore streams — no manual
  refresh needed.
- **Images**: attach a picture to a task. Images are uploaded to **Cloudinary**
  and only the resulting URL is stored in Firestore.

---

## Tech stack

| Concern              | Technology                          |
| -------------------- | ----------------------------------- |
| UI framework         | Flutter (Material)                  |
| State management     | `provider` (`ChangeNotifier`)       |
| Authentication       | `firebase_auth`                     |
| Database             | `cloud_firestore` (real-time)       |
| Image hosting        | Cloudinary (via `http` upload)      |
| Image picking        | `image_picker`                      |
| Configuration        | `flutter_dotenv` (`.env` file)      |
| Tests                | `flutter_test` + hand-written fakes |

---

## Architecture overview

The app uses a **layered architecture**. Each layer has a single
responsibility and only talks to the layer directly below it. The UI never
talks to Firebase or Cloudinary directly.

```
┌─────────────────────────────────────────────┐
│  Views & Widgets (UI)                         │  what the user sees
│  login_screen, task_list_screen, task_form…   │
└───────────────┬───────────────────────────────┘
                │ reads state / calls methods
┌───────────────▼───────────────────────────────┐
│  Providers (state management)                  │  app logic + UI state
│  AuthProvider, TaskProvider                    │
└───────────────┬───────────────────────────────┘
                │ depends on interfaces (not Firebase!)
┌───────────────▼───────────────────────────────┐
│  Repositories & Services (abstractions)        │  data access contracts
│  TaskRepository, AuthService,                  │
│  ImageStorageRepository                         │
└───────────────┬───────────────────────────────┘
                │ implemented by
┌───────────────▼───────────────────────────────┐
│  Concrete implementations                      │  the real integrations
│  FirestoreTaskRepository, FirebaseAuthService, │
│  CloudinaryImageRepository                      │
└───────────────┬───────────────────────────────┘
                │
┌───────────────▼───────────────────────────────┐
│  External services: Firebase, Cloudinary       │
└─────────────────────────────────────────────┘
```

**Why this matters:** because the providers depend on *interfaces*
(`TaskRepository`, `AuthService`, `ImageStorageRepository`) rather than concrete
Firebase classes, we can swap in **fake implementations** during tests and run
the whole app logic *without* a network or a real Firebase project.

---

## Project structure

```
task_manager/
├── lib/
│   ├── main.dart                     App entry point + provider wiring
│   ├── models/
│   │   └── task_model.dart           The Task data class (immutable)
│   ├── providers/
│   │   ├── auth_provider.dart        Auth state (user, loading, errors)
│   │   └── task_provider.dart        Task list state (streamed from Firestore)
│   ├── repositories/
│   │   ├── task_repository.dart             interface
│   │   ├── firestore_task_repository.dart   Firestore implementation
│   │   ├── image_storage_repository.dart    interface
│   │   └── cloudinary_image_repository.dart Cloudinary implementation
│   ├── services/
│   │   ├── auth_service.dart                interface
│   │   └── firebase_auth_service.dart       Firebase Auth implementation
│   ├── views/
│   │   ├── login_screen.dart
│   │   ├── task_list_screen.dart
│   │   ├── add_task_screen.dart
│   │   └── task_detail_screen.dart
│   ├── widgets/
│   │   ├── task_item.dart             one row in the task list
│   │   └── task_form.dart             shared add/edit form
│   └── utils/
│       ├── firebase_options.dart      generated Firebase config
│       ├── cloudinary_config.dart     reads Cloudinary values from .env
│       └── theme.dart                 app theme
├── test/                             unit & widget tests (mirrors lib/)
├── .env.example                      template for your local .env
└── firestore.rules                   Firestore security rules
```

---

## How the layers work together

A concrete example: **showing the task list in real time.**

1. `TaskListScreen` reads `TaskProvider` via `Provider.of` / `context.watch`.
2. `TaskProvider` subscribes to `TaskRepository.watchTasks(userId)`.
3. `FirestoreTaskRepository` returns a **stream** built from Firestore
   `.snapshots()`, ordered by `createdAt`.
4. Whenever data changes in Firestore, the stream emits a new `List<Task>`.
5. `TaskProvider` stores it and calls `notifyListeners()`.
6. The UI rebuilds automatically.

Creating, updating, or deleting a task simply writes to Firestore — the change
flows back through the same stream, so the UI never needs manual updates.

---

## State management with Provider

This project uses the **`provider`** package. The two key objects are
`ChangeNotifier`s registered in `main.dart`:

```dart
MultiProvider(
  providers: [
    Provider<ImageStorageRepository>(
      create: (_) => CloudinaryImageRepository(...),
    ),
    ChangeNotifierProvider(create: (_) => AuthProvider(FirebaseAuthService())),
    ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
      create: (_) => TaskProvider(FirestoreTaskRepository()),
      update: (_, auth, tasks) => tasks!..updateAuthProvider(auth),
    ),
  ],
  ...
)
```

- **`ChangeNotifierProvider`** exposes a `ChangeNotifier` to the widget tree.
  When it calls `notifyListeners()`, listening widgets rebuild.
- **`ChangeNotifierProxyProvider`** is used because `TaskProvider` *depends on*
  `AuthProvider`: it needs the current user's id to know whose tasks to load.
  Whenever auth changes, the proxy hands the latest `AuthProvider` to
  `TaskProvider`.
- **Dependency injection**: the providers receive their data sources through
  their constructors (`AuthProvider(FirebaseAuthService())`,
  `TaskProvider(FirestoreTaskRepository())`). This is what makes them testable.

In widgets you typically:

```dart
final tasks = context.watch<TaskProvider>().tasks;   // rebuild on change
context.read<TaskProvider>().deleteTask(id);          // call once, no rebuild
```

---

## Data model & Firestore structure

`Task` is an **immutable** value object with `copyWith`, `==`, and `hashCode`:

```dart
class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final String? imageUrl;
  final DateTime? createdAt;
}
```

In Firestore the data is stored **per user**:

```
users/{userId}/tasks/{taskId}
    title:       string
    description: string
    isCompleted: boolean
    imageUrl:    string | null
    createdAt:   timestamp (set by the server)
```

Access is restricted by `firestore.rules` so that each user can only read and
write documents under their own `users/{userId}` path.

---

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart `>=3.4`)
- An editor (VS Code or Android Studio) with the Flutter plugin
- A device or emulator
- A **Firebase** project
- A free **Cloudinary** account (for image uploads)

### Install dependencies

```bash
cd task_manager
flutter pub get
```

---

## Configuration (Firebase & Cloudinary)

### 1. Firebase

This repo already contains a generated `lib/utils/firebase_options.dart` and the
Android `google-services.json`. To point the app at **your own** Firebase
project instead, install the FlutterFire CLI and run:

```bash
flutterfire configure
```

Then, in the Firebase console:

- enable **Authentication → Email/Password**
- create a **Cloud Firestore** database
- deploy the security rules:

  ```bash
  firebase deploy --only firestore:rules
  ```

### 2. Cloudinary (image uploads)

Images are uploaded directly from the app using an **unsigned upload preset**,
so no secret key is ever stored in the app.

1. Create a free Cloudinary account.
2. In **Settings → Upload → Upload presets**, create a preset with
   **Signing Mode = Unsigned**.
3. Copy the example env file and fill in your values:

   ```bash
   cp .env.example .env
   ```

   ```env
   CLOUDINARY_CLOUD_NAME=your_cloud_name
   CLOUDINARY_UPLOAD_PRESET=your_unsigned_upload_preset
   ```

> ⚠️ The `.env` file is **git-ignored** — never commit it. Each developer keeps
> their own. Never put your Cloudinary **API secret** in the app; only the
> cloud name and the unsigned preset are needed.

---

## Running the app

```bash
cd task_manager
flutter run
```

On first launch you will see the login screen. Create an account, then start
adding tasks.

---

## Running the tests

```bash
cd task_manager
flutter test
```

The tests use **hand-written fakes** (`test/fakes.dart`) instead of real
Firebase, and a mock HTTP client for the Cloudinary upload. They cover:

- `AuthProvider` — loading/error state and auth-state changes
- `TaskProvider` — stream subscription and CRUD forwarding
- `CloudinaryImageRepository` — upload request, success, and failure
- `Task` model — serialization and `copyWith`
- `LoginScreen` — an example widget test

---

## Key concepts to learn from this project

- **Layered architecture** and separation of concerns
- **Programming to an interface**, not an implementation
- **Dependency injection** via constructors
- **`provider` / `ChangeNotifier`** for state management
- **`ChangeNotifierProxyProvider`** for cross-provider dependencies
- **Firestore real-time streams** (`.snapshots()`)
- **Firestore security rules** (per-user data isolation)
- **Using a third-party service** (Cloudinary) alongside Firebase
- **Configuration via `.env`** instead of hard-coded values
- **Testing** business logic without a backend, using fakes/mocks

---