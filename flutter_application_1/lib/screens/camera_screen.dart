// Cross-platform camera screen using image_picker.
// On web: opens the browser's file picker with the user-facing camera hint.
// On mobile: launches the native camera UI.
//
// The screen pops with a base64 data URL (`data:image/jpeg;base64,...`) of the
// captured/picked image, matching the contract that callers expect.

import 'dart:convert';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/constants.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _picker = ImagePicker();
  String? _capturedBase64;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Open the camera as soon as the screen appears.
    WidgetsBinding.instance.addPostFrameCallback((_) => _capture());
  }

  Future<void> _capture() async {
    setState(() { _busy = true; _error = null; });
    try {
      final xfile = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );
      if (xfile == null) {
        if (mounted) Navigator.pop(context);
        return;
      }
      final bytes = kIsWeb ? await xfile.readAsBytes() : await File(xfile.path).readAsBytes();
      final ext = (xfile.name.contains('.') ? xfile.name.split('.').last : 'jpg').toLowerCase();
      if (mounted) {
        setState(() {
          _capturedBase64 = 'data:image/$ext;base64,${base64Encode(bytes)}';
          _busy = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _busy = false; _error = e.toString(); });
    }
  }

  void _retake() => _capture();
  void _usePhoto() => Navigator.pop(context, _capturedBase64);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [
          // Top bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
              const Spacer(),
              const Text('Camera',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              const SizedBox(width: 40),
            ]),
          ),

          // Preview area
          Expanded(child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(borderRadius: BorderRadius.circular(20), child: _buildPreview()),
          )),

          // Controls
          Padding(padding: const EdgeInsets.all(24), child: _buildControls()),
        ]),
      ),
    );
  }

  Widget _buildPreview() {
    if (_busy) {
      return Container(
        color: const Color(0xFF111111),
        child: const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: kGreen, strokeWidth: 2.5),
          SizedBox(height: 16),
          Text('Opening camera...', style: TextStyle(color: Colors.white54, fontSize: 14)),
        ])),
      );
    }
    if (_error != null) {
      return Container(
        color: const Color(0xFF111111),
        child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.no_photography_outlined, color: Colors.white38, size: 64),
          const SizedBox(height: 20),
          Text(_error!,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
              textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _capture,
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen, foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ])),
      );
    }
    if (_capturedBase64 != null) {
      return Stack(children: [
        Image.network(_capturedBase64!, fit: BoxFit.cover,
            width: double.infinity, height: double.infinity),
        Positioned(top: 16, left: 0, right: 0,
          child: Center(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(20)),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check, color: Colors.black, size: 16),
              SizedBox(width: 6),
              Text('Photo captured!',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
            ]),
          )),
        ),
      ]);
    }
    return Container(color: const Color(0xFF111111));
  }

  Widget _buildControls() {
    if (_capturedBase64 == null) return const SizedBox(height: 80);
    return Row(children: [
      Expanded(child: GestureDetector(
        onTap: _retake,
        child: Container(
          height: 54,
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.refresh, color: Colors.white, size: 20), SizedBox(width: 8),
            Text('Retake', style: TextStyle(color: Colors.white,
                fontWeight: FontWeight.w700, fontSize: 15)),
          ]),
        ),
      )),
      const SizedBox(width: 16),
      Expanded(child: GestureDetector(
        onTap: _usePhoto,
        child: Container(
          height: 54,
          decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(16)),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check, color: Colors.black, size: 20), SizedBox(width: 8),
            Text('Use Photo', style: TextStyle(color: Colors.black,
                fontWeight: FontWeight.w800, fontSize: 15)),
          ]),
        ),
      )),
    ]);
  }
}
