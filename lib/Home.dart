import 'dart:math';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:fl_chart/fl_chart.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, int> objects = {};
  List<PieChartSectionData> _sections = [];
  String binStatus = 'Unknown';

  @override
  void initState() {
    super.initState();
    _fetchBinStatus();
    _fetchObjectsData();
  }

  void _fetchBinStatus() async {
    if (user == null) {
      print('No user logged in!');
      return;
    }

    final binStatusRef = _database.child('bin_status/${user!.uid}');

    binStatusRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?; // Cast to a map
      final status = data?['status'] ?? 'Unknown'; // Use the map to access 'status'
      setState(() {
        binStatus = status.toString();
      });
    });
  }

  void _fetchObjectsData() async {
    final objectsRef = _database.child('objects');

    final snapshot = await objectsRef.get();
    if (snapshot.exists && snapshot.value != null) {
      final fetchedObjects = Map<String, int>.from(snapshot.value as Map);
      _generatePieChartSections(fetchedObjects);
    }
  }



  void _generatePieChartSections(Map<String, int> objectsData) {
    final data = objectsData.entries.map((entry) => PieChartSectionData(
      color: Colors.primaries[Random().nextInt(Colors.primaries.length)],
      value: entry.value.toDouble(),
      title: '${entry.key}: ${entry.value}',
      radius: 100,
    )).toList();

    setState(() {
      _sections = data;
    });
  }

  void _toggleBinStatus() async {
    if (user == null) {
      print('No user logged in!');
      return;
    }

    final binStatusRef = _database.child('bin_status/${user!.uid}');

    final snapshot = await binStatusRef.get();
    if (snapshot.exists && snapshot.value != null) {
      final Map<dynamic, dynamic> valueMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final currentStatus = valueMap['status'].toString();

      final newStatus = currentStatus == 'full' ? 'can be used' : 'full';

      await binStatusRef.set({
        'status': newStatus,
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Bin status updated to: $newStatus');
    } else {
      await binStatusRef.set({
        'status': 'full',
        'timestamp': DateTime.now().toIso8601String(),
      });

      print('Bin status set to full.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SmartRecycle'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Welcome to SmartRecycle',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Text(
              'Bin Status: $binStatus',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: binStatus == 'full' ? Colors.red : Colors.green),
            ),
            SizedBox(height: 20),
            Expanded(
              child: PieChart(PieChartData(
                centerSpaceRadius: 60,
                borderData: FlBorderData(show: false),
                sectionsSpace: 0,
                sections: _sections,
              )),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleBinStatus,
              child: Text('Toggle Bin Status'),
            ),
          ],
        ),
      ),
    );
  }
}
