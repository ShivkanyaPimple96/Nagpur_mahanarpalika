import 'dart:io';


import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:nagpur_mahanagarpalika/KYC_Screens/vedio_record_screen.dart';

class PhotoClickKYCScreen extends StatefulWidget {
  final String aadhaarNumber;
  final String ppoNumber;
  final String mobileNumber;
  final String addressEnter;
  final String gender;
  final String fullName;
  final String frontImagePath;
  final String backImagePath;

  const PhotoClickKYCScreen({
    super.key,
    required this.aadhaarNumber,
    required this.ppoNumber,
    required this.mobileNumber,
    required this.addressEnter,
    required this.gender,
    required this.fullName,
    required this.frontImagePath,
    required this.backImagePath,
  });

  @override
  _PhotoClickKYCScreenState createState() => _PhotoClickKYCScreenState();
}

class _PhotoClickKYCScreenState extends State<PhotoClickKYCScreen> {
  File? _image;
  bool _isLoading = false;
  String? _latitude;
  String? _longitude;
  String? _address;

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.camera);

    if (pickedImage != null) {
      setState(() {
        _image = File(pickedImage.path);
        _isLoading = true;
      });

      try {
        await _getCurrentLocation();
      } catch (e) {
        print('Error getting location: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('No image selected.');
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      print('Location services are disabled.');
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied');
      return;
    }

    final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _latitude = position.latitude.toString();
      _longitude = position.longitude.toString();
    });

    await _getAddressFromCoordinates(position.latitude, position.longitude);
  }

  Future<void> _getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String address = '';
        if (place.street != null) address += '${place.street}, ';
        if (place.subLocality != null) address += '${place.subLocality}, ';
        if (place.locality != null) address += '${place.locality}, ';
        if (place.administrativeArea != null)
          address += '${place.administrativeArea}, ';
        if (place.postalCode != null) address += '${place.postalCode}, ';
        address = address.replaceAll(RegExp(r', $'), '');

        setState(() {
          _address = address;
        });
      } else {
        setState(() {
          _address = 'No address found for these coordinates';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _address = 'Failed to get address';
      });
    }
  }

  Future<File?> _compressImage(File imageFile) async {
    try {
      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        '${imageFile.path}_compressed.jpg',
        quality: 50,
        minWidth: 800,
        minHeight: 800,
      );
      return result != null ? File(result.path) : null;
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  Future<bool> _submitPhotoToAPI(File imageFile) async {
    setState(() {
      _isLoading = true;
    });

    try {
      final compressedImage = await _compressImage(imageFile);
      if (compressedImage == null) {
        throw Exception('Image compression failed');
      }

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('YOUR_API_ENDPOINT_HERE'), // Replace with your API endpoint
      );

      // Add all the required fields to your API request
      request.fields['aadhaarNumber'] = widget.aadhaarNumber;
      request.fields['ppoNumber'] = widget.ppoNumber;
      request.fields['mobileNumber'] = widget.mobileNumber;
      request.fields['addressEnter'] = widget.addressEnter;
      request.fields['gender'] = widget.gender;
      request.fields['fullName'] = widget.fullName;
      request.fields['latitude'] = _latitude ?? '';
      request.fields['longitude'] = _longitude ?? '';
      request.fields['address'] = _address ?? '';

      // Add the front and back images if needed
      // request.files.add(await http.MultipartFile.fromPath(
      //   'frontImage',
      //   widget.frontImagePath,
      // ));
      // request.files.add(await http.MultipartFile.fromPath(
      //   'backImage',
      //   widget.backImagePath,
      // ));

      // Add the selfie image
      request.files.add(await http.MultipartFile.fromPath(
        'Selfie',
        compressedImage.path,
      ));

      var response = await request.send().timeout(Duration(seconds: 240));
      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        print('API Response: $responseBody');
        return true;
      } else {
        final errorBody = await response.stream.bytesToString();
        print('API Error: ${response.statusCode} - $errorBody');
        return false;
      }
    } catch (e) {
      print('Error submitting photo: $e');
      return false;
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showSubmitPhotoDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle_outline, color: Colors.blue, size: 28),
              SizedBox(width: 10),
              Text(
                'Confirm Submission',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Divider(thickness: 2.5),
              Text(
                'Are you sure you want to submit the photo?\nतुम्हाला खात्री आहे की तुम्ही हा फोटो सबमिट करू इच्छिता?',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              Divider(thickness: 2.5),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                if (_image != null) {
                  final success = await _submitPhotoToAPI(_image!);
                  if (success) {
                    _navigateToVideoRecordScreen();
                  } else {
                    _showErrorDialog();
                  }
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submission Failed'),
        content: const Text(
            'Failed to submit the photo check your internet connection.\nफोटो सबमिट करण्यात अयशस्वी इंटरनेट कनेक्शन तपासा .'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToVideoRecordScreen() {
    if (_image != null && _latitude != null && _longitude != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoRecordKYCScreen(
            // imagePath: _image!.path,
            aadhaarNumber: widget.aadhaarNumber,
            // latitude: _latitude!,
            // longitude: _longitude!,
            // address: _address!,
            ppoNumber: widget.ppoNumber,
            mobileNumber: widget.mobileNumber,
            addressEnter: widget.addressEnter,
            gender: widget.gender,
            fullName: widget.fullName,
            // frontImagePath: widget.frontImagePath,
            // backImagePath: widget.backImagePath,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 27, 107, 212),
          title: const Center(
            child: Text(
              'Upload Photo [Step-4]',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 50, left: 20, right: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    Center(
                      child: Text(
                        'Click Pensioner Photo',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Center(
                      child: Text(
                        'वेतनधारक व्यक्तीचा फोटो काढा',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black54,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Container(
                        height: 400,
                        width: 350,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF7FD),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF92B7F7),
                            width: 2,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x9B9B9BC1),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: Center(
                                child: _image == null
                                    ? Container(
                                        width: 250,
                                        height: 250,
                                        color: Colors.blueGrey,
                                        child: const Center(
                                          child: Text(
                                            'No Image Captured',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      )
                                    : Image.file(
                                        _image!,
                                        height: 250,
                                        width: 250,
                                        fit: BoxFit.cover,
                                      ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: ElevatedButton(
                                onPressed: _getImage,
                                child: const Text(
                                  "Click Photo\nफोटो काढा",
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 50),
                    if (_isLoading) const CircularProgressIndicator(),
                    SizedBox(height: 20),
                    if (_image != null && !_isLoading)
                      ElevatedButton.icon(
                        onPressed: _showSubmitPhotoDialog,
                        icon: const Icon(Icons.send, size: 28),
                        label: const Text(
                          'Submit Photo\nफोटो सबमिट करा',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                          textAlign: TextAlign.center,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 27, 107, 212),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 10),
                        ),
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



// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:geocoding/geocoding.dart'; // Import Geocoding
// import 'package:geolocator/geolocator.dart'; // Import Geolocator
// import 'package:image_picker/image_picker.dart';
// import 'package:nagpur_mahanagarpalika/KYC_Screens/vedio_record_screen.dart';

// // Import your new screen

// class PhotoClickKYCScreen extends StatefulWidget {
//   final String aadhaarNumber;
//   final String ppoNumber;
//   final String mobileNumber;
//   final String addressEnter;
//   final String gender;
//   final String fullName;
//   final String frontImagePath;
//   final String backImagePath;

//   const PhotoClickKYCScreen({
//     super.key,
//     required this.aadhaarNumber,
//     required this.ppoNumber,
//     required this.mobileNumber,
//     required this.addressEnter,
//     required this.gender,
//     required this.fullName,
//     required this.frontImagePath,
//     required this.backImagePath,
//   });

//   @override
//   _PhotoClickKYCScreenState createState() => _PhotoClickKYCScreenState();
// }

// class _PhotoClickKYCScreenState extends State<PhotoClickKYCScreen> {
//   File? _image;
//   bool _isLoading = false;
//   String? _latitude;
//   String? _longitude;
//   String? _address; // Add a variable to store the address

//   Future<void> _getImage() async {
//     final picker = ImagePicker();
//     final pickedImage = await picker.pickImage(source: ImageSource.camera);

//     if (pickedImage != null) {
//       setState(() {
//         _image = File(pickedImage.path);
//         _isLoading = true; // Start loading
//       });

//       try {
//         await _getCurrentLocation();
//       } catch (e) {
//         print('Error getting location: $e');
//       } finally {
//         setState(() {
//           _isLoading = false; // Stop loading regardless of success
//         });
//       }
//     } else {
//       print('No image selected.');
//     }
//   }

//   Future<void> _getCurrentLocation() async {
//     bool serviceEnabled;
//     LocationPermission permission;

//     // Check if location services are enabled
//     serviceEnabled = await Geolocator.isLocationServiceEnabled();
//     if (!serviceEnabled) {
//       print('Location services are disabled.');
//       return;
//     }

//     // Request location permissions if not already granted
//     permission = await Geolocator.checkPermission();
//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//       if (permission == LocationPermission.denied) {
//         print('Location permissions are denied');
//         return;
//       }
//     }

//     if (permission == LocationPermission.deniedForever) {
//       print(
//           'Location permissions are permanently denied, we cannot request permissions.');
//       return;
//     }

//     // Get the current position
//     final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.high);

//     // Update latitude and longitude values
//     setState(() {
//       _latitude = position.latitude.toString();
//       _longitude = position.longitude.toString();
//     });

//     // Get the address based on the latitude and longitude
//     await _getAddressFromCoordinates(position.latitude, position.longitude);
//   }

//   Future<void> _getAddressFromCoordinates(
//       double latitude, double longitude) async {
//     try {
//       List<Placemark> placemarks =
//           await placemarkFromCoordinates(latitude, longitude);

//       if (placemarks.isNotEmpty) {
//         Placemark place = placemarks[0];

//         // Construct a more complete address
//         String address = '';
//         if (place.street != null) address += '${place.street}, ';
//         if (place.subLocality != null) address += '${place.subLocality}, ';
//         if (place.locality != null) address += '${place.locality}, ';
//         if (place.administrativeArea != null)
//           address += '${place.administrativeArea}, ';
//         if (place.postalCode != null) address += '${place.postalCode}, ';
//         // if (place.country != null) address += place.country;

//         // Remove trailing comma if any
//         address = address.replaceAll(RegExp(r', $'), '');

//         setState(() {
//           _address = address;
//         });
//       } else {
//         setState(() {
//           _address = 'No address found for these coordinates';
//         });
//       }
//     } catch (e) {
//       print('Error getting address: $e');
//       setState(() {
//         _address = 'Failed to get address';
//       });
//     }
//   }

 

//   Future<void> _showSubmitPhotoDialog() async {
//     // Show a confirmation dialog before submitting the photo
//     return showDialog<void>(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20.0), // Rounded corners
//           ),
//           title: const Row(
//             children: [
//               Icon(Icons.check_circle_outline,
//                   color: Colors.blue, size: 28), // Icon
//               SizedBox(width: 10),
//               Text(
//                 'Confirm Submission', // Title text
//                 style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//             ],
//           ),
//           content: const Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Divider(thickness: 2.5), // Top divider
//               Text(
//                 'Are you sure you want to submit the photo?\nतुम्हाला खात्री आहे की तुम्ही हा फोटो सबमिट करू इच्छिता?',
//                 style: TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//               Divider(thickness: 2.5), // Bottom divider
//             ],
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Cancle', style: TextStyle(color: Colors.red)),
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//               },
//             ),
//             TextButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green, // Submit button color
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                 ),
//               ),
//               onPressed: () {
//                 Navigator.of(context).pop(); // Close the dialog
//                 _navigateToVideoRecordScreen(); // Navigate to the next screen
//               },
//               child: const Text('Submit'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _navigateToVideoRecordScreen() {
//     if (_image != null && _latitude != null && _longitude != null) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(
//           builder: (context) => VideoRecordKYCScreen(
//             imagePath: _image!.path,
//             aadhaarNumber: widget.aadhaarNumber,
//             latitude: _latitude!, // Passing latitude
//             longitude: _longitude!,
//             address: _address!,
//             ppoNumber: widget.ppoNumber,
//             mobileNumber: widget.mobileNumber,
//             addressEnter: widget.addressEnter,
//             gender: widget.gender,
//             fullName: widget.fullName,
//             frontImagePath: widget.frontImagePath, // Pass front image path
//             backImagePath: widget.backImagePath,
//             // inputFieldOneValue: widget.inputFieldOneValue,
//             // selectedDropdownValue: widget.selectedDropdownValue,
//             // Passing longitude
//           ),
//         ),
//       );
//     } else {
//       print("No image or location data to submit.");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           backgroundColor: const Color.fromARGB(255, 27, 107, 212),
//           title: const Center(
//             child: Text(
//               'Upload Photo [Step-4]',
//               style: TextStyle(
//                 color: Colors.white, // White text color for contrast
//                 fontSize: 20, // Font size for the title
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ),
//         ),
//         body: SingleChildScrollView(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Padding(
//                 padding: EdgeInsets.only(top: 50, left: 20, right: 20),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
                  
//                     SizedBox(height: 20),
                 
//                     Center(
//                       child: Text(
//                         'Click Pensioner Photo',
//                         style: TextStyle(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black87,
//                           letterSpacing: 1.5,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                     Center(
//                       child: Text(
//                         'वेतनधारक व्यक्तीचा फोटो काढा',
//                         style: TextStyle(
//                           fontSize: 18,
//                           color: Colors.black54,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               Padding(
//                 padding: const EdgeInsets.all(10.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Center(
//                       child: Container(
//                         height: 400,
//                         width: 350,
//                         decoration: BoxDecoration(
//                           color: const Color(0xFFFDF7FD), // Background color
//                           borderRadius: BorderRadius.circular(10),
//                           border: Border.all(
//                             color:
//                                 const Color(0xFF92B7F7), // Border color #EAAFEA
//                             width: 2,
//                           ),
//                           boxShadow: const [
//                             BoxShadow(
//                               color:
//                                   Color(0x9B9B9BC1), // Shadow color #9B9B9BC1
//                               blurRadius: 10, // Softness of shadow
//                               spreadRadius: 0, // Spread effect
//                               offset: Offset(0, 2), // Position (x: 0, y: 2)
//                             ),
//                           ],
//                         ),
//                         child: Column(
//                           children: [
//                             Expanded(
//                               child: Center(
//                                 child: _image == null
//                                     ? Container(
//                                         width: 250,
//                                         height: 250,
//                                         color: Colors.blueGrey,
//                                         child: const Center(
//                                           child: Text(
//                                             'No Image Captured',
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 16,
//                                             ),
//                                           ),
//                                         ),
//                                       )
//                                     : Image.file(
//                                         _image!,
//                                         height: 250,
//                                         width: 250,
//                                         fit: BoxFit.cover, // Adjust image fit
//                                       ),
//                               ),
//                             ),
//                             Padding(
//                               padding: const EdgeInsets.all(8.0),
//                               child: ElevatedButton(
//                                 onPressed: _getImage,
//                                 child: const Text(
//                                   "Click Photo\nफोटो काढा",
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 50),
//                     if (_isLoading) const CircularProgressIndicator(),
//                     SizedBox(height: 20),
//                     if (_latitude != null && _longitude != null)
//                       // Text(
//                       //   'Location: $_latitude, $_longitude\nAddress: $_address',
//                       //   textAlign: TextAlign.center,
//                       // ),
//                       const SizedBox(height: 20),
//                     if (_image != null && !_isLoading)
//                       ElevatedButton.icon(
//                         onPressed: _showSubmitPhotoDialog,

//                         label: const Text(
//                           'Submit Photo\nफोटो सबमिट करा',
//                           style: TextStyle(
//                               fontSize: 20, // Increased text size
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white),
//                           textAlign: TextAlign.center,
//                         ),
                      
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color.fromARGB(255, 27, 107, 212),
//                           foregroundColor: Colors.black,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 40, vertical: 10),
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
  // File? _image;
  // bool _isLoading = false;
  // String? _latitude;
  // String? _longitude;
  // String? _address; // Add a variable to store the address

  // Future<void> _getImage() async {
  //   final picker = ImagePicker();
  //   final pickedImage = await picker.pickImage(source: ImageSource.camera);

  //   if (pickedImage != null) {
  //     setState(() {
  //       _image = File(pickedImage.path);
  //     });

  //     // Get the current location after the image is captured
  //     await _getCurrentLocation();
  //   } else {
  //     print('No image selected.');
  //   }
  // }

  // Future<void> _getCurrentLocation() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   // Check if location services are enabled
  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     print('Location services are disabled.');
  //     return;
  //   }

  //   // Request location permissions if not already granted
  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       print('Location permissions are denied');
  //       return;
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     print(
  //         'Location permissions are permanently denied, we cannot request permissions.');
  //     return;
  //   }

  //   // Get the current position
  //   final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.high);

  //   // Update latitude and longitude values
  //   setState(() {
  //     _latitude = position.latitude.toString();
  //     _longitude = position.longitude.toString();
  //   });

  //   // Get the address based on the latitude and longitude
  //   await _getAddressFromCoordinates(position.latitude, position.longitude);
  // }

  // Future<void> _getAddressFromCoordinates(
  //     double latitude, double longitude) async {
  //   try {
  //     List<Placemark> placemarks =
  //         await placemarkFromCoordinates(latitude, longitude);
  //     Placemark place = placemarks[0];

  //     setState(() {
  //       _address = ' ${place.locality}, ${place.postalCode}, ${place.country}';
  //     });
  //   } catch (e) {
  //     print('Error getting address: $e');
  //   }
  // }

  // Future<void> _showSubmitPhotoDialog() async {
  //   // Show a confirmation dialog before submitting the photo
  //   return showDialog<void>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       return AlertDialog(
  //         shape: RoundedRectangleBorder(
  //           borderRadius: BorderRadius.circular(20.0), // Rounded corners
  //         ),
  //         title: const Row(
  //           children: [
  //             Icon(Icons.check_circle_outline,
  //                 color: Colors.blue, size: 28), // Icon
  //             SizedBox(width: 10),
  //             Text(
  //               'Confirm Submission', // Title text
  //               style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
  //             ),
  //           ],
  //         ),
  //         content: const Column(
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Divider(thickness: 2.5), // Top divider
  //             Text(
  //               'Are you sure you want to submit the photo?\nतुम्हाला खात्री आहे की तुम्ही हा फोटो सबमिट करू इच्छिता?',
  //               style: TextStyle(fontSize: 16),
  //               textAlign: TextAlign.center,
  //             ),
  //             Divider(thickness: 2.5), // Bottom divider
  //           ],
  //         ),
  //         actions: <Widget>[
  //           TextButton(
  //             child: const Text('Cancle', style: TextStyle(color: Colors.red)),
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close the dialog
  //             },
  //           ),
  //           TextButton(
  //             style: ElevatedButton.styleFrom(
  //               backgroundColor: Colors.green, // Submit button color
  //               shape: RoundedRectangleBorder(
  //                 borderRadius: BorderRadius.circular(12.0),
  //               ),
  //             ),
  //             onPressed: () {
  //               Navigator.of(context).pop(); // Close the dialog
  //               _navigateToVideoRecordScreen(); // Navigate to the next screen
  //             },
  //             child: const Text('Submit'),
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // void _navigateToVideoRecordScreen() {
  //   if (_image != null && _latitude != null && _longitude != null) {
  //     Navigator.push(
  //       context,
  //       MaterialPageRoute(
  //         builder: (context) => VideoRecordKYCScreen(
  //           imagePath: _image!.path,
  //           aadhaarNumber: widget.aadhaarNumber,
  //           latitude: _latitude!, // Passing latitude
  //           longitude: _longitude!,
  //           address: _address!,

  //           // Passing longitude
  //         ),
  //       ),
  //     );
  //   } else {
  //     print("No image or location data to submit.");
  //   }
  // }

  // @override
  // Widget build(BuildContext context) {
  //   return SafeArea(
  //     child: Scaffold(
  //       backgroundColor: Colors.white,
  //       appBar: AppBar(
  //         backgroundColor: const Color(0xFF92B7F7),
  //         title: const Center(
  //           child: Text(
  //             'Upload Photo [Step-4]',
  //             style: TextStyle(
  //               color: Colors.black, // White text color for contrast
  //               fontSize: 18, // Font size for the title
  //               fontWeight: FontWeight.bold,
  //             ),
  //           ),
  //         ),
  //       ),
  //       body: SingleChildScrollView(
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             const Padding(
  //               padding: EdgeInsets.only(top: 50, left: 20, right: 20),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   // Text("Aadhar Number: ${widget.aadhaarNumber}"),
  //                   // Text("Input Field One Value: ${widget.inputFieldOneValue}"),
  //                   // Text(
  //                   //     "Selected Dropdown Value: ${widget.selectedDropdownValue ?? 'None'}"),
  //                   // Text(
  //                   //   'Aadhaar Number: ${widget.aadhaarNumber}',
  //                   //   style: const TextStyle(fontSize: 16, color: Colors.black),
  //                   // ),
  //                   SizedBox(height: 20),
  //                   Center(
  //                     child: Text(
  //                       'Click Divyang Photo',
  //                       style: TextStyle(
  //                         fontSize: 24,
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.black87,
  //                         letterSpacing: 1.5,
  //                       ),
  //                       textAlign: TextAlign.center,
  //                     ),
  //                   ),
  //                   Center(
  //                     child: Text(
  //                       'दिव्यांग व्यक्तीचा फोटो काढा',
  //                       style: TextStyle(
  //                         fontSize: 18,
  //                         color: Colors.black54,
  //                       ),
  //                       textAlign: TextAlign.center,
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             Padding(
  //               padding: const EdgeInsets.all(10.0),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.center,
  //                 children: [
  //                   Center(
  //                     child: Container(
  //                       height: 400,
  //                       width: 350,
  //                       decoration: BoxDecoration(
  //                         color: const Color(0xFFFDF7FD), // Background color
  //                         borderRadius: BorderRadius.circular(10),
  //                         border: Border.all(
  //                           color:
  //                               const Color(0xFF92B7F7), // Border color #EAAFEA
  //                           width: 2,
  //                         ),
  //                         boxShadow: const [
  //                           BoxShadow(
  //                             color:
  //                                 Color(0x9B9B9BC1), // Shadow color #9B9B9BC1
  //                             blurRadius: 10, // Softness of shadow
  //                             spreadRadius: 0, // Spread effect
  //                             offset: Offset(0, 2), // Position (x: 0, y: 2)
  //                           ),
  //                         ],
  //                       ),
  //                       child: Column(
  //                         children: [
  //                           Expanded(
  //                             child: Center(
  //                               child: _image == null
  //                                   ? Container(
  //                                       width: 250,
  //                                       height: 250,
  //                                       color: Colors.blueGrey,
  //                                       child: const Center(
  //                                         child: Text(
  //                                           'No Image Captured',
  //                                           style: TextStyle(
  //                                             color: Colors.white,
  //                                             fontSize: 16,
  //                                           ),
  //                                         ),
  //                                       ),
  //                                     )
  //                                   : Image.file(
  //                                       _image!,
  //                                       height: 250,
  //                                       width: 250,
  //                                       fit: BoxFit.cover, // Adjust image fit
  //                                     ),
  //                             ),
  //                           ),
  //                           Padding(
  //                             padding: const EdgeInsets.all(8.0),
  //                             child: ElevatedButton(
  //                               onPressed: _getImage,
  //                               child: const Text(
  //                                 "Click Photo\nफोटो काढा",
  //                                 textAlign: TextAlign.center,
  //                               ),
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ),
  //                   const SizedBox(height: 20),
  //                   // Display latitude and longitude if available
  //                   if (_latitude != null && _longitude != null)
  //                     _isLoading
  //                         ? const CircularProgressIndicator()
  //                         : ElevatedButton(
  //                             onPressed: () {
  //                               if (_image != null &&
  //                                   _latitude != null &&
  //                                   _longitude != null) {
  //                                 _showSubmitPhotoDialog(); // Show confirmation dialog before submitting
  //                               } else {
  //                                 print("No image or location data to submit.");
  //                               }
  //                             },
  //                             style: ElevatedButton.styleFrom(
  //                               padding: const EdgeInsets.symmetric(
  //                                   horizontal: 50, vertical: 10),
  //                               backgroundColor: const Color(0xFF92B7F7),
  //                               shape: RoundedRectangleBorder(
  //                                 borderRadius: BorderRadius.circular(10),
  //                               ),
  //                               elevation: 5,
  //                               // shadowColor: Colors.green.withOpacity(0.3),
  //                             ),
  //                             child: const Text(
  //                               'Submit Photo\nफोटो सबमिट करा',
  //                               style: TextStyle(
  //                                 fontSize: 18,
  //                                 fontWeight: FontWeight.bold,
  //                                 color: Colors.black,
  //                                 letterSpacing: 1.5,
  //                               ),
  //                               textAlign: TextAlign.center,
  //                             ),
  //                           ),
  //                 ],
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

