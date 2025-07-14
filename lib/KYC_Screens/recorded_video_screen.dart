import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:nagpur_mahanagarpalika/KYC_Screens/declaration_page_screen.dart';

import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

import 'package:video_player/video_player.dart';

class VideoPlayerKYCScreen extends StatefulWidget {
  final String videoPath;
  final String recordedDate;
  final String recordedTime;
  // final String imagePath;
  final String aadhaarNumber;
  // final String latitude;
  // final String longitude;
  // final String address;
  final bool isFrontCamera;
  final String ppoNumber;
  final String mobileNumber;
  final String addressEnter;
  final String gender;
  final String fullName;
  //     final String frontImagePath;
  // final String backImagePath;

  const VideoPlayerKYCScreen({
    super.key,
    required this.videoPath,
    required this.recordedDate,
    required this.recordedTime,
    // required this.imagePath,
    required this.aadhaarNumber,
    // required this.latitude,
    // required this.longitude,
    // required this.address,
    required this.isFrontCamera,
    required this.ppoNumber,
    required this.mobileNumber,
    required this.addressEnter,
    required this.gender,
    required this.fullName, 
  });

  @override
  _VideoPlayerKYCScreenState createState() => _VideoPlayerKYCScreenState();
}

class _VideoPlayerKYCScreenState extends State<VideoPlayerKYCScreen> {
  late VideoPlayerController _controller;
  bool _isLoading = false; // Variable to track loading state

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.file(File(widget.videoPath))
      ..initialize().then((_) {
        setState(() {}); // Refresh the screen once the video is initialized
      });
  }

  @override
  void dispose() {
    _controller
        .dispose(); // Dispose of the controller when the widget is disposed
    super.dispose();
  }

  Future<void> submitVideo(BuildContext context) async {
    setState(() {
      _isLoading = true; // Start loading when the button is clicked
    });

    // Simulating a delay for processing (e.g., video compression)
    await Future.delayed(Duration(seconds: 2));

    setState(() {
      _isLoading = false; // Stop loading after the delay
    });

    // Navigate to another screen after the button is pressed
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeclarationPageScreen(
          ppoNumber: widget.ppoNumber,
          // latitude: widget.latitude, // Pass latitude to the navigated screen
          // longitude: widget.longitude,
          // address: widget.address, // Pass longitude to the navigated screen
          videoPath: widget.videoPath, // Use widget.videoPath here
          // recordedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          // recordedTime: DateFormat('HH:mm:ss').format(DateTime.now()),
          // imagePath: widget.imagePath,
          aadhaarNumber: widget.aadhaarNumber,
            // frontImagePath: widget.frontImagePath, // Pass front image path
            // backImagePath: widget.backImagePath, 
        ),
      ),
    );
  }

  void showSubmitConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: Row(
            children: [
              Icon(Icons.video_call,
                  color: Colors.blue, size: 28), // Icon for video
              SizedBox(width: 10),
              Text(
                'Submit Video',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(thickness: 2.5),
              Text(
                'Are you sure you want to submit this video?\nतुम्हाला खात्री आहे की तुम्ही हा व्हिडिओ सबमिट करू इच्छिता?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              Divider(thickness: 2.5),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            ElevatedButton(
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Submit button color
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () {
                // Close the dialog
                submitVideo(context); // Submit video and navigate
              },
            ),
          ],
        );
      },
    );
  }

  Future<File> compressImage(String imagePath) async {
    final File imageFile = File(imagePath);
    final Directory tempDir = await getTemporaryDirectory();
    final String targetPath =
        '${tempDir.path}/${basename(imagePath)}_compressed.jpg';

    final XFile? compressedImage =
        await FlutterImageCompress.compressAndGetFile(
      imageFile.absolute.path,
      targetPath,
      quality: 30, // Adjust quality as needed (0 - 100)
    );

    return compressedImage != null ? File(compressedImage.path) : imageFile;
  }


  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Center(
            child: Text(
              'Upload Video [Step-5]',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 27, 107, 212),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Center(
                  child: Text(
                    'Recorded Video',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Center(
                  child: Text(
                    'रेकॉर्ड केलेला व्हिडिओ',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    height: 350,
                    width: 350,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF7FD),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF92B7F7),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x9B9B9BC1),
                          blurRadius: 10,
                          spreadRadius: 0,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: _controller.value.isInitialized
                          ? Stack(
                              alignment: Alignment.topCenter,
                              children: [
                                SizedBox(
                                  width: 600,
                                  height: 300,
                                  child: AspectRatio(
                                    aspectRatio: _controller.value.aspectRatio,
                                    child: widget.isFrontCamera
                                        ? Transform(
                                            alignment: Alignment.center,
                                            transform: Matrix4.rotationZ(
                                                90 * (3.14159 / 45)),
                                            child: VideoPlayer(_controller),
                                          )
                                        : Transform(
                                            alignment: Alignment.center,
                                            transform: Matrix4.rotationZ(
                                                90 * (3.14159 / 45)),
                                            child: VideoPlayer(_controller),
                                          ),
                                  ),
                                ),
                                Positioned(
                                  top: 10,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Recorded Date: ${widget.recordedDate}',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        'Recorded Time: ${widget.recordedTime}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : CircularProgressIndicator(),
                    ),
                  ),
                ),
                const SizedBox(height: 80),
                ElevatedButton(
                  onPressed: _isLoading
                      ? null
                      : () => showSubmitConfirmationDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color.fromARGB(255, 27, 107, 212),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 10),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(
                          strokeWidth: 2,
                        )
                      : const Text(
                          'Submit video\nव्हिडिओ सबमिट करा',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: Container(
          padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: const Color.fromARGB(255, 243, 163, 33),
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
                child: const Text(
                  'Re-Record\nव्हिडिओ परत रेकॉर्ड करा',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FloatingActionButton(
                onPressed: () async {
                  if (_controller.value.isInitialized) {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                        // Set volume to 1.0 (maximum) when playing
                        _controller.setVolume(1.0);
                      }
                    });
                  }
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _controller.value.isPlaying
                          ? Icons.pause
                          : Icons.play_arrow,
                      size: 30,
                    ),
                    const Text(
                      "व्हिडिओ प्ले करा",
                      style: TextStyle(fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

