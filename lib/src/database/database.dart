import 'package:postgres/postgres.dart';
import 'package:latlong2/latlong.dart';

class MapPoint {
  final int id;
  final String name;
  final String description;
  final LatLng location;

  MapPoint({required this.id, required this.name, required this.description, required this.location});
}

class Pet {
  final int id;
  final String name;
  final DateTime bornOn;

  Pet({required this.id, required this.name, required this.bornOn});
}

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
        password: "123456" // Thay thế bằng mật khẩu thực tế
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

  Future<List<MapPoint>> getCagePoints() async {
    final results = await _connection.execute(
      "SELECT id, name, ST_AsText(geom) as geom FROM cage"
    );
    
    return results.map<MapPoint>((row) {
      String geomText = row[2].toString();
      List<String> coords = geomText.replaceAll('POINT(', '').replaceAll(')', '').split(' ');
      double longitude = double.parse(coords[0]);
      double latitude = double.parse(coords[1]);
      
      return MapPoint(
        id: row[0] as int,
        name: row[1].toString(),
        description: "Chuồng ${row[1]}",
        location: LatLng(latitude, longitude),
      );
    }).toList();
  }

  Future<List<Pet>> getPetsForCage(int cageId) async {
    final results = await _connection.execute(
      'SELECT id, name, born_on FROM pet WHERE cage_id = \$1',
      parameters: [cageId],
    );
    
    return results.map((row) => Pet(
      id: row[0] as int,
      name: row[1] as String,
      bornOn: row[2] as DateTime,
    )).toList();
  }

  Future<void> close() async {
    await _connection.close();
  }
}