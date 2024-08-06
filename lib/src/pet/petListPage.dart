import 'package:flutter/material.dart';
import 'package:gis_iot/src/database/database.dart';
import 'package:intl/intl.dart';

class PetListPage extends StatefulWidget {
  @override
  _PetListPageState createState() => _PetListPageState();
}

class _PetListPageState extends State<PetListPage> {
  List<PetWithCage> _pets = [];
  List<SpeciesCount> _speciesCounts = [];
  bool _isLoading = true;
  String _searchQuery = "";
  String? _selectedSpecies;

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
    _speciesCounts = await db.getSpeciesCounts();
    await db.close();

    setState(() {
      _isLoading = false;
    });
  }

  List<PetWithCage> get filteredPets {
    return _pets.where((pet) {
      final matchesSearch = pet.petCode.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesSpecies = _selectedSpecies == null || pet.species == _selectedSpecies;
      return matchesSearch && matchesSpecies;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Danh sách các con vật"),
      ),
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: DropdownButton<String>(
                    isExpanded: true,
                    hint: Text("Chọn loài"),
                    value: _selectedSpecies,
                    items: [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text("Tất cả các loài"),
                      ),
                      ..._speciesCounts.map((species) {
                        return DropdownMenuItem<String>(
                          value: species.species,
                          child: Text("${species.species} (${species.quantity})"),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecies = value;
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
                          'Loài: ${pet.species}\n'
                          'Ngày sinh: ${DateFormat('dd/MM/yyyy').format(pet.bornOn)}\n'
                          'Chuồng: ${pet.cageName}'
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}