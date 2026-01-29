import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/lesson_service.dart';

/// Widget for uploading and managing audio files
class AudioUploadWidget extends StatefulWidget {
  final String? initialAudioUrl;
  final String lessonId;
  final Function(String? audioUrl) onAudioChanged;

  const AudioUploadWidget({
    super.key,
    this.initialAudioUrl,
    required this.lessonId,
    required this.onAudioChanged,
  });

  @override
  State<AudioUploadWidget> createState() => _AudioUploadWidgetState();
}

class _AudioUploadWidgetState extends State<AudioUploadWidget> {
  String? _audioUrl;
  String? _fileName;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _audioUrl = widget.initialAudioUrl;
    if (_audioUrl != null) {
      _fileName = _extractFileName(_audioUrl!);
    }
  }

  /// Extract filename from URL
  String _extractFileName(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.pathSegments.last;
      // Remove the audio_ prefix and timestamp
      final parts = path.split('_');
      if (parts.length >= 3) {
        return parts.sublist(2).join('_');
      }
      return path;
    } catch (e) {
      return 'Audio file';
    }
  }

  /// Pick and upload audio file
  Future<void> _pickAndUploadAudio() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;

      // Validate file size (10MB)
      if (!LessonService.instance.isFileSizeValid(file.size, 10)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Audio file too large. Maximum size: 10MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Validate file type
      if (!LessonService.instance.isValidAudioFile(file.name)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid audio format. Allowed: MP3, WAV, M4A'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload file
      final audioUrl = await LessonService.instance.uploadAudio(
        widget.lessonId,
        file.bytes!,
        file.name,
      );

      setState(() {
        _audioUrl = audioUrl;
        _fileName = file.name;
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      // Notify parent
      widget.onAudioChanged(audioUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Delete audio file
  Future<void> _deleteAudio() async {
    if (_audioUrl == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Audio'),
        content: const Text('Are you sure you want to delete this audio file?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      // Delete from storage
      await LessonService.instance.deleteFile(_audioUrl!);

      setState(() {
        _audioUrl = null;
        _fileName = null;
      });

      // Notify parent
      widget.onAudioChanged(null);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Audio deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.audiotrack, color: Colors.blue),
              const SizedBox(width: 8),
              Text(
                'Audio File',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload an audio file (MP3, WAV, M4A) - Max 10MB',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),

          // Upload button or file info
          if (_audioUrl == null)
            // No audio uploaded yet
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _pickAndUploadAudio,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload Audio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            )
          else
            // Audio uploaded - show file info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.music_note,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fileName ?? 'Audio file',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Uploaded successfully',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.play_circle_outline),
                    onPressed: () {
                      // Open audio in new tab to play
                      // ignore: avoid_web_libraries_in_flutter
                      // html.window.open(_audioUrl!, '_blank');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Audio playback coming soon!'),
                        ),
                      );
                    },
                    tooltip: 'Play audio',
                    color: Colors.blue,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _deleteAudio,
                    tooltip: 'Delete audio',
                    color: Colors.red,
                  ),
                ],
              ),
            ),

          // Upload progress
          if (_isUploading) ...[
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _uploadProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            const SizedBox(height: 8),
            Text(
              'Uploading... ${(_uploadProgress * 100).toInt()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
