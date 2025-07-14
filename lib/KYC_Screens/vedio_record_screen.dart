import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/recorded_video_screen.dart';

import 'package:path_provider/path_provider.dart';

class VideoRecordKYCScreen extends StatefulWidget {
  // final String imagePath;
  final String aadhaarNumber;
  // final String latitude;
  // final String longitude;
  // final String address;
  final String ppoNumber;
  final String mobileNumber;
  final String addressEnter;
  final String gender;
  final String fullName;
  //    final String frontImagePath;
  // final String backImagePath;

  const VideoRecordKYCScreen({
    super.key,
    // required this.imagePath,
    required this.aadhaarNumber,
    // required this.latitude,
    // required this.longitude,
    // required this.address,
    required this.ppoNumber,
    required this.mobileNumber,
    required this.addressEnter,
    required this.gender,
    required this.fullName,
  });

  @override
  _VideoRecordKYCScreenState createState() => _VideoRecordKYCScreenState();
}

class _VideoRecordKYCScreenState extends State<VideoRecordKYCScreen> {
  late List<CameraDescription> cameras;
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  // Recording control variables
  bool isRecording = false;
  late String videoPath;
  bool _isBlinking = false;
  Timer? _blinkTimer;
  Timer? _timer;
  int _elapsedTime = 0;
  int duration = 6; // Default recording duration: 6 seconds
  bool isFrontCamera = true;

  // Device type detection
  bool? _isTablet;

  @override
  void initState() {
    super.initState();
    // Lock screen orientation to portrait during recording
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    initCamera();
  }

  // Detect if the device is a tablet
  bool isTablet(BuildContext context) {
    if (_isTablet != null) return _isTablet!;

    final shortestSide = MediaQuery.of(context).size.shortestSide;
    _isTablet = shortestSide >= 600; // Standard tablet detection
    return _isTablet!;
  }

  // Initialize available cameras
  Future<void> initCamera() async {
    cameras = await availableCameras();
    setCamera(CameraLensDirection.back); // Start with back camera
  }

