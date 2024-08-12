import 'package:flutter/material.dart';
import 'package:gis_iot/src/database/database.dart';
import 'package:intl/intl.dart';

class PetDetailPage extends StatefulWidget {
  final PetWithCage pet;

  PetDetailPage({required this.pet});

  @override
  _PetDetailPageState createState() => _PetDetailPageState();
}

class _PetDetailPageState extends State<PetDetailPage> {
  List<MedicalHistory> _medicalHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMedicalHistory();
  }

  Future<void> _loadMedicalHistory() async {
    setState(() {
      _isLoading = true;
    });

    final db = DatabaseHelper();
    await db.connect();
    _medicalHistory = await db.getMedicalHistoryForPet(widget.pet.id);
    await db.close();

    setState(() {
      _isLoading = false;
    });
  }

  int _calculateAge() {
    return DateTime.now().difference(widget.pet.bornOn).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pet.name),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Thông tin chi tiết',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    Text('Tên: ${widget.pet.name}'),
                    Text('Mã: ${widget.pet.petCode}'),
                    Text('Ngày sinh: ${DateFormat('dd/MM/yyyy').format(widget.pet.bornOn)}'),
                    Text('Tuổi: ${_calculateAge()} ngày'),
                    Text('Chuồng: ${widget.pet.cageName}'),
                    SizedBox(height: 24),
                    Text(
                      'Lịch sử sức khỏe',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 16),
                    _medicalHistory.isEmpty
                        ? Text('Không có lịch sử sức khỏe.')
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemCount: _medicalHistory.length,
                            itemBuilder: (context, index) {
                              final history = _medicalHistory[index];
                              return Card(
                                child: ExpansionTile(
                                  title: Text('Khám ngày ${DateFormat('dd/MM/yyyy').format(history.examinationDate)}'),
                                  children: [
                                    ListTile(title: Text('Triệu chứng: ${history.symptoms ?? "Không có"}')),
                                    ListTile(title: Text('Chẩn đoán: ${history.diagnosis ?? "Không có"}')),
                                    ListTile(title: Text('Điều trị: ${history.treatment ?? "Không có"}')),
                                    ListTile(title: Text('Bác sĩ: ${history.veterinarian ?? "Không có"}')),
                                    ListTile(title: Text('Ghi chú: ${history.notes ?? "Không có"}')),
                                    ListTile(title: Text('Trạng thái hiện tại: ${history.currentStatus ?? "Không có"}')),
                                  ],
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}