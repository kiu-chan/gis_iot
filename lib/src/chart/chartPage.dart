// chartPage.dart

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:gis_iot/src/database/database.dart';

enum DataType { temperature, humidity }

class ChartPage extends StatefulWidget {
  @override
  _ChartPageState createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  List<FlSpot> _spots = [];
  bool _isLoading = true;
  List<Cage> _cages = [];
  Cage? _selectedCage;
  DataType _dataType = DataType.temperature;

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
        _loadData(_selectedCage!.id);
      } else {
        _isLoading = false;
      }
    });
  }

  Future<void> _loadData(int cageId) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final db = DatabaseHelper();
      await db.connect();
      final data = _dataType == DataType.temperature
          ? await db.getTemperaturesForCage(cageId)
          : await db.getHumiditiesForCage(cageId);
      await db.close();

      setState(() {
        _spots = data.asMap().entries.map((entry) {
          return FlSpot(entry.key.toDouble(), entry.value);
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _isLoading = false;
        _spots = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_dataType == DataType.temperature ? 'Temperature Chart' : 'Humidity Chart'),
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
                'Chart Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ExpansionTile(
              title: Text('Parameters'),
              children: [
                RadioListTile<DataType>(
                  title: Text('Temperature'),
                  value: DataType.temperature,
                  groupValue: _dataType,
                  onChanged: (DataType? value) {
                    setState(() {
                      _dataType = value!;
                      if (_selectedCage != null) {
                        _loadData(_selectedCage!.id);
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
                RadioListTile<DataType>(
                  title: Text('Humidity'),
                  value: DataType.humidity,
                  groupValue: _dataType,
                  onChanged: (DataType? value) {
                    setState(() {
                      _dataType = value!;
                      if (_selectedCage != null) {
                        _loadData(_selectedCage!.id);
                      }
                    });
                    Navigator.pop(context);
                  },
                ),
              ],
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
                      _loadData(value!.id);
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
                                return Text('${value.toInt()}${_dataType == DataType.temperature ? '°C' : '%'}');
                              },
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}');
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: true),
                        minX: 0,
                        maxX: _spots.length.toDouble() - 1,
                        minY: _spots.isEmpty ? 0 : _spots.map((spot) => spot.y).reduce((a, b) => a < b ? a : b) - 1,
                        maxY: _spots.isEmpty ? 0 : _spots.map((spot) => spot.y).reduce((a, b) => a > b ? a : b) + 1,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _spots,
                            isCurved: true,
                            color: _dataType == DataType.temperature ? Colors.red : Colors.blue,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(show: false),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}