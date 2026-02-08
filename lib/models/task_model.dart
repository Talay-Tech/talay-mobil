enum TaskStatus { todo, inProgress, done }

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final TaskStatus status;
  final String assignedTo;
  final String createdBy;
  final DateTime? dueDate;
  final DateTime createdAt;

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.assignedTo,
    required this.createdBy,
    this.dueDate,
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: _parseStatus(json['status'] as String),
      assignedTo: json['assigned_to'] as String,
      createdBy: json['created_by'] as String,
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static TaskStatus _parseStatus(String status) {
    switch (status) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  String get statusString {
    switch (status) {
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
      default:
        return 'todo';
    }
  }

  String get statusLabel {
    switch (status) {
      case TaskStatus.inProgress:
        return 'Devam Ediyor';
      case TaskStatus.done:
        return 'Tamamlandı';
      default:
        return 'Bekliyor';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': statusString,
      'assigned_to': assignedTo,
      'created_by': createdBy,
      'due_date': dueDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    String? assignedTo,
    String? createdBy,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      assignedTo: assignedTo ?? this.assignedTo,
      createdBy: createdBy ?? this.createdBy,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
