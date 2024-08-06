import 'package:flutter/material.dart';
import 'package:gis_iot/src/database/database.dart';
import 'package:intl/intl.dart';

class TaskPage extends StatefulWidget {
  @override
  _TaskPageState createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  List<Task> tasks = [];
  List<Task> filteredTasks = [];
  TextEditingController _taskController = TextEditingController();
  bool _isLoading = true;
  late DatabaseHelper _databaseHelper;
  String _currentFilter = 'All';
  DateTime? _selectedDate;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _databaseHelper = DatabaseHelper();
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
    });

    await _databaseHelper.connect();
    try {
      tasks = await _databaseHelper.getTasks();
      _filterTasks();
    } catch (e) {
      print('Lỗi khi tải danh sách task: $e');
    } finally {
      await _databaseHelper.close();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterTasks() {
    setState(() {
      switch (_currentFilter) {
        case 'Completed':
          filteredTasks = tasks.where((task) => task.done).toList();
          break;
        case 'Incomplete':
          filteredTasks = tasks.where((task) => !task.done).toList();
          break;
        case 'All':
          filteredTasks = List.from(tasks);
          break;
      }

      if (_selectedDate != null) {
        filteredTasks = filteredTasks.where((task) {
          return task.time != null &&
              task.time!.year == _selectedDate!.year &&
              task.time!.month == _selectedDate!.month &&
              task.time!.day == _selectedDate!.day;
        }).toList();
      }
    });
  }

  void _addTask(String workContent) async {
    if (workContent.isNotEmpty) {
      await _databaseHelper.connect();
      await _databaseHelper.addTask(workContent, null, DateTime.now());
      await _databaseHelper.close();
      _loadTasks();
      _taskController.clear();
    }
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Task Details'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Content: ${task.workContent}'),
                SizedBox(height: 10),
                Text('Time: ${task.time != null ? DateFormat('yyyy-MM-dd HH:mm').format(task.time!) : 'Not set'}'),
                SizedBox(height: 10),
                Text('Note: ${task.note ?? 'No note'}'),
                SizedBox(height: 10),
                Text('Status: ${task.done ? 'Completed' : 'Incomplete'}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Edit Note'),
              onPressed: () {
                Navigator.of(context).pop();
                _editTaskNote(task);
              },
            ),
            TextButton(
              child: Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _editTaskNote(Task task) {
    TextEditingController noteController = TextEditingController(text: task.note);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Note'),
          content: TextField(
            controller: noteController,
            decoration: InputDecoration(hintText: "Enter note"),
            maxLines: null,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () async {
                await _databaseHelper.connect();
                await _databaseHelper.updateTaskNote(task.id, noteController.text);
                await _databaseHelper.close();
                Navigator.of(context).pop();
                _loadTasks();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConfirmationDialog(String action, Function onConfirm) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm $action'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Are you sure you want to $action this task?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleTask(int id, bool currentStatus) async {
    await _showConfirmationDialog('update', () async {
      await _databaseHelper.connect();
      await _databaseHelper.updateTaskStatus(id, !currentStatus);
      await _databaseHelper.close();
      _loadTasks();
    });
  }

  void _deleteTask(int id) async {
    await _showConfirmationDialog('delete', () async {
      await _databaseHelper.connect();
      await _databaseHelper.deleteTask(id);
      await _databaseHelper.close();
      _loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Tasks'),
        actions: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue,
              ),
              child: Text(
                'Task Filters',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: Text('All Tasks'),
              onTap: () {
                setState(() {
                  _currentFilter = 'All';
                  _selectedDate = null;
                  _filterTasks();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Completed Tasks'),
              onTap: () {
                setState(() {
                  _currentFilter = 'Completed';
                  _selectedDate = null;
                  _filterTasks();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Incomplete Tasks'),
              onTap: () {
                setState(() {
                  _currentFilter = 'Incomplete';
                  _selectedDate = null;
                  _filterTasks();
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Select Date'),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate ?? DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2025),
                );
                if (picked != null && picked != _selectedDate) {
                  setState(() {
                    _selectedDate = picked;
                    _currentFilter = 'All';
                    _filterTasks();
                  });
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _taskController,
                          decoration: InputDecoration(
                            hintText: 'Enter a new task',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.add),
                        onPressed: () {
                          if (_taskController.text.isNotEmpty) {
                            _addTask(_taskController.text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter: $_currentFilter',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (_selectedDate != null)
                        Text(
                          'Date: ${DateFormat('yyyy-MM-dd').format(_selectedDate!)}',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return ListTile(
                        title: Text(
                          task.workContent,
                          style: TextStyle(
                            decoration: task.done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        subtitle: Text(
                          'Created at: ${DateFormat('yyyy-MM-dd HH:mm').format(task.createdAt)}',
                          style: TextStyle(fontSize: 12),
                        ),
                        leading: Checkbox(
                          value: task.done,
                          onChanged: (_) => _toggleTask(task.id, task.done),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteTask(task.id),
                        ),
                        onTap: () => _showTaskDetails(task),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}