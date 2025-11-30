class Task {
  final String id;
  String title;
  String? description;
  DateTime? dueDate;
  bool isDone;

  Task({
    required this.id,
    required this.title,
    this.description,
    this.dueDate,
    this.isDone = false,
  });
}
