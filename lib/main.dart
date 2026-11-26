// DawaKhata — inventory app, Phase 1 (Flutter).
// Local-only, offline, no login, no server.
import 'package:flutter/material.dart';
import 'screens.dart';

void main() {
  runApp(const DawaKhataApp());
}

class DawaKhataApp extends StatelessWidget {
  const DawaKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: shopName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _pages = [
    DashboardScreen(),
    MedicinesScreen(),
    SuppliersScreen(),
    HistoryScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _tab, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal.shade700,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medication), label: 'Medicines'),
          BottomNavigationBarItem(
              icon: Icon(Icons.local_shipping), label: 'Suppliers'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history), label: 'History'),
          BottomNavigationBarItem(
              icon: Icon(Icons.info), label: 'About'),
        ],
      ),
    );
  }
}
