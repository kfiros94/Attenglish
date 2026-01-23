import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Stub implementation for non-web platforms
class WebDropZone extends StatelessWidget {
  final Widget child;
  final void Function(bool isDragging) onDragStateChanged;
  final Future<void> Function(String fileName, Uint8List bytes) onFileDrop;
  final bool enabled;

  const WebDropZone({
    super.key,
    required this.child,
    required this.onDragStateChanged,
    required this.onFileDrop,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    // On non-web platforms, just return the child
    return child;
  }
}
