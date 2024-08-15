import 'package:postgres/postgres.dart';
import 'package:latlong2/latlong.dart';

class MapPoint {
  final int id;
  final String name;
  final String description;
  final LatLng location;

  MapPoint(
      {required this.id,
      required this.name,
      required this.description,
      required this.location});
}

class Pet {
  final int id;
  final String name;
  final DateTime bornOn;
  final String petCode;
  final String species;
  final int cageId;

  Pet(
      {required this.id,
      required this.name,
      required this.bornOn,
      required this.petCode,
      required this.species,
      required this.cageId});
}

class Cage {
  final int id;
  final String name;
  final LatLng location;

  Cage({required this.id, required this.name, required this.location});
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
  PostgreSQLConnection? _connection;

  Future<void> connect() async {
    _connection = PostgreSQLConnection(
      '192.168.1.238',
      5432,
      'gis_iot',
      username: 'postgres',
      password: '123456',
    );
    await _connection!.open();
    print('Connected to PostgreSQL database.');
  }

  Future<List<Cage>> getCages() async {
    final results = await _connection!.query('''
      SELECT id, name, ST_X(geom) as longitude, ST_Y(geom) as latitude
      FROM cages
    ''');
    return results.map((row) {
      return Cage(
        id: row[0] as int,
        name: row[1] as String,
        location: LatLng(row[3] as double, row[2] as double),
      );
    }).toList();
  }

