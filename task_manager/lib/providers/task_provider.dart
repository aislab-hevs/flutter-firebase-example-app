import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import 'auth_provider.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _repository;
  late AuthProvider? _authProvider;

  List<Task> _tasks = [];
  bool _isLoading = false;

  List<Task> get tasks => _tasks;
  bool get isLoading => _isLoading;

  TaskProvider(this._repository);

  void updateAuthProvider(AuthProvider authProvider) {
    _authProvider = authProvider;
    _refreshTasks();
  }

  Future<void> _refreshTasks() async {
    final user = _authProvider?.user;
    if (user == null) {
      _tasks = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    _tasks = await _repository.fetchTasks(user.uid);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTask(Task task) async {
    final user = _authProvider?.user;
    if (user == null) return;
    await _repository.addTask(task, user.uid);
    _tasks.add(task);
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    final user = _authProvider?.user;
    if (user == null) return;
    await _repository.updateTask(task, user.uid);
    final index = _tasks.indexWhere((t) => t.id == task.id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
  }

  Future<void> deleteTask(String taskId) async {
    final user = _authProvider?.user;
    if (user == null) return;
    await _repository.deleteTask(taskId, user.uid);
    _tasks.removeWhere((t) => t.id == taskId);
    notifyListeners();
  }
}
