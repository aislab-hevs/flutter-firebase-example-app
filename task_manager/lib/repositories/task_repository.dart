import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/task_model.dart';

class TaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Task>> fetchTasks(String userId) async {
    final snapshot = await _db
        .collection('users')
        .doc(userId)
        .collection('tasks')
        .get();
    return snapshot.docs.map((doc) => Task.fromMap(doc.data(), doc.id)).toList();
  }

  Future<void> addTask(Task task, String userId) async {
    final docRef = await _db.collection('users').doc(userId).collection('tasks').add(task.toMap());
    task.id = docRef.id;
  }

  Future<void> updateTask(Task task, String userId) async {
    await _db.collection('users').doc(userId).collection('tasks').doc(task.id).update(task.toMap());
  }

  Future<void> deleteTask(String taskId, String userId) async {
    await _db.collection('users').doc(userId).collection('tasks').doc(taskId).delete();
  }
}
