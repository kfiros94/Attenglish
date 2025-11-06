import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/lesson_service.dart';

/// Widget for uploading and managing multiple images
class ImageUploadWidget extends StatefulWidget {
  final List<String> initialImageUrls;
  final String lessonId;
  final Function(List<String> imageUrls) onImagesChanged;
  final int maxImages;

  const ImageUploadWidget({
    super.key,
    this.initialImageUrls = const [],
    required this.lessonId,
    required this.onImagesChanged,
    this.maxImages = 10,
  });

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  List<String> _imageUrls = [];
  final Map<String, bool> _uploadingImages = {};
  final Map<String, double> _uploadProgress = {};

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImageUrls);
  }

  /// Pick and upload image files
  Future<void> _pickAndUploadImages() async {
    if (_imageUrls.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxImages} images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Pick files
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      // Limit to remaining slots
      final remainingSlots = widget.maxImages - _imageUrls.length;
      final filesToUpload = result.files.take(remainingSlots).toList();

      if (filesToUpload.length < result.files.length) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Only uploading ${filesToUpload.length} images (${widget.maxImages} max)',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Upload each file
      for (final file in filesToUpload) {
        await _uploadSingleImage(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Upload a single image file
  Future<void> _uploadSingleImage(PlatformFile file) async {
    // Validate file size (5MB)
    if (!LessonService.instance.isFileSizeValid(file.size, 5)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} is too large. Maximum size: 5MB'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Validate file type
    if (!LessonService.instance.isValidImageFile(file.name)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} is not a valid image'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Check if file bytes are available
    if (file.bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read ${file.name}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    setState(() {
      _uploadingImages[tempId] = true;
      _uploadProgress[tempId] = 0.0;
    });

    try {
      print('Starting upload for ${file.name}, size: ${file.size} bytes');

      // Upload file
      final imageUrl = await LessonService.instance.uploadImage(
        widget.lessonId,
        file.bytes!,
        file.name,
      );

      print('Upload completed: $imageUrl');

      if (mounted) {
        setState(() {
          _imageUrls.add(imageUrl);
          _uploadingImages.remove(tempId);
          _uploadProgress.remove(tempId);
        });

        // Notify parent
        widget.onImagesChanged(_imageUrls);

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${file.name} uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Upload error: $e');

      if (mounted) {
        setState(() {
          _uploadingImages.remove(tempId);
          _uploadProgress.remove(tempId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload ${file.name}: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  /// Delete image
  Future<void> _deleteImage(String imageUrl) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
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
      await LessonService.instance.deleteFile(imageUrl);

      setState(() {
        _imageUrls.remove(imageUrl);
      });

      // Notify parent
      widget.onImagesChanged(_imageUrls);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final canUploadMore = _imageUrls.length < widget.maxImages;

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.image, color: Colors.purple),
                  const SizedBox(width: 8),
                  Text(
                    'Images',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
              Text(
                '${_imageUrls.length}/${widget.maxImages}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Upload images (JPG, PNG, GIF) - Max ${widget.maxImages} images, 5MB each',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),

          // Images grid
          if (_imageUrls.isNotEmpty || _uploadingImages.isNotEmpty)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 150,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _imageUrls.length + _uploadingImages.length,
              itemBuilder: (context, index) {
                if (index < _imageUrls.length) {
                  // Uploaded image
                  return _buildImageThumbnail(_imageUrls[index]);
                } else {
                  // Uploading placeholder
                  final tempId = _uploadingImages.keys.elementAt(
                    index - _imageUrls.length,
                  );
                  return _buildUploadingPlaceholder(tempId);
                }
              },
            ),

          if (_imageUrls.isNotEmpty || _uploadingImages.isNotEmpty)
            const SizedBox(height: 16),

          // Upload button
          ElevatedButton.icon(
            onPressed: canUploadMore ? _pickAndUploadImages : null,
            icon: const Icon(Icons.add_photo_alternate),
            label: Text(
              canUploadMore
                  ? 'Upload Images'
                  : 'Maximum ${widget.maxImages} images reached',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey.shade300,
              disabledForegroundColor: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  /// Build image thumbnail
  Widget _buildImageThumbnail(String imageUrl) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300, width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: 150,
                height: 150,
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
              errorWidget: (context, url, error) {
                print('Upload widget thumbnail error: $error');
                print('URL: $url');
                return Container(
                  width: 150,
                  height: 150,
                  color: Colors.grey.shade200,
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, color: Colors.red),
                      SizedBox(height: 4),
                      Text(
                        'Load failed',
                        style: TextStyle(fontSize: 10, color: Colors.red),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(20),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              color: Colors.white,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
              onPressed: () => _deleteImage(imageUrl),
              tooltip: 'Delete image',
            ),
          ),
        ),
      ],
    );
  }

  /// Build uploading placeholder
  Widget _buildUploadingPlaceholder(String tempId) {
    final progress = _uploadProgress[tempId] ?? 0.0;

    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
          ),
          const SizedBox(height: 8),
          Text(
            'Uploading...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
