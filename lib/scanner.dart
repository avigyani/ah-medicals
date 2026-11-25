// AH MEDICALS — barcode scan screen (mobile_scanner). If this package
// ever breaks the build, delete this file and the scan button falls back
// to manual barcode entry (see the form screen).
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  bool _done = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: MobileScanner(
        onDetect: (capture) {
          if (_done) return;
          final codes = capture.barcodes;
          if (codes.isEmpty) return;
          final value = codes.first.rawValue;
          if (value == null || value.isEmpty) return;
          _done = true;
          Navigator.pop(context, value);
        },
      ),
    );
  }
}
