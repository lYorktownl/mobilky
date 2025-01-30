import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'users_page.dart';

class TasksPage extends StatefulWidget {
  final List<User> users;

  TasksPage({required this.users});

  @override
  _TasksPageState createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  final List<Task> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? tasksJson = prefs.getString('tasks');
      if (tasksJson != null) {
        final List<dynamic> tasksList = jsonDecode(tasksJson);
        setState(() {
          _tasks.clear();
          _tasks.addAll(tasksList.map((json) => Task.fromJson(json)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to load tasks. Please try again later.'),
      ));
    }
  }

  Future<void> _saveTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String tasksJson = jsonEncode(_tasks.map((task) => task.toJson()).toList());
      await prefs.setString('tasks', tasksJson);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to save tasks. Please try again later.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        itemCount: _tasks.length,
        itemBuilder: (context, index) {
          final task = _tasks[index];
          return ListTile(
            title: Text(task.title),
            subtitle: Text(
              '${task.description}\nDue: ${DateFormat.yMd().add_jm().format(task.dueDate)}\nAssignee: ${task.assignee?.name ?? "Unassigned"}',
            ),
            isThreeLine: true,
            tileColor: task.dueDate.isBefore(DateTime.now()) ? Colors.red[50] : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditTaskDialog(context, task, index),
                ),
                IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () => _deleteTask(index),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        users: widget.users,
        onSave: (title, description, dueDate, assignee) {
          if (title.isNotEmpty && description.isNotEmpty && dueDate != null) {
            setState(() {
              _tasks.add(Task(
                title: title,
                description: description,
                dueDate: dueDate,
                assignee: assignee,
              ));
            });
            _saveTasks();
          }
        },
      ),
    );
  }

  void _showEditTaskDialog(BuildContext context, Task task, int index) {
    showDialog(
      context: context,
      builder: (context) => TaskDialog(
        users: widget.users,
        initialTitle: task.title,
        initialDescription: task.description,
        initialDueDate: task.dueDate,
        initialAssignee: task.assignee,
        onSave: (title, description, dueDate, assignee) {
          if (title.isNotEmpty && description.isNotEmpty) {
            setState(() {
              _tasks[index] = Task(
                title: title,
                description: description,
                dueDate: dueDate,
                assignee: assignee,
              );
            });
            _saveTasks();
          }
        },
      ),
    );
  }

  void _deleteTask(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Delete Task'),
          content: Text('Are you sure you want to delete this task?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _tasks.removeAt(index);
                });
                _saveTasks();
                Navigator.of(context).pop();
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

class TaskDialog extends StatefulWidget {
  final List<User> users;
  final Function(String title, String description, DateTime dueDate, User? assignee) onSave;
  final String? initialTitle;
  final String? initialDescription;
  final DateTime? initialDueDate;
  final User? initialAssignee;

  const TaskDialog({
    required this.users,
    required this.onSave,
    this.initialTitle,
    this.initialDescription,
    this.initialDueDate,
    this.initialAssignee,
    Key? key,
  }) : super(key: key);

  @override
  _TaskDialogState createState() => _TaskDialogState();
}

class _TaskDialogState extends State<TaskDialog> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.initialTitle ?? '';
    _descriptionController.text = widget.initialDescription ?? '';
    _selectedDate = widget.initialDueDate;
    _selectedUser = widget.initialAssignee;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTitle == null ? 'Add Task' : 'Edit Task'),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 8.0),
            DropdownButton<User>(
              value: _selectedUser,
              hint: Text('Select Assignee'),
              items: widget.users.map((user) {
                return DropdownMenuItem(
                  value: user,
                  child: Text(user.name),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedUser = value;
                });
              },
            ),
            TextButton(
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_selectedDate ?? DateTime.now()),
                  );
                  if (time != null) {
                    setState(() {
                      _selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                }
              },
              child: Text('Select Due Date'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_titleController.text.isNotEmpty &&
                _descriptionController.text.isNotEmpty &&
                _selectedDate != null) {
              widget.onSave(
                _titleController.text,
                _descriptionController.text,
                _selectedDate!,
                _selectedUser,
              );
              Navigator.of(context).pop();
            }
          },
          child: Text('Save'),
        ),
      ],
    );
  }
}

class Task {
  final String title;
  final String description;
  final DateTime dueDate;
  final User? assignee;

  Task({
    required this.title,
    required this.description,
    required this.dueDate,
    this.assignee,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'dueDate': dueDate.toIso8601String(),
    'assignee': assignee?.toJson(),
  };

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      title: json['title'],
      description: json['description'],
      dueDate: DateTime.parse(json['dueDate']),
      assignee: json['assignee'] != null ? User.fromJson(json['assignee']) : null,
    );
  }
}