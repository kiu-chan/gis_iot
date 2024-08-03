// database.dart

import 'package:postgres/postgres.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  late Connection _connection;

  DatabaseHelper._internal();

  Future<void> connect() async {
    _connection = await Connection.open(
      Endpoint(
        host: "192.168.2.9",
        port: 5432,
        database: "gis_iot",
        username: "postgres",
        password: "123456"  // Replace with actual password
      ),
    );
  }

  Future<List<String>> getCages() async {
    final results = await _connection.execute('SELECT DISTINCT cage FROM temperature');
    return results.map<String>((row) => row[0].toString()).toList();
  }

  Future<List<double>> getTemperaturesForCage(String cage) async {
    final results = await _connection.execute(
      'SELECT value FROM temperature WHERE cage = \$1 ORDER BY created_at DESC LIMIT 24',
      parameters: [cage],
    );
    return results.map<double>((row) => double.parse(row[0].toString())).toList();
  }

  Future<List<double>> getHumiditiesForCage(String cage) async {
    final results = await _connection.execute(
      'SELECT value FROM humidity WHERE cage = \$1 ORDER BY created_at DESC LIMIT 24',
      parameters: [cage],
    );
    return results.map<double>((row) => double.parse(row[0].toString())).toList();
  }

  Future<void> close() async {
    await _connection.close();
  }
}