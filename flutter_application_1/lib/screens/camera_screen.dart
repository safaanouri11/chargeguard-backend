// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  html.VideoElement?  _video;
  html.CanvasElement? _canvas;
  html.MediaStream?   _stream;

  String? _capturedBase64;
  bool    _isLoading  = true;
  bool    _hasError   = false;
  bool    _captured   = false;
  String  _errorMsg   = '';

  // Unique IDs for HTML elements
  final String _videoId  = 'cg_camera_video_${DateTime.now().millisecondsSinceEpoch}';
  final String _canvasId = 'cg_camera_canvas_${DateTime.now().millisecondsSinceEpoch}';

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    _stopCamera();
    super.dispose();
  }

  // ── Start Camera ──────────────────────────────────────────
  Future<void> _initCamera() async {
    try {
      // Request camera permission
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {
          'facingMode': 'user',  // front camera
          'width':  {'ideal': 1280},
          'height': {'ideal': 720},
        },
        'audio': false,
      });

      _stream = stream;

      // Create video element
      _video = html.VideoElement()
        ..id       = _videoId
        ..autoplay = true
        ..muted    = true
        ..style.width    = '100%'
        ..style.height   = '100%'
        ..style.objectFit = 'cover'
        ..style.borderRadius = '16px';

      _video!.srcObject = stream;

      // Create canvas for snapshot
      _canvas = html.CanvasElement(width: 1280, height: 720)
        ..id = _canvasId
        ..style.display = 'none';

      // Register with Flutter Web
      // ignore: undefined_prefixed_name
      js.context.callMethod('eval', ['''
        (function() {
          var div = document.getElementById('$_videoId');
          if (!div) {
            var container = document.createElement('div');
            container.id = '$_videoId-container';
            container.style.position = 'absolute';
            container.style.opacity = '0';
            document.body.appendChild(container);
          }
        })();
      ''']);

      await _video!.play();

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError  = true;
          _errorMsg  = e.toString().contains('NotAllowed')
              ? 'Camera permission denied.\nPlease allow camera access in your browser.'
              : 'Camera not available.\n${e.toString()}';
        });
      }
    }
  }

  void _stopCamera() {
    _stream?.getTracks().forEach((track) => track.stop());
  }

  // ── Capture Photo ─────────────────────────────────────────
  void _capture() {
    if (_video == null || _canvas == null) return;

    final w = _video!.videoWidth;
    final h = _video!.videoHeight;
    _canvas!.width  = w;
    _canvas!.height = h;

    final ctx = _canvas!.context2D;
    ctx.drawImage(_video!, 0, 0);

    final base64 = _canvas!.toDataUrl('image/jpeg', 0.92);
    setState(() {
      _capturedBase64 = base64;
      _captured       = true;
    });
    _stopCamera();
  }

  // ── Retake ────────────────────────────────────────────────
  void _retake() {
    setState(() {
      _capturedBase64 = null;
      _captured       = false;
      _isLoading      = true;
    });
    _initCamera();
  }

  // ── Use Photo ─────────────────────────────────────────────
  void _usePhoto() {
    if (_capturedBase64 != null) {
      Navigator.pop(context, _capturedBase64);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(children: [

          // ── Top Bar ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.close, color: Colors.white, size: 20)),
              ),
              const Spacer(),
              const Text('Camera',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              const SizedBox(width: 40),
            ]),
          ),

          // ── Camera View ────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: _buildCameraView(),
              ),
            ),
          ),

          // ── Bottom Controls ────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildControls(),
          ),
        ]),
      ),
    );
  }

  Widget _buildCameraView() {
    // Error state
    if (_hasError) {
      return Container(
        color: const Color(0xFF111111),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.no_photography_outlined, color: Colors.white38, size: 64),
            const SizedBox(height: 20),
            Text(_errorMsg, style: const TextStyle(color: Colors.white54, fontSize: 14),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () { setState(() { _hasError = false; _isLoading = true; }); _initCamera(); },
              style: ElevatedButton.styleFrom(backgroundColor: kGreen, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Try Again', style: TextStyle(fontWeight: FontWeight.w700))),
          ]),
        ),
      );
    }

    // Captured photo
    if (_captured && _capturedBase64 != null) {
      return Stack(children: [
        Image.network(_capturedBase64!, fit: BoxFit.cover,
            width: double.infinity, height: double.infinity),
        // Captured overlay
        Positioned(top: 16, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(20)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check, color: Colors.black, size: 16), SizedBox(width: 6),
                Text('Photo captured!',
                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
              ])))),
      ]);
    }

    // Loading
    if (_isLoading) {
      return Container(
        color: const Color(0xFF111111),
        child: const Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: kGreen, strokeWidth: 2.5),
            SizedBox(height: 16),
            Text('Starting camera...', style: TextStyle(color: Colors.white54, fontSize: 14)),
          ])));
    }

    // Live Camera — HtmlElementView
    if (_video != null) {
      // Register the video element for Flutter web
      final viewType = 'camera-view-$_videoId';
      // ignore: undefined_prefixed_name
      try {
        // ignore: undefined_prefixed_name
        js.context.callMethod('eval', ['''
          if (!window.__cgCameraRegistered_$_videoId) {
            window.__cgCameraRegistered_$_videoId = true;
          }
        ''']);
      } catch (_) {}

      return _WebCameraView(video: _video!);
    }

    return Container(color: const Color(0xFF111111));
  }

  Widget _buildControls() {
    if (_hasError) return const SizedBox.shrink();

    if (_captured) {
      // Retake + Use Photo
      return Row(children: [
        Expanded(
          child: GestureDetector(
            onTap: _retake,
            child: Container(
              height: 54,
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.refresh, color: Colors.white, size: 20), SizedBox(width: 8),
                Text('Retake', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ])),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _usePhoto,
            child: Container(
              height: 54,
              decoration: BoxDecoration(color: kGreen, borderRadius: BorderRadius.circular(16)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.check, color: Colors.black, size: 20), SizedBox(width: 8),
                Text('Use Photo', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 15)),
              ])),
          ),
        ),
      ]);
    }

    // Capture button
    return Center(
      child: GestureDetector(
        onTap: _isLoading ? null : _capture,
        child: Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
            border: Border.all(color: Colors.white, width: 3),
          ),
          child: Center(
            child: Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(18),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════
//  Web Camera View Widget
// ════════════════════════════════════════
class _WebCameraView extends StatefulWidget {
  final html.VideoElement video;
  const _WebCameraView({required this.video});
  @override
  State<_WebCameraView> createState() => _WebCameraViewState();
}

class _WebCameraViewState extends State<_WebCameraView> {
  @override
  void initState() {
    super.initState();
    // Register platform view factory
    // ignore: undefined_prefixed_name
    try {
      // Register the view factory if not already registered
      final viewType = 'video-${widget.video.id}';
      // ignore: undefined_prefixed_name
      js.context.callMethod('eval', ['''
        (function() {
          var existingVideo = document.getElementById('${widget.video.id}');
          if (!existingVideo) {
            document.body.appendChild(arguments[0]);
          }
        })
      ''']);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // Use a styled container to host the video
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.videocam, color: kGreen, size: 48),
          const SizedBox(height: 16),
          const Text('Camera is active',
              style: TextStyle(color: Colors.white70, fontSize: 14)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: kGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: const Text('Tap the white button to capture',
                style: TextStyle(color: kGreen, fontSize: 12, fontWeight: FontWeight.w600))),
        ]),
      ),
    );
  }
}
