import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

class MultiImagePicker extends StatefulWidget {
  final List<String> initialImages;
  final Function(List<String>) onImagesChanged;
  final int maxImages;
  final String emptyText;

  const MultiImagePicker({
    super.key,
    this.initialImages = const [],
    required this.onImagesChanged,
    this.maxImages = 10,
    this.emptyText = 'No images selected',
  });

  @override
  State<MultiImagePicker> createState() => _MultiImagePickerState();
}

class _MultiImagePickerState extends State<MultiImagePicker> {
  late List<String> _images;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _images = List.from(widget.initialImages);
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isNotEmpty) {
        for (final file in pickedFiles) {
          if (_images.length >= widget.maxImages) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Maximum ${widget.maxImages} images allowed')),
              );
            }
            break;
          }

          // Read file as bytes and convert to base64
          final bytes = await file.readAsBytes();
          final base64Image = base64Encode(bytes);
          final imageUrl = 'data:image/jpeg;base64,$base64Image';

          setState(() {
            _images.add(imageUrl);
          });
        }

        widget.onImagesChanged(_images);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking images: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _images.removeAt(index);
    });
    widget.onImagesChanged(_images);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with add button
        Row(
          children: [
            Text(
              'Car Images',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              '(${_images.length}/${widget.maxImages})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const Spacer(),
            if (_images.length < widget.maxImages)
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate, size: 18),
                label: const Text('Add Images'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Image grid or empty state
        if (_images.isEmpty)
          _buildEmptyState()
        else
          _buildImageGrid(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[50],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              widget.emptyText,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Select Images'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        return _buildImageCard(index);
      },
    );
  }

  Widget _buildImageCard(int index) {
    return Stack(
      children: [
        // Image
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _buildImage(_images[index]),
          ),
        ),

        // Primary badge (first image)
        if (index == 0)
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Primary',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Delete button
        Positioned(
          top: 8,
          right: 8,
          child: InkWell(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String imageUrl) {
    if (imageUrl.startsWith('data:image')) {
      // Base64 image
      final base64String = imageUrl.split(',')[1];
      final bytes = base64Decode(base64String);
      return Image.memory(
        Uint8List.fromList(bytes),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage();
        },
      );
    } else if (imageUrl.startsWith('http')) {
      // Network image
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
            ),
          );
        },
      );
    } else {
      return _buildErrorImage();
    }
  }

  Widget _buildErrorImage() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(Icons.broken_image, color: Colors.grey[400], size: 32),
      ),
    );
  }
}