  // Set camera based on lens direction
  Future<void> setCamera(CameraLensDirection direction) async {
    final selectedCamera =
        cameras.firstWhere((camera) => camera.lensDirection == direction);

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.high,
      enableAudio: false, // No audio needed
    );
    _initializeControllerFuture = _controller!.initialize();
    setState(() {});
  }

  // Toggle between front and back camera
  Future<void> switchCamera() async {
    if (isFrontCamera) {
      await setCamera(CameraLensDirection.back);
    } else {
      await setCamera(CameraLensDirection.front);
    }
    isFrontCamera = !isFrontCamera;
  }

  @override
  void dispose() {
    // Reset screen orientation and clean up timers/controllers
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _controller?.dispose();
    _blinkTimer?.cancel();
    _timer?.cancel();
    super.dispose();
  }

  // Start recording video
  Future<void> startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      Fluttertoast.showToast(
        msg: "Camera not initialized",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      // Prepare storage path
      final Directory extDir = await getApplicationDocumentsDirectory();
      final String dirPath = '${extDir.path}/Videos';
      await Directory(dirPath).create(recursive: true);

      final String filePath =
          '$dirPath/${DateTime.now().millisecondsSinceEpoch}.mp4';

      // Start recording
      await _controller!.startVideoRecording();
      setState(() {
        isRecording = true;
        videoPath = filePath;
        _elapsedTime = 0;
      });

      _startBlinking(); // Red blinking indicator
      _startTimer(); // Show recording time counter

      // Wait until desired duration completes
      await Future.delayed(Duration(seconds: duration));

      // Stop recording and save file
      final XFile videoFile = await _controller!.stopVideoRecording();
      final File recordedFile = File(videoFile.path);
      await recordedFile.copy(filePath); // Save video
      await recordedFile.delete(); // Remove temporary file

      setState(() {
        isRecording = false;
        videoPath = filePath;
      });

      _stopBlinking();
      _timer?.cancel();

      Fluttertoast.showToast(
        msg: "Video Recorded!",
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );

      // Navigate to video preview screen
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerKYCScreen(
            // latitude: widget.latitude,
            // longitude: widget.longitude,
            // address: widget.address,
            videoPath: videoPath,
            recordedDate: DateFormat('yyyy-MM-dd').format(DateTime.now()),
            recordedTime: DateFormat('HH:mm:ss').format(DateTime.now()),
            // imagePath: widget.imagePath,
            aadhaarNumber: widget.aadhaarNumber,
            ppoNumber: widget.ppoNumber,
            mobileNumber: widget.mobileNumber,
            addressEnter: widget.addressEnter,
            gender: widget.gender,
            fullName: widget.fullName,
            isFrontCamera: isFrontCamera,
            // frontImagePath: widget.frontImagePath, // Pass front image path
            // backImagePath: widget.backImagePath, 
            // inputFieldOneValue: widget.inputFieldOneValue,
            // selectedDropdownValue: widget.selectedDropdownValue,
          ),
        ),
      );
    } catch (e) {
      print('Error recording video: $e');

      if (isRecording) {
        try {
          await _controller!.stopVideoRecording();
        } catch (stopError) {
          print('Error stopping video after failure: $stopError');
        }

        setState(() {
          isRecording = false;
        });

        _stopBlinking();
        _timer?.cancel();

        await SystemChrome.setPreferredOrientations(DeviceOrientation.values);

        Fluttertoast.showToast(
          msg:
              "Recording failed: ${e.toString().substring(0, min(50, e.toString().length))}",
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    }
  }

  // Stop recording manually (not used in auto recording flow)
  Future<void> stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    try {
      final XFile videoFile = await _controller!.stopVideoRecording();
      setState(() {
        isRecording = false;
        videoPath = videoFile.path;
      });

      _stopBlinking();
      _timer?.cancel();
    } catch (e) {
      print('Error stopping video recording: $e');
    }
  }

  // Red blinking indicator for recording
  void _startBlinking() {
    _blinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      setState(() {
        _isBlinking = !_isBlinking;
      });
    });
  }

  void _stopBlinking() {
    _blinkTimer?.cancel();
    setState(() {
      _isBlinking = false;
    });
  }

  // Timer to track elapsed recording time
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _elapsedTime++;
      });

      if (_elapsedTime >= duration) {
        _timer?.cancel();
      }
    });
  }

  Widget _buildCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    final preview = CameraPreview(_controller!);
    final previewSize = _controller!.value.previewSize!;
    final cameraAspectRatio = previewSize.height / previewSize.width;

    final isFrontCamera =
        _controller!.description.lensDirection == CameraLensDirection.front;
    final isBackCamera =
        _controller!.description.lensDirection == CameraLensDirection.back;

    // Set rotation angle based on camera type
    double rotationAngle = 0;
    if (isFrontCamera) {
      rotationAngle = pi + pi; // Rotate right (90°)
    } else if (isBackCamera) {
      rotationAngle = pi + pi; // Rotate left (90°)
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: SizedBox(
        height: 600,
        width: 650,
        child: Transform.rotate(
          angle: rotationAngle,
          child: AspectRatio(
            aspectRatio: cameraAspectRatio, // Invert ratio after rotation
            child: preview,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Center(
            child: Text(
              ' Upload Video [Step-5]',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 27, 107, 212),
        ),
        body: _controller == null
            ? const Center(child: CircularProgressIndicator())
            : FutureBuilder<void>(
                future: _initializeControllerFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          const Center(
                            child: Text(
                              'Click Pensioner Video',
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
                              'वेतनधारक व्यक्तीचा व्हिडिओ काढा',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                left: 20,
                                right: 20,
                                top: 30,
                              ),
                              child: Stack(
                                children: [
                                  _buildCameraPreview(),
                                  if (!isRecording)
                                    const Positioned(
                                      top: 22,
                                      left: 40.0,
                                      right: 10.0,
                                      child: Text(
                                        'Make sure your face is clearly visible\nDo not look left or right\nPlease look front of the camera',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  if (isRecording)
                                    Positioned(
                                      right: 40.0,
                                      top: 10.0,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Recording... ${_elapsedTime}s',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Icon(
                                            Icons.radio_button_checked,
                                            color: _isBlinking
                                                ? Colors.red
                                                : Colors.transparent,
                                            size: 50,
                                          ),
                                          Text(
                                            'Date: ${DateFormat('yyyy-MM-dd').format(DateTime.now())}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            'Time: ${DateFormat('HH:mm:ss').format(DateTime.now())}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          // Recording and switch camera buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              ElevatedButton.icon(
                                onPressed: isRecording
                                    ? null
                                    : () async {
                                        await startVideoRecording();
                                      },
                                icon: const Icon(
                                  Icons.videocam,
                                  color: Colors.white,
                                ),
                                label: const Text(
                                  'Start Recording\nव्हिडिओ रेकॉर्ड करा',
                                  textAlign: TextAlign.center,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Color.fromARGB(255, 27, 107, 212),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 10),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.switch_camera_sharp,
                                      color: Color.fromARGB(255, 27, 107, 212),
                                      size: 40,
                                    ),
                                    onPressed:
                                        isRecording ? null : switchCamera,
                                  ),
                                  const Text("कॅमेरा बदला"),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
      ),
    );
  }
}
