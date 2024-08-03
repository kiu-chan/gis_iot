import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:gis_iot/src/database/database.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController mapController = MapController();
  double currentZoom = 10.0;
  String mapUrl = "https://tile.openstreetmap.org/{z}/{x}/{y}.png";
  final String namePackage = "com.example.app";
  final LatLng mapLat = LatLng(22.406276, 105.624405);  // Tọa độ mặc định

  List<Polygon> polygons = [];
  List<MapPoint> mapPoints = [];
  late DatabaseHelper dbHelper;

  @override
  void initState() {
    super.initState();
    dbHelper = DatabaseHelper();
    loadGeoJson();
    loadCagePoints();
  }

  Future<void> loadGeoJson() async {
    String jsonString = await rootBundle.loadString('lib/assets/geojson/vungDem.geojson');
    final jsonResult = json.decode(jsonString);

    setState(() {
      polygons = (jsonResult['features'] as List).map((feature) {
        List<LatLng> polygonCoords = [];
        
        if (feature['geometry']['type'] == 'MultiPolygon') {
          List<dynamic> coordinates = feature['geometry']['coordinates'][0][0];
          polygonCoords = coordinates.map((coord) => LatLng(coord[1], coord[0])).toList();
        }

        return Polygon(
          points: polygonCoords,
          color: Colors.blue.withOpacity(0.3),
          borderColor: Colors.blue,
          borderStrokeWidth: 2,
        );
      }).toList();
    });
  }

  Future<void> loadCagePoints() async {
    await dbHelper.connect();
    List<MapPoint> points = await dbHelper.getCagePoints();
    setState(() {
      mapPoints = points;
    });
  }

  void _showPopup(MapPoint point) async {
    List<Pet> pets = await dbHelper.getPetsForCage(point.id);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(point.name),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(point.description),
                SizedBox(height: 10),
                Text('Danh sách các con vật:'),
                ...pets.map((pet) => ListTile(
                  title: Text(pet.name),
                  subtitle: Text('Ngày sinh: ${pet.bornOn.toLocal().toString().split(' ')[0]}'),
                )).toList(),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Đóng'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _zoomIn() {
    currentZoom = (mapController.zoom + 1).clamp(1.0, 18.0);
    mapController.move(mapController.center, currentZoom);
  }

  void _zoomOut() {
    currentZoom = (mapController.zoom - 1).clamp(1.0, 18.0);
    mapController.move(mapController.center, currentZoom);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bản đồ")),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              center: mapLat,
              zoom: currentZoom,
            ),
            nonRotatedChildren: [
              TileLayer(
                urlTemplate: mapUrl,
                userAgentPackageName: namePackage,
              ),
              PolygonLayer(polygons: polygons),
              MarkerLayer(
                markers: mapPoints.map((point) => Marker(
                  width: 80.0,
                  height: 80.0,
                  point: point.location,
                  builder: (ctx) => GestureDetector(
                    onTap: () => _showPopup(point),
                    child: Icon(Icons.location_on, color: Colors.red, size: 40),
                  ),
                )).toList(),
              ),
            ],
          ),
          Positioned(
            right: 20,
            bottom: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: "zoomIn",
                  onPressed: _zoomIn,
                  child: Icon(Icons.add),
                ),
                SizedBox(height: 10),
                FloatingActionButton(
                  heroTag: "zoomOut",
                  onPressed: _zoomOut,
                  child: Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    dbHelper.close();
    super.dispose();
  }
}