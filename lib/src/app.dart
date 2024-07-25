import 'package:flutter/material.dart';
import 'package:gis_iot/src/home/home.dart';
// import 'package:gis_iot/src/page/account/login/loginPage.dart';

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {

    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SafeArea(
        child: Home(),
      )
    );
  }
}