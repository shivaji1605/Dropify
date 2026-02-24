import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto_guide/custom_snackbar.dart';
import 'dart:developer';

// --- NEW IMPORTS ---
import 'dart:io'; 
import 'package:image_picker/image_picker.dart'; 
import 'package:firebase_storage/firebase_storage.dart'; 

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final _titleController = TextEditingController();
  final _urlController = TextEditingController();
  // final _thumbnailController = TextEditingController(); // --- REMOVED ---
  final _orderController = TextEditingController();

  // --- NEW STATE VARIABLES ---
  File? _imageFile;
  String? _imageName;
  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    // _thumbnailController.dispose(); // --- REMOVED ---
    _orderController.dispose();
    super.dispose();
  }

  // --- NEW FUNCTION: To pick an image from the gallery ---
  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _imageName = image.name; // To show the user
      });
    }
  }

  // --- MODIFIED: This function now uploads the image first ---
  Future<void> _saveVideo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // --- NEW: Check if an image was picked ---
    if (_imageFile == null) {
      CustomSnackbar().showCustomSnackbar(context, "Please select a thumbnail image.", bgColor: Colors.red);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- 1. Upload the image to Firebase Storage ---
      final String storagePath = 'video_thumbnails/${DateTime.now().millisecondsSinceEpoch}-${_imageName}';
      final Reference storageRef = FirebaseStorage.instance.ref().child(storagePath);
      
      UploadTask uploadTask = storageRef.putFile(_imageFile!);
      TaskSnapshot snapshot = await uploadTask;
      String downloadUrl = await snapshot.ref.getDownloadURL();
      
      // --- 2. Save the DOWNLOAD URL to Firestore ---
      await FirebaseFirestore.instance.collection('videos').add({
        'title': _titleController.text.trim(),
        'url': _urlController.text.trim(),
        'thumbnail': downloadUrl, // <-- SAVE THE URL, NOT A PATH
        'order': int.tryParse(_orderController.text.trim()) ?? 0,
      });

      if (mounted) {
        CustomSnackbar().showCustomSnackbar(context, "Video saved successfully!", bgColor: Colors.green);
        Navigator.of(context).pop();
      }
    } catch (e) {
      log("Error saving video: $e");
      if (mounted) {
        CustomSnackbar().showCustomSnackbar(context, "Failed to save video.", bgColor: Colors.red);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Videos"),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add/Edit Video", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(labelText: "Video Title"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  TextFormField(
                    controller: _urlController,
                    decoration: const InputDecoration(labelText: "YouTube URL"),
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  
                  // --- MODIFIED: Thumbnail text field is replaced ---
                  const SizedBox(height: 24),
                  const Text("Thumbnail Image", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 8),
                  Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _imageFile != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.file(_imageFile!, fit: BoxFit.cover),
                          )
                        : const Center(child: Text("No thumbnail selected", style: TextStyle(color: Colors.grey))),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.upload_file),
                    label: Text(_imageName ?? "Select Thumbnail Image"),
                    onPressed: _pickImage,
                  ),
                  // --- END OF MODIFICATION ---

                  TextFormField(
                    controller: _orderController,
                    decoration: const InputDecoration(labelText: "Order"),
                    keyboardType: TextInputType.number,
                    validator: (v) => v!.isEmpty ? "Required" : null,
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save),
                      label: const Text("Save Video"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      ),
                      onPressed: _isLoading ? null : _saveVideo,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }
}