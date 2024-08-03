import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:gis_iot/src/map/elements/menu.dart';

class MapPoint {
  final String name;
  final String description;
  final LatLng location;

  MapPoint({required this.name, required this.description, required this.location});
}

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
  List<MapPoint> mapPoints = [
    MapPoint(
      name: "Điểm A",
      description: "Đây là mô tả cho Điểm A",
      location: LatLng(22.406276, 105.624405),
    ),
    MapPoint(
      name: "Điểm B",
      description: "Đây là mô tả cho Điểm B",
      location: LatLng(22.416276, 105.634405),
    ),
    // Thêm các điểm khác vào đây
  ];

  @override
  void initState() {
    super.initState();
    loadGeoJson();
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

  void _showPopup(MapPoint point) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(point.name),
          content: Text(point.description),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Bản đồ")),
      body: FlutterMap(
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
    );
  }
}