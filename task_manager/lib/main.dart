import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:task_manager/repositories/task_repository.dart';
import 'package:task_manager/utils/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/task_provider.dart';
import 'views/login_screen.dart';
import 'views/task_list_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (_) => TaskProvider(TaskRepository()),
          update: (_, authProvider, taskProvider) =>
          taskProvider!..updateAuthProvider(authProvider),
        ),
      ],
      child: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'Task Manager App',
            theme: buildThemeData(),
            home: auth.user != null ? const TaskListScreen() : const LoginScreen(),
          );
        },
      ),
    );


  }
}
