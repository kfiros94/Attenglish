// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Web-specific drop zone using HTML5 drag and drop API
class WebDropZone extends StatefulWidget {
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
  State<WebDropZone> createState() => _WebDropZoneState();
}

class _WebDropZoneState extends State<WebDropZone> {
  int _dragCounter = 0; // Track drag enter/leave properly

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupDropZone();
    });
  }

  @override
  void dispose() {
    _removeDropZone();
    super.dispose();
  }

  void _setupDropZone() {
    // Get the body element and set up listeners on it
    final body = html.document.body;
    if (body == null) return;

    body.addEventListener('dragenter', _onDragEnter);
    body.addEventListener('dragover', _onDragOver);
    body.addEventListener('dragleave', _onDragLeave);
    body.addEventListener('drop', _onDrop);
  }

  void _removeDropZone() {
    final body = html.document.body;
    if (body == null) return;

    body.removeEventListener('dragenter', _onDragEnter);
    body.removeEventListener('dragover', _onDragOver);
    body.removeEventListener('dragleave', _onDragLeave);
    body.removeEventListener('drop', _onDrop);
  }

  void _onDragEnter(html.Event event) {
    if (!widget.enabled) return;
    event.preventDefault();
    _dragCounter++;
    if (_dragCounter == 1) {
      widget.onDragStateChanged(true);
    }
  }

  void _onDragOver(html.Event event) {
    if (!widget.enabled) return;
    event.preventDefault();
    // Required for drop to work
    (event as dynamic).dataTransfer?.dropEffect = 'copy';
  }

  void _onDragLeave(html.Event event) {
    if (!widget.enabled) return;
    event.preventDefault();
    _dragCounter--;
    if (_dragCounter <= 0) {
      _dragCounter = 0;
      widget.onDragStateChanged(false);
    }
  }

  void _onDrop(html.Event event) {
    if (!widget.enabled) return;
    event.preventDefault();
    event.stopPropagation();

    _dragCounter = 0;
    widget.onDragStateChanged(false);

    final dataTransfer = (event as dynamic).dataTransfer;
    if (dataTransfer == null) return;

    final files = dataTransfer.files as html.FileList?;
    if (files == null || files.isEmpty) return;

    final file = files.first;
    if (file == null) return;

    final reader = html.FileReader();
    reader.onLoadEnd.listen((_) {
      final result = reader.result;
      if (result is Uint8List) {
        widget.onFileDrop(file.name, result);
      } else if (result is List<int>) {
        widget.onFileDrop(file.name, Uint8List.fromList(result));
      }
    });
    reader.readAsArrayBuffer(file);
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
