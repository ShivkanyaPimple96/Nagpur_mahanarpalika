import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:nagpur_mahanagarpalika/KYC_Screens/aadhar_verification_screen.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/view_certificate_screen.dart';

class PensionerDetailesScreen extends StatefulWidget {
  final String ppoNumber;
  final String mobileNumber;
  final String fullName;
  final String verificationStatus;
  final String url;
  final String aadhaarNumber;
  final String addresss;
  final String gender;
  final String bankName;

  const PensionerDetailesScreen({
    super.key,
    required this.ppoNumber,
    required this.mobileNumber,
    required this.fullName,
    required this.verificationStatus,
    required this.url,
    required this.aadhaarNumber,
    required this.addresss,
    required this.gender,
    required this.bankName,
  });

  @override
  State<PensionerDetailesScreen> createState() =>
      _PensionerDetailesScreenState();
}

class _PensionerDetailesScreenState extends State<PensionerDetailesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  String? _selectedGender;
  String? _storedAadhar;
  String? _storedAddress;
  String? _storedGender;
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedGender = 'Male';
    _fetchPensionerDetails();
  }

  // Future<void> _fetchPensionerDetails() async {
  //   try {
  //     final response = await http.get(
  //       Uri.parse(
  //           'https://nagpurpensioner.altwise.in/api/aadhar/GetUserDetails?PPONumber=${widget.ppoNumber}'),
  //     );

  //     if (response.statusCode == 200) {
  //       final responseData = json.decode(response.body);
  //       setState(() {
  //         _storedAadhar = responseData['AadhaarNumber'] ?? '';
  //         _storedAddress = responseData['Address'] ?? '';
  //         _storedGender = responseData['Gender'] ?? '';
  //         _aadharController.text = _storedAadhar ?? '';
  //         _addressController.text = _storedAddress ?? '';
  //         _selectedGender = _storedGender;
  //         _dataLoaded = true;
  //       });
  //     } else {
  //       setState(() {
  //         _dataLoaded = true;
  //       });
  //     }
  //   } catch (e) {
  //     print('Error fetching details: $e');
  //     setState(() {
  //       _dataLoaded = true;
  //     });
  //   }
  // }

  _fetchPensionerDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://nagpurpensioner.altwise.in/api/aadhar/GetUserDetails?PPONumber=${widget.ppoNumber}'),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        setState(() {
          _storedAadhar = responseData['AadhaarNumber'] ?? '';
          _storedAddress = responseData['Address'] ?? '';
          // Ensure the gender value matches one of your dropdown items
          _storedGender =
              responseData['Gender'] == 'Female' ? 'Female' : 'Male';
          _aadharController.text = _storedAadhar ?? '';
          _addressController.text = _storedAddress ?? '';
          _selectedGender = _storedGender;
          _dataLoaded = true;
        });
      } else {
        setState(() {
          _dataLoaded = true;
        });
      }
    } catch (e) {
      print('Error fetching details: $e');
      setState(() {
        _dataLoaded = true;
      });
    }
  }

  @override
  void dispose() {
    _aadharController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _validateAndProceed() async {
    // Validate form fields
    bool isValid = true;
    String? errorMessage;

    if (_aadharController.text.isEmpty) {
      errorMessage = 'Please enter Aadhaar number';
      isValid = false;
    } else if (_aadharController.text.length != 12) {
      errorMessage = 'Aadhaar must be exactly 12 digits';
      isValid = false;
    } else if (_addressController.text.isEmpty) {
      errorMessage = 'Please enter your address';
      isValid = false;
    } else if (_selectedGender == null || _selectedGender!.isEmpty) {
      errorMessage = 'Please select your gender';
      isValid = false;
    }

    if (!isValid) {
      Fluttertoast.showToast(
        msg: errorMessage!,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Prepare request body with correct field names
      final Map<String, dynamic> requestBody = {
        "PPONumber": widget.ppoNumber,
        "AadhaarNumber": _aadharController.text,
        "Address": _addressController.text,
        "Gender": _selectedGender,
      };

      print('Sending request: ${json.encode(requestBody)}');

      // Make API call
      final response = await http.post(
        Uri.parse(
            'https://nagpurpensioner.altwise.in/api/aadhar/UpdateUserDetails'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );

      print('API Response: ${response.statusCode} - ${response.body}');

      setState(() {
        _isLoading = false;
      });

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        Fluttertoast.showToast(
          msg: responseData['Message'] ?? 'Details updated successfully',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.green,
          textColor: Colors.white,
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AadharVerificationKYCScreen(
              ppoNumber: widget.ppoNumber,
              fullName: widget.fullName,
              mobileNumber: widget.mobileNumber,
              aadharNumber: _aadharController.text,
              addressEnter: _addressController.text,
              gender: _selectedGender!,
            ),
          ),
        );
      } else {
        Fluttertoast.showToast(
          msg: responseData['Message'] ?? 'Failed to update details',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: 'Error: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Pensioner Details [Step-2]',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 27, 107, 212),
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFF92B7F7), width: 2),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInfoCard('PPO Number', widget.ppoNumber),
                                const SizedBox(height: 15),
                                _buildInfoCard('Full Name', widget.fullName),
                                const SizedBox(height: 15),
                                _buildInfoCard(
                                    'Mobile Number', widget.mobileNumber),
                                const SizedBox(height: 15),
                                _buildInfoCard(' BankName', widget.bankName),

                                // Show additional fields if status is Verification In Progress or Approved
                                if ((widget.verificationStatus ==
                                            'Verification In Progress' ||
                                        widget.verificationStatus ==
                                            'Application Approved') &&
                                    _dataLoaded) ...[
                                  const SizedBox(height: 15),
                                  _buildInfoCard(
                                      'AadhaarNumber', widget.aadhaarNumber),
                                  const SizedBox(height: 15),
                                  _buildInfoCard('Addresss', widget.addresss),
                                  const SizedBox(height: 15),
                                  _buildInfoCard('Gender', widget.gender),
                                ],
                              ],
                            ),

                            const SizedBox(height: 20),

                            // Only show these fields if verification is NOT in progress and NOT approved
                            if (widget.verificationStatus !=
                                    'Verification In Progress' &&
                                widget.verificationStatus !=
                                    'Application Approved') ...[
                              Text(
                                'Enter Your Aadhar Number(आधार क्रमांक टाका):',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _aadharController,
                                keyboardType: TextInputType.number,
                                maxLength: 12,
                                decoration: InputDecoration(
                                  hintText: 'Enter 12-digit Aadhar number',
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF92B7F7), width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF92B7F7), width: 2),
                                  ),
                                  errorText: _aadharController
                                              .text.isNotEmpty &&
                                          _aadharController.text.length != 12
                                      ? 'Aadhar must be exactly 12 digits'
                                      : null,
                                ),
                                onChanged: (value) {
                                  setState(() {});
                                },
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Enter Your Address( पत्ता टाका):',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextFormField(
                                controller: _addressController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF92B7F7), width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF92B7F7), width: 2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Enter Your Gender( लिंग टाका):',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // DropdownButtonFormField<String>(
                              //   value: _selectedGender,
                              //   decoration: InputDecoration(
                              //     filled: true,
                              //     fillColor: Colors.white,
                              //     border: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(
                              //           color: Color(0xFF92B7F7), width: 2),
                              //     ),
                              //     focusedBorder: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(10),
                              //       borderSide: const BorderSide(
                              //           color: Color(0xFF92B7F7), width: 2),
                              //     ),
                              //   ),
                              //   items: ['Male', 'Female'].map((String value) {
                              //     return DropdownMenuItem<String>(
                              //       value: value,
                              //       child: Text(value),
                              //     );
                              //   }).toList(),
                              //   onChanged: (newValue) {
                              //     setState(() {
                              //       _selectedGender = newValue;
                              //     });
                              //   },
                              //   hint: const Text('Select Gender'),
                              // ),
                              DropdownButtonFormField<String>(
                                value: _selectedGender,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF92B7F7), width: 2),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: Color(0xFF92B7F7), width: 2),
                                  ),
                                ),
                                items: [
                                  DropdownMenuItem<String>(
                                    value: 'Male',
                                    child: Text('Male'),
                                  ),
                                  DropdownMenuItem<String>(
                                    value: 'Female',
                                    child: Text('Female'),
                                  ),
                                ].toList(),
                                onChanged: (newValue) {
                                  setState(() {
                                    _selectedGender = newValue;
                                  });
                                },
                                hint: const Text('Select Gender'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF92B7F7), width: 2),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _buildInfoCard(
                              'Verification Status', widget.verificationStatus),
                          const SizedBox(height: 30),
                          Center(
                            child: Builder(
                              builder: (context) {
                                if (widget.verificationStatus.isEmpty) {
                                  return ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _validateAndProceed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 27, 107, 212),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 40, vertical: 10),
                                    ),
                                    child: const Text(
                                      'Complete Your KYC\nतुमची केवायसी पूर्ण करा',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                } else if (widget.verificationStatus ==
                                    'Application Rejected') {
                                  return ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _validateAndProceed,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 27, 107, 212),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 40, vertical: 10),
                                    ),
                                    child: const Text(
                                      'Re-Complete Your KYC\nतुमची केवायसी पूर्ण करा',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                } else if (widget.verificationStatus ==
                                    'Verification In Progress') {
                                  return ElevatedButton(
                                    onPressed: () {}, // Disabled button
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          const Color.fromARGB(255, 53, 57, 63),
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 40, vertical: 10),
                                    ),
                                    child: const Text(
                                      'Verification in Process\nपडताळणी प्रक्रियेत आहे',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                } else if (widget.verificationStatus ==
                                    'Application Approved') {
                                  return ElevatedButton(
                                    onPressed: () {
                                      Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CertificateWebViewScreen(
                                                  url: widget.url),
                                        ),
                                        (Route<dynamic> route) => false,
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.black,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      padding: const EdgeInsets.symmetric( 
                                          horizontal: 40, vertical: 10),
                                    ),
                                    child: const Text(
                                      'View Certificate\nप्रमाणपत्र पहा',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  );
                                }
                                return Container();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:nagpur_mahanagarpalika/KYC_Screens/aadhar_verification_screen.dart';
