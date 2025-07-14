import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'dart:io';

import 'package:nagpur_mahanagarpalika/KYC_Screens/capture_photo_screen.dart';

class UploadAadharPhotos extends StatefulWidget {
  final String aadhaarNumber;
  final String ppoNumber;
  final String mobileNumber;
  final String addressEnter;
  final String gender;
  final String fullName;

  const UploadAadharPhotos({
    super.key,
    required this.aadhaarNumber,
    required this.ppoNumber,
    required this.mobileNumber,
    required this.addressEnter,
    required this.gender,
    required this.fullName,
  });

  @override
  _UploadAadharPhotosState createState() => _UploadAadharPhotosState();
}

class _UploadAadharPhotosState extends State<UploadAadharPhotos> {
  File? _frontImage;
  File? _backImage;
  final ImagePicker _picker = ImagePicker();
  bool _isCompressing = false;

  Future<File?> _compressImage(File file) async {
    try {
      final filePath = file.absolute.path;

      // Create output file path
      final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
      final splitted = filePath.substring(0, (lastIndex));
      final outPath = "${splitted}_compressed${filePath.substring(lastIndex)}";

      final result = await FlutterImageCompress.compressAndGetFile(
        filePath,
        outPath,
        quality: 30, // adjust quality (0-100)
        minWidth: 1024, // adjust width as needed
        minHeight: 1024, // adjust height as needed
      );

      return result != null ? File(result.path) : file;
    } catch (e) {
      print('Error compressing image: $e');
      return file; // return original if compression fails
    }
  }

