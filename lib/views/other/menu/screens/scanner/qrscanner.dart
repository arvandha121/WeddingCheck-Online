import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:weddingcheck/app/database/dbHelper.dart';
import 'package:weddingcheck/app/model/listItem.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({Key? key}) : super(key: key);

  @override
  State<QRScanner> createState() => _QRScannerState();
}

class _QRScannerState extends State<QRScanner> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  Timer? _inactivityTimer;
  Timer? _cameraCheckTimer;

  bool isFlashOn = false;
  bool isFrontCamera = false; // Track the current camera
  bool isCameraPaused = false; // Track if the camera is paused

  @override
  void initState() {
    super.initState();
    _startInactivityTimer();
    _startCameraCheckTimer();
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    }
    controller?.resumeCamera();
  }

  @override
  void dispose() {
    controller?.dispose();
    _inactivityTimer?.cancel();
    _cameraCheckTimer?.cancel();
    super.dispose();
  }

  void _startInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(Duration(minutes: 1), _showInactivityDialog);
  }

  void _startCameraCheckTimer() {
    _cameraCheckTimer?.cancel();
    _cameraCheckTimer = Timer.periodic(Duration(seconds: 10), (timer) {
      if (isCameraPaused) {
        // Do not resume the camera here
      }
    });
  }

  void _showInactivityDialog() {
    controller?.pauseCamera(); // Pause the camera when showing the dialog
    isCameraPaused = true;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Inactivity Alert"),
          content: Text("KETIK OK KETIKA INGIN MENGGUNAKAN QR SCANNER KEMBALI"),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                _startInactivityTimer(); // Restart the timer
                controller?.resumeCamera(); // Resume the camera
                isCameraPaused = false;
              },
            ),
          ],
        );
      },
    );
  }

  void _resetInactivityTimer() {
    _startInactivityTimer();
  }

  void _toggleFlash() async {
    setState(() {
      isFlashOn = !isFlashOn;
    });
    controller?.toggleFlash();
    _resetInactivityTimer();

    // Adjust screen brightness if using the front camera and flash is on
    if (isFrontCamera && isFlashOn) {
      try {
        await ScreenBrightness()
            .setScreenBrightness(1.0); // Set brightness to 100%
      } catch (e) {
        print("Error setting screen brightness: $e");
      }
    } else {
      try {
        await ScreenBrightness()
            .resetScreenBrightness(); // Reset to default brightness
      } catch (e) {
        print("Error resetting screen brightness: $e");
      }
    }
  }

  void _flipCamera() {
    setState(() {
      isFrontCamera = !isFrontCamera;
    });
    controller?.flipCamera();
    _resetInactivityTimer();
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      controller.pauseCamera();
      isCameraPaused = true;
      final String scannedData = scanData.code ?? "";
      fetchListItemByGambar(scannedData).then((item) {
        if (item != null) {
          if (item.keterangan == "belum hadir") {
            updateListItemStatus(item.id!).then(
              (_) {
                // Ensure updateListItemStatus accepts only one argument
                _showNotificationDialog(
                  context,
                  "Konfirmasi",
                  "${item.nama} terdaftar hadir.",
                  Duration(seconds: 5), // 3 seconds delay for success
                );
              },
            );
          } else {
            _showNotificationDialog(
              context,
              "Ditolak",
              "Akses ditolak karena ${item.nama} telah terdaftar.",
              Duration(seconds: 8), // 3 seconds delay for already registered
            );
          }
        } else {
          _showNotificationDialog(
            context,
            "Error",
            "Kode QR tidak valid atau item tidak ditemukan.",
            Duration(seconds: 12), // 15 seconds delay for error
          );
        }
      });
    });
    controller.resumeCamera();
  }

  Future<void> updateListItemStatus(int id) async {
    DatabaseHelper dbHelper = DatabaseHelper();
    await dbHelper.updateKeteranganHadir(id);
    if (mounted) {
      setState(() {});
    }
  }

  Future<bool> _onWillPop() async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Konfirmasi'),
            content: Text('Apakah Anda yakin ingin keluar dari aplikasi?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Tidak'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Iya',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        )) ??
        false;
  }

  void _showNotificationDialog(
      BuildContext context, String title, String content, Duration delay) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
                controller?.resumeCamera();
                isCameraPaused = false;
              },
            ),
          ],
        );
      },
    );

    Future.delayed(delay, () {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // Dismiss the dialog
      }
      controller?.resumeCamera(); // Resume the camera
      isCameraPaused = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: GestureDetector(
        onTap: _resetInactivityTimer,
        onPanDown: (_) => _resetInactivityTimer(),
        child: Scaffold(
          body: Stack(
            children: [
              QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.red,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 300,
                ),
              ),
              Positioned(
                left: 10, // Position the flash button on the left
                bottom: 10,
                child: FloatingActionButton(
                  onPressed: _toggleFlash,
                  child: Icon(
                    isFlashOn ? Icons.flash_off : Icons.flash_on,
                    color: Colors.white,
                  ),
                  backgroundColor:
                      isFlashOn ? Colors.yellow[700] : Colors.black54,
                ),
              ),
              Positioned(
                right: 10, // Position the flip camera button on the right
                bottom: 10,
                child: FloatingActionButton(
                  onPressed: _flipCamera,
                  child: Icon(
                    Icons.flip_camera_android,
                    color: Colors.white,
                  ),
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<ListItem?> fetchListItemByGambar(String gambar) async {
    DatabaseHelper list = await DatabaseHelper();
    return list.getListItemByGambar(gambar);
  }
}