// import 'package:nagpur_mahanagarpalika/KYC_Screens/view_certificate_screen.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// class PensionerDetailesScreen extends StatefulWidget {
//   final String ppoNumber;
//   final String mobileNumber;
//   final String fullName;
//   final String verificationStatus;
//   final String url;

//   const PensionerDetailesScreen({
//     super.key,
//     required this.ppoNumber,
//     required this.mobileNumber,
//     required this.fullName,
//     required this.verificationStatus,
//     required this.url,
//   });

//   @override
//   State<PensionerDetailesScreen> createState() =>
//       _PensionerDetailesScreenState();
// }

// class _PensionerDetailesScreenState extends State<PensionerDetailesScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _aadharController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   bool _isLoading = false;
//   String? _selectedGender;

//   @override
//   void dispose() {
//     _aadharController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }

//   Future<void> _validateAndProceed() async {
//     // Validate form fields
//     bool isValid = true;
//     String? errorMessage;

//     if (_aadharController.text.isEmpty) {
//       errorMessage = 'Please enter Aadhaar number';
//       isValid = false;
//     } else if (_aadharController.text.length != 12) {
//       errorMessage = 'Aadhaar must be exactly 12 digits';
//       isValid = false;
//     } else if (_addressController.text.isEmpty) {
//       errorMessage = 'Please enter your address';
//       isValid = false;
//     } else if (_selectedGender == null || _selectedGender!.isEmpty) {
//       errorMessage = 'Please select your gender';
//       isValid = false;
//     }

