import 'package:core_pmc/core/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../core/utils/snackbar_utils.dart';
import 'add_todo.dart';

enum TodoPriority { low, medium, high }

extension PriorityColor on TodoPriority {
  Color get color {
    switch (this) {
      case TodoPriority.low:
        return Colors.green;
      case TodoPriority.medium:
        return Colors.orange;
      case TodoPriority.high:
        return Colors.red;
    }
  }
}

class TodoItem {
  String? id;
  String title;
  String description;
  DateTime? dueDate;
  bool isCompleted;
  TodoPriority priority;

  TodoItem({
    this.id,
    required this.title,
    required this.description,
    this.dueDate,
    this.isCompleted = false,
    this.priority = TodoPriority.medium,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    return !isCompleted && dueDate!.isBefore(DateTime.now());
  }

  TodoItem copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
    TodoPriority? priority,
  }) {
    return TodoItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      priority: priority ?? this.priority,
    );
  }
}

class ToDoList extends StatefulWidget {
  const ToDoList({Key? key}) : super(key: key);

  @override
  _ToDoListState createState() => _ToDoListState();
}

class _ToDoListState extends State<ToDoList> {
  final FirebaseService _firebaseService = FirebaseService();

  List<TodoItem> _todos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTodos();
  }

  void _loadTodos() async {
    final currentUser = AuthService.currentUser;
    
    if (currentUser != null) {
      _firebaseService.getTodosStream(currentUser.id.toString()).listen((todos) {
        setState(() {
          _todos = todos;
          _isLoading = false;
        });
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addTodo(TodoItem todo) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await _firebaseService.addTodo(todo, currentUser.id.toString());
      } else {
        SnackBarUtils.showError(context, message: 'User not authenticated');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error adding todo: $e');
    }
  }

  Future<void> _updateTodo(TodoItem todo) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await _firebaseService.updateTodo(
          todo.id!,
          todo,
          currentUser.id.toString(),
        );
      } else {
        SnackBarUtils.showError(context, message: 'User not authenticated');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error updating todo: $e');
    }
  }

  Future<void> _deleteTodo(String id) async {
    try {
      final currentUser = AuthService.currentUser;
      if (currentUser != null) {
        await _firebaseService.deleteTodo(id, currentUser.id.toString());
      } else {
        SnackBarUtils.showError(context, message: 'User not authenticated');
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error deleting todo: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final incompleteTasks = _todos.where((item) => !item.isCompleted).toList();
    final completedTasks = _todos.where((item) => item.isCompleted).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: CustomAppBar(
        title: "To-Do List",
        showDrawer: false,
        showBackButton: true,
      ),

      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _todos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.task_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No tasks added yet',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                if (incompleteTasks.isNotEmpty) ...[
                  _buildSectionHeader('Pending Tasks'),
                  ...incompleteTasks.map((item) => _buildTodoCard(item)),
                ],
                if (completedTasks.isNotEmpty) ...[
                  SizedBox(height: 16),
                  _buildSectionHeader('Completed Tasks'),
                  ...completedTasks.map((item) => _buildTodoCard(item)),
                ],
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddTodoScreen(onTodoAdded: _addTodo),
            ),
          );
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.add),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTodoCard(TodoItem item) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: item.priority.color.withValues(alpha: 0.3), width: 1),
      ),
      child: ExpansionTile(
        leading: Checkbox(
          value: item.isCompleted,
          activeColor: AppColors.primary,
          onChanged: (bool? value) {
            if (value != null && item.id != null) {
              _updateTodo(item.copyWith(isCompleted: value));
            }
          },
        ),
        title: Text(
          item.title,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
            color: item.isCompleted ? Colors.grey : Colors.black,
          ),
        ),
        subtitle: item.dueDate != null
            ? Text(
                'Due: ${DateFormat('dd MMM yyyy').format(item.dueDate!)}',
                style: TextStyle(
                  color: item.isOverdue ? Colors.red : Colors.grey,
                ),
              )
            : null,
        trailing: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: item.priority.color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: item.priority.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
        children: [
          if (item.description.isNotEmpty)
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      item.description,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      if (item.id != null) {
                        _deleteTodo(item.id!);
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}





class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'todos';

  // Add a new todo
  Future<void> addTodo(TodoItem todo, String userId) async {
    try {
      await _firestore.collection(_collection).add({
        'title': todo.title,
        'description': todo.description,
        'dueDate': todo.dueDate?.toIso8601String(),
        'isCompleted': todo.isCompleted,
        'priority': todo.priority.index,
        'userId': userId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding todo: $e');
      rethrow;
    }
  }

  // Update a todo
  Future<void> updateTodo(String id, TodoItem todo, String userId) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'title': todo.title,
        'description': todo.description,
        'dueDate': todo.dueDate?.toIso8601String(),
        'isCompleted': todo.isCompleted,
        'priority': todo.priority.index,
        'userId': userId,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating todo: $e');
      rethrow;
    }
  }

  // Delete a todo
  Future<void> deleteTodo(String id, String userId) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      print('Error deleting todo: $e');
      rethrow;
    }
  }

  // Get todos stream for a specific user
  Stream<List<TodoItem>> getTodosStream(String userId) {
    return _firestore
        .collection(_collection)
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final todos = snapshot.docs.map((doc) {
        final data = doc.data();
        return TodoItem(
          id: doc.id,
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          dueDate: data['dueDate'] != null
              ? DateTime.parse(data['dueDate'])
              : null,
          isCompleted: data['isCompleted'] ?? false,
          priority: TodoPriority.values[data['priority'] ?? 1],
        );
      }).toList();

      // Sort the todos by createdAt locally
      todos.sort((a, b) {
        final aData = snapshot.docs.firstWhere((doc) => doc.id == a.id).data();
        final bData = snapshot.docs.firstWhere((doc) => doc.id == b.id).data();
        final aTimestamp = aData['createdAt'] as Timestamp?;
        final bTimestamp = bData['createdAt'] as Timestamp?;
        if (aTimestamp == null || bTimestamp == null) return 0;
        return bTimestamp.compareTo(aTimestamp); // Descending order
      });

      return todos;
    });
  }
}