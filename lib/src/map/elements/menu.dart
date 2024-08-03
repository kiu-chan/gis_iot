import 'package:flutter/material.dart';

class Menu extends StatefulWidget {
  final ValueChanged<int> onClickMap;

  @override
  _MenuState createState() => _MenuState();
  Menu({required this.onClickMap});
}

class _MenuState extends State<Menu> {
  int? selectedMap = 1;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 80,
            child: DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      Navigator.pop(context); // Đóng Drawer
                    },
                  ),
                  const Text(
                    'Hiển thị',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ExpansionTile(
            leading: const Icon(Icons.api),
            title: const Text('Bản đồ nền'),
            subtitle: const Text('Bản đồ mặc định'),
            children: <Widget>[
              RadioListTile<int>(
                title: const Text('Bản đồ địa lý'),
                value: 1,
                groupValue: selectedMap,
                onChanged: (value) {
                  setState(() {
                    selectedMap = value;
                    widget.onClickMap(0);
                  });
                },
              ),
              RadioListTile<int>(
                title: Text('Bản đồ vệ tinh'),
                value: 2,
                groupValue: selectedMap,
                onChanged: (value) {
                  setState(() {
                    selectedMap = value;
                    widget.onClickMap(1);
                  });
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: Icon(Icons.show_chart),
            title: Text('Lớp hành chính'),
            subtitle: Text('Mô tả'),
            children: <Widget>[
              CheckboxListTile(
                title: Text('Ranh giới'),
                value: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.blue,
                onChanged: (bool? value) {
                  // Implement logic to show/hide boundaries
                  Navigator.pop(context);
                },
              ),
              CheckboxListTile(
                title: Text('Ranh giới huyện'),
                value: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.blue,
                onChanged: (bool? value) {
                  // Implement logic to show/hide district boundaries
                  Navigator.pop(context);
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.home),
            title: const Text('Danh sách chuồng'),
            subtitle: const Text('Mô tả'),
            children: <Widget>[
              CheckboxListTile(
                title: const Text('Hiển thị tất cả'),
                value: true,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Colors.blue,
                onChanged: (bool? value) {
                  // Implement logic to show/hide all cages
                },
              ),
              // You can add more CheckboxListTile widgets here for individual cages
              // if you want to allow toggling visibility for each cage separately
            ],
          ),
        ],
      ),
    );
  }
}