  Future<void> _pickImage(bool isFront) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() => _isCompressing = true);

      final file = File(pickedFile.path);
      final compressedFile = await _compressImage(file);

      setState(() {
        if (isFront) {
          _frontImage = compressedFile;
        } else {
          _backImage = compressedFile;
        }
        _isCompressing = false;
      });
    }
  }

  Future<void> _submitAadharPhotos() async {
    if (_frontImage == null || _backImage == null) return;

    // Show confirmation dialog first
    bool? confirmSubmission = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
          title: Row(children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            SizedBox(width: 10),
            Text('Confirm Submission',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(thickness: 2.5),
              Text(
                'Are you sure you want to submit this Aadhar photos?\nतुम्हाला खात्री आहे की तुम्ही हे आधार फोटो सबमिट करू इच्छिता??',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              Divider(thickness: 2.5),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Colors.red)),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: Text('Submit'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0)),
              ),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmSubmission != true) return;

    setState(() => _isCompressing = true);

    try {
      // Compress images again before submission
      final compressedFront = await _compressImage(_frontImage!);
      final compressedBack = await _compressImage(_backImage!);

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://nagpurpensioner.altwise.in/api/aadhar/SubmitAadharData'), // Update with your API endpoint
      );

      // Add all required fields to request
      request.fields['AadhaarNumber'] = widget.aadhaarNumber;
      request.fields['PPONumber'] = widget.ppoNumber;
      request.fields['MobileNumber'] = widget.mobileNumber;
      request.fields['Address'] = widget.addressEnter;
      request.fields['Gender'] = widget.gender;
      request.fields['FullName'] = widget.fullName;

      // Add front and back images
      request.files.add(await http.MultipartFile.fromPath(
        'AadharFront',
        compressedFront?.path ?? _frontImage!.path,
        filename: path.basename(compressedFront?.path ?? _frontImage!.path),
        contentType: MediaType('image', 'jpeg'),
      ));

      request.files.add(await http.MultipartFile.fromPath(
        'AadharBack',
        compressedBack?.path ?? _backImage!.path,
        filename: path.basename(compressedBack?.path ?? _backImage!.path),
        contentType: MediaType('image', 'jpeg'),
      ));

      // Debug print request details
      print('Request fields: ${request.fields}');
      print('Request files:');
      for (var file in request.files) {
        print(' - ${file.field}: ${file.filename}');
      }

      // Send the request
      var response = await request.send().timeout(Duration(seconds: 240));

      // Read response
      String responseBody = await response.stream.bytesToString();
      print('Response status: ${response.statusCode}');
      print('Response body: $responseBody');

      if (!mounted) return;

      if (response.statusCode == 200) {
        // Navigate to next screen on success
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoClickKYCScreen(
              aadhaarNumber: widget.aadhaarNumber,
              ppoNumber: widget.ppoNumber,
              mobileNumber: widget.mobileNumber,
              addressEnter: widget.addressEnter,
              gender: widget.gender,
              fullName: widget.fullName,
              frontImagePath: compressedFront?.path ?? _frontImage!.path,
              backImagePath: compressedBack?.path ?? _backImage!.path,
            ),
          ),
        );
      } else {
        // Show error in dialog
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 10),
                Text('Submission Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to submit Aadhar photos. Please try again.\n'
                  'आधार फोटो सबमिट करण्यात अयशस्वी. कृपया पुन्हा प्रयत्न करा.',
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
              ],
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      }
    } on TimeoutException {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.timer_off, color: Colors.orange),
              SizedBox(width: 10),
              Text('Request Timeout'),
            ],
          ),
          content: Text(
            'The request timed out. Please check your internet connection and try again.\n'
            'विनंतीची मुदत संपली. कृपया तुमचे इंटरनेट कनेक्शन तपासा आणि पुन्हा प्रयत्न करा.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Text('Error'),
            ],
          ),
          content: Text(
            'Please check your internet connection\n कृपया तुमचे इंटरनेट कनेक्शन तपासा.',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
      print('Error during submission: $e');
    } finally {
      if (mounted) {
        setState(() => _isCompressing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF551561),
        title: Text(
          ' Upload Aadhar Card Photos',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Text(
                  'Click Aadhar Card Front Photo\nआधार कार्डचा समोरील फोटो काढा.',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 30),

                // Front Side Upload
                _buildUploadCard(
                  isFront: true,
                  image: _frontImage,
                  onTap: () => _pickImage(true),
                ),
                SizedBox(height: 30),
                Text(
                  'Click Aadhar Card Back Photo\nआधार कार्डचा मागील फोटो काढा.',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  textAlign: TextAlign.center,
                ),
                // Back Side Upload
                _buildUploadCard(
                  isFront: false,
                  image: _backImage,
                  onTap: () => _pickImage(false),
                ),
                SizedBox(height: 40),

                // Submit Button
                ElevatedButton(
                  onPressed: _frontImage != null &&
                          _backImage != null &&
                          !_isCompressing
                      ? _submitAadharPhotos
                      : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                    child: Text(
                      'Submit',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
                    backgroundColor: const Color(0xFF551561),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 5,
                    shadowColor: Colors.teal.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          if (_isCompressing)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadCard({
    required bool isFront,
    required File? image,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isCompressing ? null : onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 10,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(
            color: Color(0xFFEAAFEA),
            width: 1.5,
          ),
        ),
        child: image == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 50,
                    color: Color(0xFFEAAFEA),
                  ),
                  SizedBox(height: 10),
                  Text(
                    isFront ? 'Front Side' : 'Back Side',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.blue[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Tap to upload',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.file(
                      image,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    if (_isCompressing)
                      Container(
                        color: Colors.black.withOpacity(0.3),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}


// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:flutter_image_compress/flutter_image_compress.dart';
// import 'dart:io';

// import 'package:nagpur_mahanagarpalika/KYC_Screens/capture_photo_screen.dart';

// class UploadAadharPhotos extends StatefulWidget {
//   final String aadhaarNumber;
//   // final String frontImagePath;
//   // final String backImagePath;
//   final String ppoNumber;
//   final String mobileNumber;
//   final String addressEnter;
//   final String gender;
//   final String fullName;

//   const UploadAadharPhotos({
//     super.key,
//     required this.aadhaarNumber,
//     // required this.frontImagePath,
//     // required this.backImagePath,
//     required this.ppoNumber,
//     required this.mobileNumber,
//     required this.addressEnter,
//     required this.gender,
//     required this.fullName,
//   });

//   @override
//   _UploadAadharPhotosState createState() => _UploadAadharPhotosState();
// }

// class _UploadAadharPhotosState extends State<UploadAadharPhotos> {
//   File? _frontImage;
//   File? _backImage;
//   final ImagePicker _picker = ImagePicker();
//   bool _isCompressing = false;

//   Future<File?> _compressImage(File file) async {
//     try {
//       final filePath = file.absolute.path;

//       // Create output file path
//       final lastIndex = filePath.lastIndexOf(RegExp(r'.jp'));
//       final splitted = filePath.substring(0, (lastIndex));
//       final outPath = "${splitted}_compressed${filePath.substring(lastIndex)}";

//       final result = await FlutterImageCompress.compressAndGetFile(
//         filePath,
//         outPath,
//         quality: 30, // adjust quality (0-100)
//         minWidth: 1024, // adjust width as needed
//         minHeight: 1024, // adjust height as needed
//       );

//       return result != null ? File(result.path) : file;
//     } catch (e) {
//       print('Error compressing image: $e');
//       return file; // return original if compression fails
//     }
//   }

//   Future<void> _pickImage(bool isFront) async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.camera);

//     if (pickedFile != null) {
//       setState(() => _isCompressing = true);

//       final file = File(pickedFile.path);
//       final compressedFile = await _compressImage(file);

//       setState(() {
//         if (isFront) {
//           _frontImage = compressedFile;
//         } else {
//           _backImage = compressedFile;
//         }
//         _isCompressing = false;
//       });
//     }
//   }

//   Future<void> _navigateWithCompressedImages() async {
//     if (_frontImage == null || _backImage == null) return;

//     setState(() => _isCompressing = true);

//     try {
//       // Compress images again before navigation (optional)
//       final compressedFront = await _compressImage(_frontImage!);
//       final compressedBack = await _compressImage(_backImage!);

//       if (!mounted) return;

//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => PhotoClickKYCScreen(
//             aadhaarNumber: widget.aadhaarNumber,
//               ppoNumber: widget.ppoNumber,
//                             mobileNumber: widget.mobileNumber,
//                             addressEnter: widget.addressEnter,
//                             gender: widget.gender,
//                             fullName: widget.fullName,
//             frontImagePath: (compressedFront ?? _frontImage!).path,
//             backImagePath: (compressedBack ?? _backImage!).path,
//           ),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Error compressing images: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() => _isCompressing = false);
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF551561),
//         title: Text(
//           ' Upload Aadhar Card Photos',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: Stack(
//         children: [
//           SingleChildScrollView(
//             padding: EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 Text(
//                   'Click Aadhar Card Front Photo\nआधार कार्डचा समोरील फोटो काढा.',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black),
//                   textAlign: TextAlign.center,
//                 ),
//                 SizedBox(height: 30),

//                 // Front Side Upload
//                 _buildUploadCard(
//                   isFront: true,
//                   image: _frontImage,
//                   onTap: () => _pickImage(true),
//                 ),
//                 SizedBox(height: 30),
//                 Text(
//                   'Click Aadhar Card Back Photo\nआधार कार्डचा मागील फोटो काढा.',
//                   style: TextStyle(
//                       fontSize: 18,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black),
//                   textAlign: TextAlign.center,
//                 ),
//                 // Back Side Upload
//                 _buildUploadCard(
//                   isFront: false,
//                   image: _backImage,
//                   onTap: () => _pickImage(false),
//                 ),
//                 SizedBox(height: 40),

//                 // Submit Button
//                 ElevatedButton(
//                   onPressed: _frontImage != null &&
//                           _backImage != null &&
//                           !_isCompressing
//                       ? _navigateWithCompressedImages
//                       : null,
//                   child: Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//                     child: Text(
//                       'Submit',
//                       style: TextStyle(fontSize: 20, color: Colors.white),
//                     ),
//                   ),
//                   style: ElevatedButton.styleFrom(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
//                     backgroundColor: const Color(0xFF551561),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(10),
//                     ),
//                     elevation: 5,
//                     shadowColor: Colors.teal.withOpacity(0.3),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           if (_isCompressing)
//             Container(
//               color: Colors.black.withOpacity(0.5),
//               child: Center(
//                 child: CircularProgressIndicator(),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildUploadCard({
//     required bool isFront,
//     required File? image,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: _isCompressing ? null : onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         width: double.infinity,
//         height: 200,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.3),
//               spreadRadius: 2,
//               blurRadius: 10,
//               offset: Offset(0, 3),
//             ),
//           ],
//           border: Border.all(
//             color: Color(0xFFEAAFEA),
//             width: 1.5,
//           ),
//         ),
//         child: image == null
//             ? Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.cloud_upload,
//                     size: 50,
//                     color: Color(0xFFEAAFEA),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     isFront ? 'Front Side' : 'Back Side',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.blue[800],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 5),
//                   Text(
//                     'Tap to upload',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               )
//             : ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Stack(
//                   children: [
//                     Image.file(
//                       image,
//                       width: double.infinity,
//                       height: double.infinity,
//                       fit: BoxFit.cover,
//                     ),
//                     if (_isCompressing)
//                       Container(
//                         color: Colors.black.withOpacity(0.3),
//                         child: Center(
//                           child: CircularProgressIndicator(),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//       ),
//     );
//   }
// }

// import 'package:divyank_pmc/DivyangPMC/capture_photo_screen.dart';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class UploadAadharPhotos extends StatefulWidget {
//   final String aadhaarNumber;

//   const UploadAadharPhotos({
//     super.key,
//     required this.aadhaarNumber,
//   });

//   _UploadAadharPhotosState createState() => _UploadAadharPhotosState();
// }

// class _UploadAadharPhotosState extends State<UploadAadharPhotos> {
//   File? _frontImage;
//   File? _backImage;
//   final ImagePicker _picker = ImagePicker();

//   Future<void> _pickImage(bool isFront) async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.camera);

//     if (pickedFile != null) {
//       setState(() {
//         if (isFront) {
//           _frontImage = File(pickedFile.path);
//         } else {
//           _backImage = File(pickedFile.path);
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF551561),
//         title: Text(
//           ' Upload Aadhar Card Photos',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Text(
//               'Click Aadhar Card Front Photo\nआधार कार्डचा समोरील फोटो काढा.',
//               style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 30),

//             // Front Side Upload
//             _buildUploadCard(
//               isFront: true,
//               image: _frontImage,
//               onTap: () => _pickImage(true),
//             ),
//             SizedBox(height: 30),
//             Text(
//               'Click Aadhar Card Back Photo\nआधार कार्डचा मागील फोटो काढा.',
//               style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black),
//               textAlign: TextAlign.center,
//             ),
//             // Back Side Upload
//             _buildUploadCard(
//               isFront: false,
//               image: _backImage,
//               onTap: () => _pickImage(false),
//             ),
//             SizedBox(height: 40),

//             // Submit Button
//             ElevatedButton(
//               onPressed: _frontImage != null && _backImage != null
//                   ? () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PhotoClickScreen(
//                             aadhaarNumber: widget.aadhaarNumber,
//                             frontImagePath: _frontImage!.path,
//                             backImagePath: _backImage!.path,
//                             // aadhaarNumber: '',
//                           ),
//                         ),
//                       );
//                     }
//                   : null,
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//                 child: Text(
//                   'Submit',
//                   style: TextStyle(fontSize: 20, color: Colors.white),
//                 ),
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
//                 backgroundColor: const Color(0xFF551561),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 elevation: 5,
//                 shadowColor: Colors.teal.withOpacity(0.3),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUploadCard({
//     required bool isFront,
//     required File? image,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         width: double.infinity,
//         height: 200,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.3),
//               spreadRadius: 2,
//               blurRadius: 10,
//               offset: Offset(0, 3),
//             ),
//           ],
//           border: Border.all(
//             color: Color(0xFFEAAFEA),
//             width: 1.5,
//           ),
//         ),
//         child: image == null
//             ? Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.cloud_upload,
//                     size: 50,
//                     color: Color(0xFFEAAFEA),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     isFront ? 'Front Side' : 'Back Side',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.blue[800],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 5),
//                   Text(
//                     'Tap to upload',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               )
//             : ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.file(
//                   image,
//                   width: double.infinity,
//                   height: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//       ),
//     );
//   }
// }

// class AadharVerificationScreen extends StatelessWidget {
//   final String frontImagePath;
//   final String backImagePath;

//   const AadharVerificationScreen({
//     Key? key,
//     required this.frontImagePath,
//     required this.backImagePath,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Aadhar Verification'),
//         backgroundColor: const Color(0xFF551561),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(20.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               'Front Image:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),
//             Container(
//               height: 200,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Image.file(File(frontImagePath), fit: BoxFit.cover),
//             ),
//             SizedBox(height: 20),
//             Text(
//               'Back Image:',
//               style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),
//             Container(
//               height: 200,
//               width: double.infinity,
//               decoration: BoxDecoration(
//                 border: Border.all(color: Colors.grey),
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Image.file(File(backImagePath), fit: BoxFit.cover),
//             ),
//             SizedBox(height: 30),
//             Center(
//               child: ElevatedButton(
//                 onPressed: () {
//                   // Add your verification logic here
//                 },
//                 child: Text('Verify Aadhar'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: const Color(0xFF551561),
//                   padding: EdgeInsets.symmetric(horizontal: 30, vertical: 12),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';

// class UploadAadharPhotos extends StatefulWidget {
//   @override
//   _UploadAadharPhotosState createState() => _UploadAadharPhotosState();
// }

// class _UploadAadharPhotosState extends State<UploadAadharPhotos> {
//   File? _frontImage;
//   File? _backImage;
//   final ImagePicker _picker = ImagePicker();

//   Future<void> _pickImage(bool isFront) async {
//     final pickedFile = await _picker.pickImage(source: ImageSource.camera);

//     if (pickedFile != null) {
//       setState(() {
//         if (isFront) {
//           _frontImage = File(pickedFile.path);
//         } else {
//           _backImage = File(pickedFile.path);
//         }
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF551561),
//         title: Text(
//           ' Upload Aadhar Card Photos',
//           style: TextStyle(
//             color: Colors.white, // White text color for contrast
//             fontSize: 20, // Font size for the title
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         centerTitle: true,
//         elevation: 0,
//       ),
//       body: SingleChildScrollView(
//         padding: EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Text(
//               'Click Aadhar Card Front Photo\nआधार कार्डचा समोरील फोटो काढा.',
//               style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black),
//               textAlign: TextAlign.center,
//             ),
//             SizedBox(height: 30),

//             // Front Side Upload
//             _buildUploadCard(
//               isFront: true,
//               image: _frontImage,
//               onTap: () => _pickImage(true),
//             ),
//             SizedBox(height: 30),
//             Text(
//               'Click Aadhar Card Back Photo\nआधार कार्डचा मागील फोटो काढा.',
//               style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.black),
//               textAlign: TextAlign.center,
//             ),
//             // Back Side Upload
//             _buildUploadCard(
//               isFront: false,
//               image: _backImage,
//               onTap: () => _pickImage(false),
//             ),
//             SizedBox(height: 40),

//             // Submit Button
//             ElevatedButton(
//               onPressed: _frontImage != null && _backImage != null
//                   ? () {
//                       // Handle submission
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(
//                             content: Text('Aadhar uploaded successfully!')),
//                       );
//                     }
//                   : null,
//               child: Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 30, vertical: 10),
//                 child: Text(
//                   'Submit',
//                   style: TextStyle(fontSize: 20, color: Colors.white),
//                 ),
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 35, vertical: 8),
//                 backgroundColor: const Color(0xFF551561),
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//                 elevation: 5,
//                 shadowColor: Colors.teal.withOpacity(0.3),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildUploadCard({
//     required bool isFront,
//     required File? image,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(20),
//       child: Container(
//         width: double.infinity,
//         height: 200,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.grey.withOpacity(0.3),
//               spreadRadius: 2,
//               blurRadius: 10,
//               offset: Offset(0, 3),
//             ),
//           ],
//           border: Border.all(
//             color: Color(0xFFEAAFEA),
//             width: 1.5,
//           ),
//         ),
//         child: image == null
//             ? Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Icon(
//                     Icons.cloud_upload,
//                     size: 50,
//                     color: Color(0xFFEAAFEA),
//                   ),
//                   SizedBox(height: 10),
//                   Text(
//                     isFront ? 'Front Side' : 'Back Side',
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.blue[800],
//                       fontWeight: FontWeight.w500,
//                     ),
//                   ),
//                   SizedBox(height: 5),
//                   Text(
//                     'Tap to upload',
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey[600],
//                     ),
//                   ),
//                 ],
//               )
//             : ClipRRect(
//                 borderRadius: BorderRadius.circular(20),
//                 child: Image.file(
//                   image,
//                   width: double.infinity,
//                   height: double.infinity,
//                   fit: BoxFit.cover,
//                 ),
//               ),
//       ),
//     );
//   }
// }
