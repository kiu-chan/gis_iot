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
  final String petCode;

  Pet({required this.id, required this.name, required this.bornOn, required this.petCode});
}

class Cage {
  final int id;
  final String name;

  Cage({required this.id, required this.name});
}

class Task {
  final int id;
  final String workContent;
  final String? note;
  final int? petId;
  final DateTime? time;
  final DateTime createdAt;
  bool done;

  Task({
    required this.id,
    required this.workContent,
    this.note,
    this.petId,
    this.time,
    required this.createdAt,
    required this.done,
  });
}

class PetWithCage {
  final int id;
  final String name;
  final DateTime bornOn;
  final String petCode;
  final String cageName;

  PetWithCage({
    required this.id,
    required this.name,
    required this.bornOn,
    required this.petCode,
    required this.cageName,
  });
}

class SpeciesCount {
  final String species;
  final int quantity;

  SpeciesCount({required this.species, required this.quantity});
}

class MedicalHistory {
  final int id;
  final int petId;
  final DateTime examinationDate;
  final String? symptoms;
  final String? diagnosis;
  final String? treatment;
  final String? veterinarian;
  final String? notes;
  final DateTime createdAt;
  final String? currentStatus;

  MedicalHistory({
    required this.id,
    required this.petId,
    required this.examinationDate,
    this.symptoms,
    this.diagnosis,
    this.treatment,
    this.veterinarian,
    this.notes,
    required this.createdAt,
    this.currentStatus,
  });
}

class DatabaseHelper {
  PostgreSQLConnection? connection;

  Future<void> connect() async {
    connection = PostgreSQLConnection(
      '172.20.10.4',
      5432,
      'gis_iot',
      username: 'postgres',
      password: '123456',
    );
    await connection!.open();
    print('Connected to PostgreSQL database.');
  }

  Future<List<Cage>> getCages() async {
    try {
      final results = await connection!.query('SELECT id, name FROM cage');
      return results.map((row) => Cage(id: row[0] as int, name: row[1] as String)).toList();
    } catch (e) {
      print('Lỗi khi truy vấn danh sách cage: $e');
      return [];
    }
  }

  Future<List<double>> getTemperaturesForCage(int cageId) async {
    try {
      final results = await connection!.query(
        'SELECT value FROM temperature WHERE cage_id = @cageId ORDER BY created_at DESC LIMIT 24',
        substitutionValues: {'cageId': cageId},
      );
      return results.map<double>((row) => double.parse(row[0].toString())).toList();
    } catch (e) {
      print('Lỗi khi truy vấn nhiệt độ cho cage: $e');
      return [];
    }
  }

  Future<List<double>> getHumiditiesForCage(int cageId) async {
    try {
      final results = await connection!.query(
        'SELECT value FROM humidity WHERE cage_id = @cageId ORDER BY created_at DESC LIMIT 24',
        substitutionValues: {'cageId': cageId},
      );
      return results.map<double>((row) => double.parse(row[0].toString())).toList();
    } catch (e) {
      print('Lỗi khi truy vấn độ ẩm cho cage: $e');
      return [];
    }
  }

