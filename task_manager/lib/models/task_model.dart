class Task {
  final String id;
  final String title;
  final String description;
  final bool isCompleted;
  final DateTime? createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.isCompleted,
    this.createdAt,
  });

  factory Task.fromMap(Map<String, dynamic> data, String documentId) {
    return Task(
      id: documentId,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      isCompleted: data['isCompleted'] ?? false,
      createdAt: data['createdAt'] as DateTime?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'isCompleted': isCompleted,
    };
  }
}
