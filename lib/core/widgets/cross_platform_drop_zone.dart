import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// Conditional imports for web
import 'cross_platform_drop_zone_stub.dart'
    if (dart.library.html) 'cross_platform_drop_zone_web.dart' as platform;

/// Data class for dropped files
class DroppedFile {
  final String name;
  final Uint8List bytes;

  DroppedFile({required this.name, required this.bytes});
}

/// A cross-platform drop zone that works on both web and desktop
class CrossPlatformDropZone extends StatefulWidget {
  final Widget child;
  final void Function(bool isDragging) onDragStateChanged;
  final Future<void> Function(String fileName, Uint8List bytes) onFileDrop;
  final bool enabled;

  const CrossPlatformDropZone({
    super.key,
    required this.child,
    required this.onDragStateChanged,
    required this.onFileDrop,
    this.enabled = true,
  });

  @override
  State<CrossPlatformDropZone> createState() => _CrossPlatformDropZoneState();
}

class _CrossPlatformDropZoneState extends State<CrossPlatformDropZone> {
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return platform.WebDropZone(
        onDragStateChanged: widget.onDragStateChanged,
        onFileDrop: widget.onFileDrop,
        enabled: widget.enabled,
        child: widget.child,
      );
    } else {
      // For non-web platforms, just return the child (desktop_drop can be used separately)
      return widget.child;
    }
  }
}
