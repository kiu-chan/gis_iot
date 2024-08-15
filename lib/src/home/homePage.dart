import 'package:flutter/material.dart';
import 'package:gis_iot/src/database/database.dart';
import 'package:intl/intl.dart';
import 'package:gis_iot/src/pet/petListPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<double> _recentTemperatures = [];
  double _currentTemperature = 0;
  List<String> _alerts = [];
  bool _isLoading = true;
  Cage? _currentCage;
  Task? _nextTask;
  List<Task> _completedTasksToday = [];
  List<SpeciesCount> _speciesCounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper();
      await db.connect();

      final cages = await db.getCages();

      if (cages.isNotEmpty) {
        _currentCage = cages.first;
        final temperatures = await db.getTemperaturesForCage(_currentCage!.id);

        // Lấy công việc tiếp theo cần làm
        List<Task> tasks = await db.getTasks();
        _nextTask = tasks.firstWhere(
          (task) =>
              !task.done &&
              (task.time == null || task.time!.isAfter(DateTime.now())),
          orElse: () => Task(
              id: -1, workContent: '', createdAt: DateTime.now(), done: false),
        );

        // Lấy danh sách công việc đã hoàn thành trong ngày
        _completedTasksToday = tasks
            .where((task) =>
                task.done &&
                task.time != null &&
                task.time!.year == DateTime.now().year &&
                task.time!.month == DateTime.now().month &&
                task.time!.day == DateTime.now().day)
            .toList();

        // Lấy danh sách các loài và số lượng
        _speciesCounts = await db.getSpeciesCounts();

        setState(() {
          _recentTemperatures = temperatures;
          _currentTemperature =
              temperatures.isNotEmpty ? temperatures.first : 0;
          _generateAlerts();
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }

      await db.close();
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateAlerts() {
    _alerts.clear();
    if (_currentTemperature > 30) {
      _alerts.add(
          "Cảnh báo nhiệt độ cao: ${_currentTemperature.toStringAsFixed(1)}°C");
    }
    if (_currentTemperature < 10) {
      _alerts.add(
          "Cảnh báo nhiệt độ thấp: ${_currentTemperature.toStringAsFixed(1)}°C");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trang chủ"),
        actions: [
          IconButton(
            icon: Icon(Icons.pets),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PetListPage()),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCurrentTemperature(),
                      SizedBox(height: 20),
                      _buildRecentTemperatures(),
                      SizedBox(height: 20),
                      _buildAlerts(),
                      SizedBox(height: 20),
                      _buildNextTask(),
                      SizedBox(height: 20),
                      _buildCompletedTasks(),
                      SizedBox(height: 20),
                      _buildSpeciesList(),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCurrentTemperature() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Nhiệt độ hiện tại${_currentCage != null ? ' - ${_currentCage!.name}' : ''}",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            Text(
              "${_currentTemperature.toStringAsFixed(1)}°C",
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTemperatures() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Nhiệt độ gần đây",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _recentTemperatures.length.clamp(0, 5),
              itemBuilder: (context, index) {
                return Text(
                  "${index + 1}. ${_recentTemperatures[index].toStringAsFixed(1)}°C",
                  style: Theme.of(context).textTheme.bodyLarge,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlerts() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cảnh báo",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            _alerts.isEmpty
                ? Text("Không có cảnh báo nào tại thời điểm này.")
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: Icon(Icons.warning, color: Colors.red),
                        title: Text(_alerts[index]),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextTask() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Công việc tiếp theo",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            _nextTask != null && _nextTask!.id != -1
                ? ListTile(
                    title: Text(_nextTask!.workContent),
                    subtitle: Text(_nextTask!.time != null
                        ? "Thời gian: ${DateFormat('HH:mm dd/MM/yyyy').format(_nextTask!.time!)}"
                        : "Không có thời gian cụ thể"),
                    trailing: ElevatedButton(
                      child: Text("Hoàn thành"),
                      onPressed: () => _completeTask(_nextTask!),
                    ),
                    onTap: () => _showTaskDetails(_nextTask!),
                  )
                : Text("Không có công việc nào sắp tới"),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedTasks() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Công việc đã hoàn thành hôm nay",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            Container(
              height: 200,
              child: _completedTasksToday.isEmpty
                  ? Text("Chưa có công việc nào hoàn thành hôm nay.")
                  : ListView.builder(
                      itemCount: _completedTasksToday.length,
                      itemBuilder: (context, index) {
                        final task = _completedTasksToday[index];
                        return ListTile(
                          title: Text(task.workContent),
                          subtitle: Text(task.time != null
                              ? DateFormat('HH:mm').format(task.time!)
                              : 'Không có thời gian'),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeciesList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Danh sách các loài",
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 10),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _speciesCounts.length,
              itemBuilder: (context, index) {
                final species = _speciesCounts[index];
                return ListTile(
                  title: Text(species.species),
                  trailing: Text(species.quantity.toString()),
                  onTap: () => _showPetsBySpecies(species.species),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showTaskDetails(Task task) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Chi tiết công việc'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Nội dung: ${task.workContent}'),
                SizedBox(height: 10),
                Text(
                    'Thời gian: ${task.time != null ? DateFormat('HH:mm dd/MM/yyyy').format(task.time!) : 'Không có'}'),
                SizedBox(height: 10),
                Text('Ghi chú: ${task.note ?? 'Không có'}'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _completeTask(Task task) async {
    try {
      final db = DatabaseHelper();
      await db.connect();
      await db.updateTaskStatus(task.id, true);
      await db.close();
      await _loadData(); // Reload data after completing the task
    } catch (e) {
      print('Error completing task: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi hoàn thành công việc')),
      );
    }
  }

  void _showPetsBySpecies(String species) async {
    try {
      final db = DatabaseHelper();
      await db.connect();
      List<Pet> pets = await db.getPetsBySpecies(species);
      await db.close();

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Danh sách $species'),
            content: SingleChildScrollView(
              child: ListBody(
                children: pets
                    .map((pet) => ListTile(
                          title: Text(pet.name),
                          subtitle: Text(
                              'Mã: ${pet.petCode}\nNgày sinh: ${DateFormat('dd/MM/yyyy').format(pet.bornOn)}'),
                        ))
                    .toList(),
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Đóng'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } catch (e) {
      print('Error loading pets by species: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi tải danh sách vật nuôi')),
      );
    }
  }
}
