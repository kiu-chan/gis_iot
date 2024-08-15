import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gis_iot/src/database/database.dart';
import 'package:intl/intl.dart';

class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<FlSpot> _temperatureSpots = [];
  List<FlSpot> _humiditySpots = [];
  bool _isLoading = true;
  List<Cage> _cages = [];
  Cage? _selectedCage;
  DateTime _selectedDate = DateTime.now();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _timeFormat = DateFormat('HH:mm');
  double _minX = 0;
  double _maxX = 24;

  @override
  void initState() {
    super.initState();
    _loadCages();
  }

  Future<void> _loadCages() async {
    final db = DatabaseHelper();
    await db.connect();
    final cages = await db.getCages();
    await db.close();

    setState(() {
      _cages = cages;
      if (cages.isNotEmpty) {
        _selectedCage = cages.first;
        _loadData();
      } else {
        _isLoading = false;
      }
    });
  }

  Future<void> _loadData() async {
    if (_selectedCage == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper();
      await db.connect();
      final temperatures = await db.getTemperaturesForCageAndDate(_selectedCage!.id, _selectedDate);
      final humidities = await db.getHumiditiesForCageAndDate(_selectedCage!.id, _selectedDate);
      await db.close();

      setState(() {
        _temperatureSpots = _convertToSpots(temperatures);
        _humiditySpots = _convertToSpots(humidities);
        _updateXAxisRange();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _temperatureSpots = [];
        _humiditySpots = [];
      });
    }
  }

  List<FlSpot> _convertToSpots(List<Map<String, dynamic>> data) {
    return data.map((item) {
      final hours = item['timestamp'].hour + (item['timestamp'].minute / 60);
      return FlSpot(hours, item['value']);
    }).toList();
  }

  void _updateXAxisRange() {
    if (_temperatureSpots.isNotEmpty || _humiditySpots.isNotEmpty) {
      final allSpots = [..._temperatureSpots, ..._humiditySpots];
      _minX = allSpots.map((spot) => spot.x).reduce((a, b) => a < b ? a : b);
      _maxX = allSpots.map((spot) => spot.x).reduce((a, b) => a > b ? a : b);
    } else {
      _minX = 0;
      _maxX = 24;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _loadData();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Temperature and Humidity Chart'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
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
                'Chart Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ExpansionTile(
              title: Text('Cages'),
              children: _cages.map((cage) {
                return RadioListTile<Cage>(
                  title: Text(cage.name),
                  value: cage,
                  groupValue: _selectedCage,
                  onChanged: (Cage? value) {
                    setState(() {
                      _selectedCage = value;
                      _loadData();
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Selected Cage: ${_selectedCage?.name ?? "None"}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Date: ${_dateFormat.format(_selectedDate)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  SizedBox(height: 16),
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}');
                              },
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}%');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 3,
                              getTitlesWidget: (value, meta) {
                                final time = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, value.toInt(), (value % 1 * 60).toInt());
                                return Text(_timeFormat.format(time));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        minX: _minX,
                        maxX: _maxX,
                        minY: 0,
                        maxY: 100,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _temperatureSpots,
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                          LineChartBarData(
                            spots: _humiditySpots,
                            isCurved: true,
                            color: Colors.blue,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.thermostat, color: Colors.red),
                      Text(' Temperature'),
                      SizedBox(width: 20),
                      Icon(Icons.opacity, color: Colors.blue),
                      Text(' Humidity'),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}