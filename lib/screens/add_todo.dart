import 'package:core_pmc/core/constants/app_colors.dart';
import 'package:core_pmc/core/utils/snackbar_utils.dart';
import 'package:core_pmc/widgets/custom_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'to_do_list.dart';

class AddTodoScreen extends StatefulWidget {
  final Function(TodoItem) onTodoAdded;

  const AddTodoScreen({Key? key, required this.onTodoAdded}) : super(key: key);

  @override
  State<AddTodoScreen> createState() => _AddTodoScreenState();
}

class _AddTodoScreenState extends State<AddTodoScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TodoPriority _priority = TodoPriority.medium;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveTodo() {
    if (_titleController.text.isEmpty) {
      SnackBarUtils.showError(context, message: "Please enter a title");

      return;
    }

    final newTodo = TodoItem(
      title: _titleController.text,
      description: _descriptionController.text,
      dueDate: _selectedDate,
      priority: _priority,
      isCompleted: false,
    );

    widget.onTodoAdded(newTodo);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,


      appBar: CustomAppBar(title: "Add New Task", showDrawer: false, showBackButton: true,),


      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Task Title'),
            _buildTextField(
              controller: _titleController,
              hintText: 'Enter task title',
            ),
            SizedBox(height: 20),

            _buildSectionTitle('Description'),
            _buildTextField(
              controller: _descriptionController,
              hintText: 'Enter task description',
              maxLines: 3,
            ),
            SizedBox(height: 20),

            _buildSectionTitle('Due Date'),
            InkWell(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text(
                      _selectedDate == null
                          ? 'Select due date'
                          : DateFormat('dd MMM yyyy').format(_selectedDate!),
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            _buildSectionTitle('Priority'),
            Row(
              children: TodoPriority.values.map((priority) {
                return Expanded(
                  child: Container(


                    child: RadioListTile<TodoPriority>(
                      visualDensity: const VisualDensity(
                          horizontal: VisualDensity.minimumDensity,
                          vertical: VisualDensity.minimumDensity),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      contentPadding: EdgeInsets.zero,
                      title: Text(priority.name.toUpperCase(), style: TextStyle(fontSize: 14),),
                      value: priority,
                      groupValue: _priority,
                      onChanged: (TodoPriority? value) {
                        setState(() {
                          _priority = value!;
                        });
                      },
                      activeColor: priority.color,
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _saveTodo,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Add Task',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: AppColors.primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
} 