import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final User? user = FirebaseAuth.instance.currentUser;
  Map<String, int> objects = {};

  @override
  void initState() {
    super.initState();
    _fetchObjectsData();
  }

  void _fetchObjectsData() async {
    final objectsRef = _database.child('objects');

    final snapshot = await objectsRef.get();
    if (snapshot.exists && snapshot.value != null) {
      setState(() {
        objects = Map<String, int>.from(snapshot.value as Map);
      });
    }
  }

  void _toggleBinStatus() async {
    if (user == null) {
      print('No user logged in!');
      return;
    }

    final binStatusRef = _database.child('bin_status/${user?.uid}');

    final snapshot = await binStatusRef.get();
    if (snapshot.exists && snapshot.value != null) {
      final Map<dynamic, dynamic> valueMap = Map<dynamic, dynamic>.from(snapshot.value as Map);
      final currentStatus = valueMap['status'].toString();

      final newStatus = currentStatus == 'full' ? 'can be used ' : 'full';

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
            if (objects.isNotEmpty)
              ...objects.entries.map((entry) => Text("${entry.key}: ${entry.value}")),
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
