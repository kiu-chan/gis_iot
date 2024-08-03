// home.dart

import 'package:flutter/material.dart';
import 'package:gis_iot/src/map/mapPage.dart';
import 'package:gis_iot/src/home/homePage.dart';
import 'package:gis_iot/src/task/taskPage.dart';
import 'package:gis_iot/src/chart/chartPage.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int currentIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget currentWidget = SizedBox.shrink();
    switch(currentIndex) {
      case 0:
        currentWidget = HomePage();  // Updated this line
        break;
      case 1:
        currentWidget = MapPage();
        break;
      case 2:
        currentWidget = ChartPage();
        break;
      case 3:
        currentWidget = TaskPage();
        break;
    }
    return Scaffold(
      body: Container(
        child: AnimatedSwitcher(
          duration: Duration(milliseconds: 500),
          child:
              Container(key: ValueKey<int>(currentIndex), child: currentWidget),
        ),
      ),
      bottomNavigationBar: Container(
        child: BottomNavigationBar(
          onTap: (int index) {
            setState(() {
              currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.map_outlined),
              label: "Map",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.show_chart),
              label: "Chart",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list),
              label: "Tasks",
            ),
          ],
        ),
      ),
    );
  }
}