enum Priority { low, medium, high }

enum TodoStatus { pending, inProgress, completed, cancelled }

class Todo {
  final String id;
  final String title;
  final String? description;
  final Priority priority;
  final TodoStatus status;
  final String category;
  final DateTime createdAt;
  final DateTime? dueDate;
  final DateTime? completedAt;

  Todo({
    required this.id,
    required this.title,
    this.description,
    required this.priority,
    required this.status,
    required this.category,
    required this.createdAt,
    this.dueDate,
    this.completedAt,
  });

  Todo copyWith({
    String? id,
    String? title,
    String? description,
    Priority? priority,
    TodoStatus? status,
    String? category,
    DateTime? createdAt,
    DateTime? dueDate,
    DateTime? completedAt,
  }) {
    return Todo(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      dueDate: dueDate ?? this.dueDate,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority.index,
      'status': status.index,
      'category': category,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'dueDate': dueDate?.millisecondsSinceEpoch,
      'completedAt': completedAt?.millisecondsSinceEpoch,
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: Priority.values[json['priority'] as int],
      status: TodoStatus.values[json['status'] as int],
      category: json['category'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      dueDate: json['dueDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['dueDate'] as int)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Todo &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.priority == priority &&
        other.status == status &&
        other.category == category &&
        other.createdAt == createdAt &&
        other.dueDate == dueDate &&
        other.completedAt == completedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        description.hashCode ^
        priority.hashCode ^
        status.hashCode ^
        category.hashCode ^
        createdAt.hashCode ^
        dueDate.hashCode ^
        completedAt.hashCode;
  }

  @override
  String toString() {
    return 'Todo(id: $id, title: $title, description: $description, priority: $priority, status: $status, category: $category, createdAt: $createdAt, dueDate: $dueDate, completedAt: $completedAt)';
  }
}