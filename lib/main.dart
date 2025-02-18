import 'dart:io';
import 'dart:typed_data'; // For Uint8List
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saver_gallery/saver_gallery.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Camera App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const MyHomePage(title: 'Camera'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  XFile? _imageFile;

  Future<void> _takePhoto() async {
    // Request camera permission
    var cameraStatus = await Permission.camera.request();
    if (cameraStatus.isDenied) {
      // Handle the case when permission is denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission denied')),
      );
      return;
    }

    if (cameraStatus.isPermanentlyDenied) {
      // Handle the case when permission is permanently denied
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Camera permission permanently denied')),
      );
      openAppSettings(); // Open app settings to allow the user to enable it manually
      return;
    }

    // If Android 11 or higher, Scoped Storage is enough. No need for storage permission.
    // You don't need to ask for Permission.storage for Android 11 or above

    // Use the image_picker package to take a photo
    final ImagePicker _picker = ImagePicker();
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);

    if (photo != null) {
      setState(() {
        _imageFile = photo;
      });

      // Convert the photo file into a byte array (Uint8List)
      final Uint8List imageBytes = await photo.readAsBytes();

      // Save the image to the gallery using saver_gallery
      final result = await SaverGallery.saveImage(
        imageBytes, // Passing Uint8List instead of File
        skipIfExists: true, // Provide the skipIfExists parameter
        fileName: 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      // Handle save result
      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo saved to gallery')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save photo')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120.0), // Height of the panel
        child: Container(
          margin: const EdgeInsets.only(top: 24),
          color: const Color(0xFF578FCA),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(Icons.camera_alt, color: Colors.white),
                const SizedBox(width: 10),
                Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (_imageFile != null)
              Padding(
                padding: const EdgeInsets.all(16.0), // Padding around the image
                child: Image.file(
                  File(_imageFile!.path),
                  width: 400, // Set a fixed width for the image
                  height: 500, // Set a fixed height for the image
                  fit: BoxFit
                      .cover, // Ensures the image fits within the given space
                ),
              )
            else
              const Text(
                'No photo taken yet',
                style: TextStyle(fontSize: 17),
              ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _takePhoto,
              child: const Text(
                'Take Photo',
                style: TextStyle(color: Color(0xFF578FCA), fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
