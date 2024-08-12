import 'package:flutter/material.dart';
import 'package:gis_iot/src/database/database.dart';
import 'package:gis_iot/src/pet/PetDetailPage.dart';
import 'package:intl/intl.dart';

class PetListPage extends StatefulWidget {
  @override
  _PetListPageState createState() => _PetListPageState();
}

class _PetListPageState extends State<PetListPage> {
  List<PetWithCage> _pets = [];
  List<Cage> _cages = [];
  bool _isLoading = true;
  String _searchQuery = "";
  Set<String> _selectedNames = Set<String>();
  Set<String> _selectedCages = Set<String>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final db = DatabaseHelper();
    await db.connect();
    _pets = await db.getAllPetsWithCage();
    _cages = await db.getCages();
    await db.close();

    setState(() {
      _isLoading = false;
    });
  }

  List<PetWithCage> get filteredPets {
    return _pets.where((pet) {
      final matchesSearch = pet.petCode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesName = _selectedNames.isEmpty || _selectedNames.contains(pet.name);
      final matchesCage = _selectedCages.isEmpty || _selectedCages.contains(pet.cageName);
      return matchesSearch && matchesName && matchesCage;
    }).toList();
  }

  List<String> get uniquePetNames {
    return _pets.map((pet) => pet.name).toSet().toList()..sort();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Danh sách các con vật"),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),
      endDrawer: _buildFilterDrawer(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    decoration: InputDecoration(
                      labelText: "Tìm kiếm theo mã pet",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredPets.length,
                    itemBuilder: (context, index) {
                      final pet = filteredPets[index];
                      return ListTile(
                        title: Text(pet.name),
                        subtitle: Text(
                          'Mã: ${pet.petCode}\n'
                          'Ngày sinh: ${DateFormat('dd/MM/yyyy').format(pet.bornOn)}\n'
                          'Chuồng: ${pet.cageName}'
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PetDetailPage(pet: pet),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Bộ lọc",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ExpansionTile(
                    title: Text("Lọc theo tên"),
                    children: uniquePetNames.map((name) {
                      return CheckboxListTile(
                        title: Text(name),
                        value: _selectedNames.contains(name),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedNames.add(name);
                            } else {
                              _selectedNames.remove(name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                  ExpansionTile(
                    title: Text("Lọc theo chuồng"),
                    children: _cages.map((cage) {
                      return CheckboxListTile(
                        title: Text(cage.name),
                        value: _selectedCages.contains(cage.name),
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedCages.add(cage.name);
                            } else {
                              _selectedCages.remove(cage.name);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                child: Text("Áp dụng"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}