  Future<List<double>> getTemperaturesForCage(int cageId) async {
    final results = await _connection!.query(
      'SELECT value FROM temperatures WHERE cage_id = @cageId ORDER BY created_at DESC LIMIT 24',
      substitutionValues: {'cageId': cageId},
    );
    return results.map<double>((row) {
      if (row[0] == null) return 0.0; // or another default value
      // Safely parse the string to double
      return double.tryParse(row[0].toString()) ?? 0.0;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getTemperaturesForCageAndDate(
      int cageId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final results = await _connection!.query(
      'SELECT value, created_at FROM temperatures WHERE cage_id = @cageId AND created_at >= @startOfDay AND created_at < @endOfDay ORDER BY created_at',
      substitutionValues: {
        'cageId': cageId,
        'startOfDay': startOfDay.toUtc(),
        'endOfDay': endOfDay.toUtc(),
      },
    );

    return results.map<Map<String, dynamic>>((row) {
      return {
        'value': double.tryParse(row[0].toString()) ?? 0.0,
        'timestamp': (row[1] as DateTime).toLocal(),
      };
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getHumiditiesForCageAndDate(
      int cageId, DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(Duration(days: 1));

    final results = await _connection!.query(
      'SELECT value, created_at FROM humidities WHERE cage_id = @cageId AND created_at >= @startOfDay AND created_at < @endOfDay ORDER BY created_at',
      substitutionValues: {
        'cageId': cageId,
        'startOfDay': startOfDay.toUtc(),
        'endOfDay': endOfDay.toUtc(),
      },
    );

    return results.map<Map<String, dynamic>>((row) {
      return {
        'value': double.tryParse(row[0].toString()) ?? 0.0,
        'timestamp': (row[1] as DateTime).toLocal(),
      };
    }).toList();
  }

  Future<List<double>> getHumiditiesForCage(int cageId) async {
    final results = await _connection!.query(
      'SELECT value FROM humidities WHERE cage_id = @cageId ORDER BY created_at DESC LIMIT 24',
      substitutionValues: {'cageId': cageId},
    );
    return results.map<double>((row) {
      if (row[0] == null) return 0.0; // or another default value
      // Safely parse the string to double
      return double.tryParse(row[0].toString()) ?? 0.0;
    }).toList();
  }

  Future<List<MapPoint>> getCagePoints() async {
    final results = await _connection!.query('''
      SELECT id, name, ST_X(geom) as longitude, ST_Y(geom) as latitude
      FROM cages
    ''');

    return results.map((row) {
      return MapPoint(
        id: row[0] as int,
        name: row[1] as String,
        description: "Chuồng ${row[1]}",
        location: LatLng(row[3] as double, row[2] as double),
      );
    }).toList();
  }

  Future<List<Pet>> getPetsForCage(int cageId) async {
    final results = await _connection!.query(
      'SELECT id, name, born_on, pet_code, species FROM pets WHERE cage_id = @cageId',
      substitutionValues: {'cageId': cageId},
    );

    return results
        .map((row) => Pet(
              id: row[0] as int,
              name: row[1] as String,
              bornOn: row[2] as DateTime,
              petCode: row[3] as String,
              species: row[4] as String,
              cageId: cageId,
            ))
        .toList();
  }

  Future<double?> getLatestTemperatureForCage(int cageId) async {
    final results = await _connection!.query(
      'SELECT value FROM temperatures WHERE cage_id = @cageId ORDER BY created_at DESC LIMIT 1',
      substitutionValues: {'cageId': cageId},
    );

    if (results.isNotEmpty && results[0][0] != null) {
      // Safely parse the string to double
      return double.tryParse(results[0][0].toString());
    } else {
      return null;
    }
  }

  Future<double?> getLatestHumidityForCage(int cageId) async {
    final results = await _connection!.query(
      'SELECT value FROM humidities WHERE cage_id = @cageId ORDER BY created_at DESC LIMIT 1',
      substitutionValues: {'cageId': cageId},
    );

    if (results.isNotEmpty && results[0][0] != null) {
      // Safely parse the string to double
      return double.tryParse(results[0][0].toString());
    } else {
      return null;
    }
  }

  Future<List<Task>> getTasks() async {
    final results = await _connection!.query('''
      SELECT id, work_content, note, pet_id, time, created_at, done 
      FROM tasks 
      ORDER BY created_at DESC
    ''');

    return results
        .map((row) => Task(
              id: row[0] as int,
              workContent: row[1] as String,
              note: row[2] as String?,
              petId: row[3] as int?,
              time: row[4] as DateTime?,
              createdAt: row[5] as DateTime,
              done: row[6] as bool,
            ))
        .toList();
  }

  Future<void> updateTaskStatus(int id, bool isDone) async {
    await _connection!.query(
      'UPDATE tasks SET done = @isDone WHERE id = @id',
      substitutionValues: {
        'isDone': isDone,
        'id': id,
      },
    );
  }

  Future<void> addTask(String workContent, int? petId, DateTime? time) async {
    await _connection!.query(
      'INSERT INTO tasks (work_content, pet_id, time) VALUES (@workContent, @petId, @time)',
      substitutionValues: {
        'workContent': workContent,
        'petId': petId,
        'time': time,
      },
    );
  }

  Future<void> deleteTask(int id) async {
    await _connection!.query(
      'DELETE FROM tasks WHERE id = @id',
      substitutionValues: {
        'id': id,
      },
    );
  }

  Future<void> updateTaskNote(int id, String note) async {
    await _connection!.query(
      'UPDATE tasks SET note = @note WHERE id = @id',
      substitutionValues: {
        'note': note,
        'id': id,
      },
    );
  }

  Future<List<SpeciesCount>> getSpeciesCounts() async {
    final results = await _connection!.query(
        'SELECT species, COUNT(*) as quantity FROM pets GROUP BY species');
    return results
        .map((row) => SpeciesCount(
              species: row[0] as String,
              quantity: row[1] as int,
            ))
        .toList();
  }

  Future<List<Pet>> getPetsBySpecies(String species) async {
    final results = await _connection!.query(
      'SELECT id, name, born_on, pet_code, cage_id FROM pets WHERE species = @species',
      substitutionValues: {'species': species},
    );

    return results
        .map((row) => Pet(
              id: row[0] as int,
              name: row[1] as String,
              bornOn: row[2] as DateTime,
              petCode: row[3] as String,
              species: species,
              cageId: row[4] as int,
            ))
        .toList();
  }

  Future<Cage?> getCageById(int cageId) async {
    final results = await _connection!.query(
      'SELECT id, name, ST_X(geom) as longitude, ST_Y(geom) as latitude FROM cages WHERE id = @cageId',
      substitutionValues: {'cageId': cageId},
    );
    if (results.isNotEmpty) {
      return Cage(
        id: results[0][0] as int,
        name: results[0][1] as String,
        location: LatLng(results[0][3] as double, results[0][2] as double),
      );
    }
    return null;
  }

  Future<List<PetWithCage>> getAllPetsWithCage() async {
    final results = await _connection!.query('''
      SELECT p.id, p.name, p.born_on, p.pet_code, c.name as cage_name
      FROM pets p
      JOIN cages c ON p.cage_id = c.id
    ''');

    return results
        .map((row) => PetWithCage(
              id: row[0] as int,
              name: row[1] as String,
              bornOn: row[2] as DateTime,
              petCode: row[3] as String,
              cageName: row[4] as String,
            ))
        .toList();
  }

  Future<List<MedicalHistory>> getMedicalHistoryForPet(int petId) async {
    final results = await _connection!.query('''
      SELECT id, pet_id, examination_date, symptoms, diagnosis, treatment, 
             veterinarian, notes, created_at, current_status
      FROM medical_histories
      WHERE pet_id = @petId
      ORDER BY examination_date DESC
    ''', substitutionValues: {'petId': petId});

    return results
        .map((row) => MedicalHistory(
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
            ))
        .toList();
  }

  Future<void> close() async {
    await _connection?.close();
    print('Connection closed.');
  }
}