//     if (!isValid) {
//       Fluttertoast.showToast(
//         msg: errorMessage!,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Prepare request body with correct field names
//       final Map<String, dynamic> requestBody = {
//         "PPONumber": widget.ppoNumber,
//         "AadhaarNumber": _aadharController.text,
//         "Address": _addressController.text,
//         "Gender": _selectedGender,
//       };

//       print('Sending request: ${json.encode(requestBody)}');

//       // Make API call
//       final response = await http.post(
//         Uri.parse(
//             'https://nagpurpensioner.altwise.in/api/aadhar/UpdateUserDetails'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestBody),
//       );

//       print('API Response: ${response.statusCode} - ${response.body}');

//       setState(() {
//         _isLoading = false;
//       });

//       final responseData = json.decode(response.body);

//       if (response.statusCode == 200) {
//         Fluttertoast.showToast(
//           msg: responseData['Message'] ?? 'Details updated successfully',
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.green,
//           textColor: Colors.white,
//         );

//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AadharVerificationKYCScreen(
//               ppoNumber: widget.ppoNumber,
//               fullName: widget.fullName,
//               mobileNumber: widget.mobileNumber,
//               aadharNumber: _aadharController.text,
//               addressEnter: _addressController.text,
//               gender: _selectedGender!,
//             ),
//           ),
//         );
//       } else {
//         Fluttertoast.showToast(
//           msg: responseData['Message'] ?? 'Failed to update details',
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       Fluttertoast.showToast(
//         msg: 'Error: ${e.toString()}',
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text(
//             'Pensioner Details [Step-2]',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: const Color.fromARGB(255, 27, 107, 212),
//         ),
//         body: Stack(
//           children: [
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                             color: const Color(0xFF92B7F7), width: 2),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildInfoCard('PPO Number', widget.ppoNumber),
//                             const SizedBox(height: 15),
//                             _buildInfoCard('Full Name', widget.fullName),
//                             const SizedBox(height: 15),
//                             _buildInfoCard(
//                                 'Mobile Number', widget.mobileNumber),

//                             const SizedBox(height: 20),

//                             // Only show these fields if verification is NOT in progress and NOT approved
//                             if (widget.verificationStatus !=
//                                     'Verification In Progress' &&
//                                 widget.verificationStatus !=
//                                     'Application Approved') ...[
//                               Text(
//                                 'Enter Your Aadhar Number(आधार क्रमांक टाका):',
//                                 style: TextStyle(
//                                   color: Colors.black54,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               TextFormField(
//                                 controller: _aadharController,
//                                 keyboardType: TextInputType.number,
//                                 maxLength: 12,
//                                 decoration: InputDecoration(
//                                   hintText: 'Enter 12-digit Aadhar number',
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                   errorText: _aadharController
//                                               .text.isNotEmpty &&
//                                           _aadharController.text.length != 12
//                                       ? 'Aadhar must be exactly 12 digits'
//                                       : null,
//                                 ),
//                                 onChanged: (value) {
//                                   setState(() {});
//                                 },
//                               ),
//                               const SizedBox(height: 20),
//                               Text(
//                                 'Enter Your Address( पत्ता टाका):',
//                                 style: TextStyle(
//                                   color: Colors.black54,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               TextFormField(
//                                 controller: _addressController,
//                                 maxLines: 3,
//                                 decoration: InputDecoration(
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//                               Text(
//                                 'Enter Your Gender( लिंग टाका):',
//                                 style: TextStyle(
//                                   color: Colors.black54,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               DropdownButtonFormField<String>(
//                                 value: _selectedGender,
//                                 decoration: InputDecoration(
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                 ),
//                                 items: ['Male', 'Female'].map((String value) {
//                                   return DropdownMenuItem<String>(
//                                     value: value,
//                                     child: Text(value),
//                                   );
//                                 }).toList(),
//                                 onChanged: (newValue) {
//                                   setState(() {
//                                     _selectedGender = newValue;
//                                   });
//                                 },
//                                 hint: const Text('Select Gender'),
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 25),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                             color: const Color(0xFF92B7F7), width: 2),
//                       ),
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           _buildInfoCard(
//                               'Verification Status', widget.verificationStatus),
//                           const SizedBox(height: 30),
//                           Center(
//                             child: Builder(
//                               builder: (context) {
//                                 if (widget.verificationStatus.isEmpty) {
//                                   return ElevatedButton(
//                                     onPressed:
//                                         _isLoading ? null : _validateAndProceed,
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color.fromARGB(
//                                           255, 27, 107, 212),
//                                       foregroundColor: Colors.black,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 40, vertical: 10),
//                                     ),
//                                     child: const Text(
//                                       'Complete Your KYC\nतुमची केवायसी पूर्ण करा',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   );
//                                 } else if (widget.verificationStatus ==
//                                     'Application Rejected') {
//                                   return ElevatedButton(
//                                     onPressed:
//                                         _isLoading ? null : _validateAndProceed,
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color.fromARGB(
//                                           255, 27, 107, 212),
//                                       foregroundColor: Colors.black,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 40, vertical: 10),
//                                     ),
//                                     child: const Text(
//                                       'Re-Complete Your KYC\nतुमची केवायसी पूर्ण करा',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   );
//                                 } else if (widget.verificationStatus ==
//                                     'Verification In Progress') {
//                                   return ElevatedButton(
//                                     onPressed: () {}, // Disabled button
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor:
//                                           const Color.fromARGB(255, 53, 57, 63),
//                                       foregroundColor: Colors.black,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 40, vertical: 10),
//                                     ),
//                                     child: const Text(
//                                       'Verification in Process\nपडताळणी प्रक्रियेत आहे',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   );
//                                 } else if (widget.verificationStatus ==
//                                     'Application Approved') {
//                                   return ElevatedButton(
//                                     onPressed: () {
//                                       Navigator.pushAndRemoveUntil(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               CertificateWebViewScreen(
//                                                   url: widget.url),
//                                         ),
//                                         (Route<dynamic> route) => false,
//                                       );
//                                     },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.green,
//                                       foregroundColor: Colors.black,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 40, vertical: 10),
//                                     ),
//                                     child: const Text(
//                                       'View Certificate\nप्रमाणपत्र पहा',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   );
//                                 }
//                                 return Container();
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (_isLoading)
//               const Center(
//                 child: CircularProgressIndicator(),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.grey[200],
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:nagpur_mahanagarpalika/KYC_Screens/aadhar_verification_screen.dart';
// import 'package:nagpur_mahanagarpalika/KYC_Screens/view_certificate_screen.dart';
// import 'package:fluttertoast/fluttertoast.dart';

// class PensionerDetailesScreen extends StatefulWidget {
//   final String ppoNumber;
//   final String mobileNumber;
//   final String fullName;
//   final String verificationStatus;
//   final String url;

//   const PensionerDetailesScreen({
//     super.key,
//     required this.ppoNumber,
//     required this.mobileNumber,
//     required this.fullName,
//     required this.verificationStatus,
//     required this.url,
//   });

//   @override
//   State<PensionerDetailesScreen> createState() =>
//       _PensionerDetailesScreenState();
// }

// class _PensionerDetailesScreenState extends State<PensionerDetailesScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _aadharController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _genderController = TextEditingController();
//   bool _isLoading = false;
//   String? _selectedGender;

//   @override
//   void dispose() {
//     _aadharController.dispose();
//     _addressController.dispose();
//     _genderController.dispose();
//     super.dispose();
//   }

//   Future<void> _validateAndProceed() async {
//     // Validate form fields
//     bool isValid = true;
//     String? errorMessage;

//     if (_aadharController.text.isEmpty) {
//       errorMessage = 'Please enter Aadhaar number';
//       isValid = false;
//     } else if (_aadharController.text.length != 12) {
//       errorMessage = 'Aadhaar must be exactly 12 digits';
//       isValid = false;
//     } else if (_addressController.text.isEmpty) {
//       errorMessage = 'Please enter your address';
//       isValid = false;
//     } else if (_genderController.text.isEmpty) {
//       errorMessage = 'Please enter your gender';
//       isValid = false;
//     }

//     if (!isValid) {
//       Fluttertoast.showToast(
//         msg: errorMessage!,
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Format gender correctly (trim + capitalize first letter)
//       String formattedGender = _genderController.text.trim();
//       if (formattedGender.isNotEmpty) {
//         formattedGender = formattedGender[0].toUpperCase() +
//             formattedGender.substring(1).toLowerCase();
//       }

//       // Check if gender is valid (Male, Female, Other)
//       final validGenders = {'Male', 'Female', 'Other'};
//       if (!validGenders.contains(formattedGender)) {
//         throw Exception('Invalid gender. Must be Male, Female, or Other');
//       }

//       // Prepare request body with correct field names
//       final Map<String, dynamic> requestBody = {
//         "PPONumber": widget.ppoNumber,
//         "AadhaarNumber": _aadharController.text,
//         "Address": _addressController.text,
//         "Gender": formattedGender,
//       };

//       print('Sending request: ${json.encode(requestBody)}');

//       // Make API call
//       final response = await http.post(
//         Uri.parse(
//             'https://nagpurpensioner.altwise.in/api/aadhar/UpdateUserDetails'),
//         headers: {
//           'Content-Type': 'application/json',
//         },
//         body: json.encode(requestBody),
//       );

//       print('API Response: ${response.statusCode} - ${response.body}');

//       setState(() {
//         _isLoading = false;
//       });

//       final responseData = json.decode(response.body);

//       if (response.statusCode == 200) {
//         Fluttertoast.showToast(
//           msg: responseData['Message'] ?? 'Details updated successfully',
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.green,
//           textColor: Colors.white,
//         );

//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AadharVerificationKYCScreen(
//               ppoNumber: widget.ppoNumber,
//               fullName: widget.fullName,
//               mobileNumber: widget.mobileNumber,
//               aadharNumber: _aadharController.text,
//               addressEnter: _addressController.text,
//               gender: formattedGender,
//             ),
//           ),
//         );
//       } else {
//         Fluttertoast.showToast(
//           msg: responseData['Message'] ?? 'Failed to update details',
//           toastLength: Toast.LENGTH_LONG,
//           gravity: ToastGravity.BOTTOM,
//           backgroundColor: Colors.red,
//           textColor: Colors.white,
//         );
//       }
//     } catch (e) {
//       setState(() {
//         _isLoading = false;
//       });

//       Fluttertoast.showToast(
//         msg: 'Error: ${e.toString()}',
//         toastLength: Toast.LENGTH_LONG,
//         gravity: ToastGravity.BOTTOM,
//         backgroundColor: Colors.red,
//         textColor: Colors.white,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text(
//             'Pensioner Details [Step-2]',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: const Color.fromARGB(255, 27, 107, 212),
//         ),
//         body: Stack(
//           children: [
//             SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         border: Border.all(
//                             color: const Color(0xFF92B7F7), width: 2),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.all(16.0),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             _buildInfoCard('PPO Number', widget.ppoNumber),
//                             const SizedBox(height: 15),
//                             _buildInfoCard('Full Name', widget.fullName),
//                             const SizedBox(height: 15),
//                             _buildInfoCard(
//                                 'Mobile Number', widget.mobileNumber),

//                             const SizedBox(height: 20),

//                             // Only show these fields if verification is NOT in progress and NOT approved
//                             if (widget.verificationStatus !=
//                                     'Verification In Progress' &&
//                                 widget.verificationStatus !=
//                                     'Application Approved') ...[
//                               Text(
//                                 'Enter Your Aadhar Number(आधार क्रमांक टाका):',
//                                 style: TextStyle(
//                                   color: Colors.black54,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               const SizedBox(height: 10),
//                               TextFormField(
//                                 controller: _aadharController,
//                                 keyboardType: TextInputType.number,
//                                 maxLength: 12,
//                                 decoration: InputDecoration(
//                                   hintText: 'Enter 12-digit Aadhar number',
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                   errorText: _aadharController
//                                               .text.isNotEmpty &&
//                                           _aadharController.text.length != 12
//                                       ? 'Aadhar must be exactly 12 digits'
//                                       : null,
//                                 ),
//                                 onChanged: (value) {
//                                   setState(() {});
//                                 },
//                               ),
//                               const SizedBox(height: 20),
//                               Text(
//                                 'Enter Your Address( पत्ता टाका):',
//                                 style: TextStyle(
//                                   color: Colors.black54,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               TextFormField(
//                                 controller: _addressController,
//                                 maxLines: 3,
//                                 decoration: InputDecoration(
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                 ),
//                               ),
//                               const SizedBox(height: 20),
//                               Text(
//                                 'Enter Your Gender( लिंग टाका):',
//                                 style: TextStyle(
//                                   color: Colors.black54,
//                                   fontSize: 15,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               // TextFormField(
//                               //   controller: _genderController,
//                               //   decoration: InputDecoration(
//                               //     filled: true,
//                               //     fillColor: Colors.white,
//                               //     border: OutlineInputBorder(
//                               //       borderRadius: BorderRadius.circular(10),
//                               //       borderSide: const BorderSide(
//                               //           color: Color(0xFF92B7F7), width: 2),
//                               //     ),
//                               //     focusedBorder: OutlineInputBorder(
//                               //       borderRadius: BorderRadius.circular(10),
//                               //       borderSide: const BorderSide(
//                               //           color: Color(0xFF92B7F7), width: 2),
//                               //     ),
//                               //   ),
//                               // ),
//                               DropdownButtonFormField<String>(
//                                 value: _selectedGender,
//                                 decoration: InputDecoration(
//                                   filled: true,
//                                   fillColor: Colors.white,
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                     borderSide: const BorderSide(
//                                         color: Color(0xFF92B7F7), width: 2),
//                                   ),
//                                 ),
//                                 items: ['Male', 'Female'].map((String value) {
//                                   return DropdownMenuItem<String>(
//                                     value: value,
//                                     child: Text(value),
//                                   );
//                                 }).toList(),
//                                 onChanged: (newValue) {
//                                   setState(() {
//                                     _selectedGender = newValue;
//                                   });
//                                 },
//                                 validator: (value) {
//                                   if (value == null || value.isEmpty) {
//                                     return 'Please select gender';
//                                   }
//                                   return null;
//                                 },
//                               ),
//                             ],
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(height: 25),
//                     Container(
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(20),
//                         border: Border.all(
//                             color: const Color(0xFF92B7F7), width: 2),
//                       ),
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         children: [
//                           _buildInfoCard(
//                               'Verification Status', widget.verificationStatus),
//                           const SizedBox(height: 30),
//                           Center(
//                             child: Builder(
//                               builder: (context) {
//                                 if (widget.verificationStatus.isEmpty) {
//                                   return ElevatedButton(
//                                     onPressed:
//                                         _isLoading ? null : _validateAndProceed,
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color.fromARGB(
//                                           255, 27, 107, 212),
//                                       foregroundColor: Colors.black,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 40, vertical: 10),
//                                     ),
//                                     child: const Text(
//                                       'Complete Your KYC\nतुमची केवायसी पूर्ण करा',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   );
//                                 } else if (widget.verificationStatus ==
//                                     'Application Rejected') {
//                                   return ElevatedButton(
//                                     onPressed:
//                                         _isLoading ? null : _validateAndProceed,
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color.fromARGB(
//                                           255, 27, 107, 212),
//                                       foregroundColor: Colors.black,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 40, vertical: 10),
//                                     ),
//                                     child: const Text(
//                                       'Re-Complete Your KYC\nतुमची केवायसी पूर्ण करा',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                   );
//                                 } else if (widget.verificationStatus ==
//                                     'Verification In Progress') {
//                                   return ElevatedButton(
//                                     onPressed: null, // Disabled button
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: const Color.fromARGB(
//                                           255, 27, 107, 212),
//                                       foregroundColor: Colors.black,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 40, vertical: 10),
//                                     ),
//                                     child: const Text(
//                                       'Verification in Process\nसत्यापन प्रक्रियेत आहे',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   );
//                                 } else if (widget.verificationStatus ==
//                                     'Application Approved') {
//                                   return ElevatedButton(
//                                     onPressed: () {
//                                       Navigator.pushAndRemoveUntil(
//                                         context,
//                                         MaterialPageRoute(
//                                           builder: (context) =>
//                                               CertificateWebViewScreen(
//                                                   url: widget.url),
//                                         ),
//                                         (Route<dynamic> route) => false,
//                                       );
//                                     },
//                                     style: ElevatedButton.styleFrom(
//                                       backgroundColor: Colors.green,
//                                       foregroundColor: Colors.black,
//                                       shape: RoundedRectangleBorder(
//                                         borderRadius: BorderRadius.circular(30),
//                                       ),
//                                       padding: const EdgeInsets.symmetric(
//                                           horizontal: 40, vertical: 10),
//                                     ),
//                                     child: const Text(
//                                       'View Certificate\nप्रमाणपत्र पहा',
//                                       style: TextStyle(
//                                         color: Colors.white,
//                                         fontSize: 16,
//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                       textAlign: TextAlign.center,
//                                     ),
//                                   );
//                                 }
//                                 return Container();
//                               },
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//             if (_isLoading)
//               const Center(
//                 child: CircularProgressIndicator(),
//               ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildInfoCard(String title, String value) {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(15),
//       decoration: BoxDecoration(
//         color: Colors.grey[200],
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             title,
//             style: const TextStyle(
//               fontSize: 14,
//               color: Colors.grey,
//             ),
//           ),
//           const SizedBox(height: 5),
//           Text(
//             value,
//             style: const TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
