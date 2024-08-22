import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/task_model.dart';

class TaskService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  Future<List<Task>> fetchTasks(String userId) async {
    final snapshot = await _db.collection('users').doc(userId).collection('tasks').get();
    return snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> addTask(Task task) async {
    final user = auth.currentUser;
    if (user != null) {
      final docRef = await _db.collection('users').doc(user.uid).collection('tasks').add(task.toMap());
      task.id = docRef.id;
    }
  }

  Future<void> updateTask(Task task) async {
    final user = auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('tasks').doc(task.id).update(task.toMap());
    }
  }

  Future<void> deleteTask(String taskId) async {
    final user = auth.currentUser;
    if (user != null) {
      await _db.collection('users').doc(user.uid).collection('tasks').doc(taskId).delete();
    }
  }
}
