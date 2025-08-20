import 'task_model.dart';

class TaskResponse {
  final int status;
  final int totalTasks;
  final List<TaskModel> data;

  TaskResponse({
    required this.status,
    required this.totalTasks,
    required this.data,
  });

  factory TaskResponse.fromJson(Map<String, dynamic> json) {
    return TaskResponse(
      status: json['status'] ?? 0,
      totalTasks: json['totalTasks'] ?? 0,
      data: (json['data'] as List<dynamic>?)
          ?.map((taskJson) => TaskModel.fromJson(taskJson))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'totalTasks': totalTasks,
      'data': data.map((task) => task.toJson()).toList(),
    };
  }

  bool get isSuccess => status == 1;
}
