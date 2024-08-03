// homePage.dart

import 'package:flutter/material.dart';
import 'package:gis_iot/src/database/database.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<double> _recentTemperatures = [];
  double _currentTemperature = 0;
  List<String> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseHelper();
    await db.connect();
    
    // Lấy danh sách các cage
    final cages = await db.getCages();
    
    // Nếu có ít nhất một cage, lấy nhiệt độ của cage đầu tiên
    if (cages.isNotEmpty) {
      final temperatures = await db.getTemperaturesForCage(cages.first);
      await db.close();

      setState(() {
        _recentTemperatures = temperatures;
        _currentTemperature = temperatures.isNotEmpty ? temperatures.first : 0;
        _generateAlerts();
        _isLoading = false;
      });
    } else {
      await db.close();
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _generateAlerts() {
    _alerts.clear();
    if (_currentTemperature > 30) {
      _alerts.add("Cảnh báo nhiệt độ cao: ${_currentTemperature.toStringAsFixed(1)}°C");
    }
    if (_currentTemperature < 10) {
      _alerts.add("Cảnh báo nhiệt độ thấp: ${_currentTemperature.toStringAsFixed(1)}°C");
    }
    // Thêm các điều kiện cảnh báo khác nếu cần
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Trang chủ"),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                  ],
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
              "Nhiệt độ hiện tại",
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
}