  Future<List<MapPoint>> getCagePoints() async {
    try {
      final results = await connection!.query(
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
    } catch (e) {
      print('Lỗi khi truy vấn điểm cage: $e');
      return [];
    }
  }

  Future<List<Pet>> getPetsForCage(int cageId) async {
    try {
      final results = await connection!.query(
        'SELECT id, name, born_on, pet_code FROM pet WHERE cage_id = @cageId',
        substitutionValues: {'cageId': cageId},
      );
      
      return results.map((row) => Pet(
        id: row[0] as int,
        name: row[1] as String,
        bornOn: row[2] as DateTime,
        petCode: row[3] as String,
      )).toList();
    } catch (e) {
      print('Lỗi khi truy vấn danh sách pet cho cage: $e');
      return [];
    }
  }

  Future<double?> getLatestTemperatureForCage(int cageId) async {
    try {
      final results = await connection!.query(
        'SELECT value FROM temperature WHERE cage_id = @cageId ORDER BY created_at DESC LIMIT 1',
        substitutionValues: {'cageId': cageId},
      );
      if (results.isNotEmpty) {
        return double.parse(results[0][0].toString());
      }
      return null;
    } catch (e) {
      print('Lỗi khi truy vấn nhiệt độ mới nhất cho cage: $e');
      return null;
    }
  }

  Future<double?> getLatestHumidityForCage(int cageId) async {
    try {
      final results = await connection!.query(
        'SELECT value FROM humidity WHERE cage_id = @cageId ORDER BY created_at DESC LIMIT 1',
        substitutionValues: {'cageId': cageId},
      );
      if (results.isNotEmpty) {
        return double.parse(results[0][0].toString());
      }
      return null;
    } catch (e) {
      print('Lỗi khi truy vấn độ ẩm mới nhất cho cage: $e');
      return null;
    }
  }

  Future<List<Task>> getTasks() async {
    try {
      final results = await connection!.query('''
        SELECT id, work_content, note, pet_id, time, created_at, done 
        FROM tasks 
        ORDER BY created_at DESC
      ''');
      
      return results.map((row) => Task(
        id: row[0] as int,
        workContent: row[1] as String,
        note: row[2] as String?,
        petId: row[3] as int?,
        time: row[4] as DateTime?,
        createdAt: row[5] as DateTime,
        done: row[6] as bool,
      )).toList();
    } catch (e) {
      print('Lỗi khi truy vấn danh sách task: $e');
      return [];
    }
  }

  Future<void> updateTaskStatus(int id, bool isDone) async {
    try {
      await connection!.query(
        'UPDATE tasks SET done = @isDone WHERE id = @id',
        substitutionValues: {
          'isDone': isDone,
          'id': id,
        },
      );
    } catch (e) {
      print('Lỗi khi cập nhật trạng thái task: $e');
    }
  }

  Future<void> addTask(String workContent, int? petId, DateTime? time) async {
    try {
      await connection!.query(
        'INSERT INTO tasks (work_content, pet_id, time) VALUES (@workContent, @petId, @time)',
        substitutionValues: {
          'workContent': workContent,
          'petId': petId,
          'time': time,
        },
      );
    } catch (e) {
      print('Lỗi khi thêm task mới: $e');
    }
  }

  Future<void> deleteTask(int id) async {
    try {
      await connection!.query(
        'DELETE FROM tasks WHERE id = @id',
        substitutionValues: {
          'id': id,
        },
      );
    } catch (e) {
      print('Lỗi khi xóa task: $e');
    }
  }

  Future<void> updateTaskNote(int id, String note) async {
    try {
      await connection!.query(
        'UPDATE tasks SET note = @note WHERE id = @id',
        substitutionValues: {
          'note': note,
          'id': id,
        },
      );
    } catch (e) {
      print('Lỗi khi cập nhật ghi chú task: $e');
    }
  }

  Future<List<SpeciesCount>> getSpeciesCounts() async {
    try {
      final results = await connection!.query('SELECT species, quantity FROM species_count');
      return results.map((row) => SpeciesCount(
        species: row[0] as String,
        quantity: row[1] as int,
      )).toList();
    } catch (e) {
      print('Lỗi khi truy vấn danh sách species_count: $e');
      return [];
    }
  }

  Future<List<Pet>> getPetsBySpecies(String species) async {
    try {
      final results = await connection!.query(
        'SELECT id, name, born_on, pet_code FROM pet WHERE species = @species',
        substitutionValues: {'species': species},
      );
      
      return results.map((row) => Pet(
        id: row[0] as int,
        name: row[1] as String,
        bornOn: row[2] as DateTime,
        petCode: row[3] as String,
      )).toList();
    } catch (e) {
      print('Lỗi khi truy vấn danh sách pet cho loài: $e');
      return [];
    }
  }

Future<List<PetWithCage>> getAllPetsWithCage() async {
  try {
    final results = await connection!.query('''
      SELECT p.id, p.name, p.born_on, p.pet_code, c.name as cage_name
      FROM pet p
      JOIN cage c ON p.cage_id = c.id
    ''');
    
    return results.map((row) => PetWithCage(
      id: row[0] as int,
      name: row[1] as String,
      bornOn: row[2] as DateTime,
      petCode: row[3] as String,
      cageName: row[4] as String,
    )).toList();
  } catch (e) {
    print('Lỗi khi truy vấn danh sách tất cả pet với cage: $e');
    return [];
  }
}

  Future<List<MedicalHistory>> getMedicalHistoryForPet(int petId) async {
    try {
      final results = await connection!.query('''
        SELECT id, pet_id, examination_date, symptoms, diagnosis, treatment, 
               veterinarian, notes, created_at, current_status
        FROM medical_history
        WHERE pet_id = @petId
        ORDER BY examination_date DESC
      ''', substitutionValues: {'petId': petId});

      return results.map((row) => MedicalHistory(
        id: row[0] as int,
        petId: row[1] as int,
        examinationDate: row[2] as DateTime,
        symptoms: row[3] as String?,
        diagnosis: row[4] as String?,
        treatment: row[5] as String?,
        veterinarian: row[6] as String?,
        notes: row[7] as String?,
        createdAt: row[8] as DateTime,
        currentStatus: row[9] as String?,
      )).toList();
    } catch (e) {
      print('Lỗi khi truy vấn lịch sử sức khỏe cho pet: $e');
      return [];
    }
  }

  Future<void> close() async {
    await connection!.close();
    print('Connection closed.');
  }
}