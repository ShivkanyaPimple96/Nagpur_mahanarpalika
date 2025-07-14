import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/capture_photo_screen.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/upload_aadhar_photos.dart';

class AadharVerificationKYCScreen extends StatefulWidget {
  final String fullName;
  final String aadharNumber;
  final String mobileNumber;
  final String addressEnter;
  final String ppoNumber;
  final String gender;

  const AadharVerificationKYCScreen({
    super.key,
    required this.fullName,
    required this.aadharNumber,
    required this.mobileNumber,
    required this.addressEnter,
    required this.ppoNumber,
    required this.gender,
  });

  @override
  _AadharVerificationKYCScreenState createState() =>
      _AadharVerificationKYCScreenState();
}

class _AadharVerificationKYCScreenState
    extends State<AadharVerificationKYCScreen> {
  String fetchedFullName = '';
  String verificationStatus = '';
  String clientId = '';
  String otpStatus = '';
  String profilePhotoUrl = '';
  String aadhaarName = '';
  String aadhaarAddress = '';
  String gender = '';
  String dateOfBirth = '';
  String pincode = '';
  String liveAddress = '';
  String verificationNote = '';

  final TextEditingController otpController = TextEditingController();
  bool isOtpFieldVisible = false;
  bool isSubmitOtpButtonVisible = true;
  bool isNextButtonVisible = false;
  bool isResponseDataVisible = false;

  // Loading state variables
  bool isVerifyingAadharLoading = false;
  bool isSubmittingOtpLoading = false;
  bool isVerificationSuccessful = false;

   File? _frontImage;
  File? _backImage;

  Future<void> verifyAadhar() async {
    try {
      setState(() {
        isVerifyingAadharLoading = true;
      });

      final HttpClient client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final String apiUrl =
          'https://nagpurpensioner.altwise.in/api/aadhar/GetAadharOtp?AadhaarNumber=${widget.aadharNumber}';

      final request = await client.getUrl(Uri.parse(apiUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> responseData = json.decode(responseBody);

        print('API Response: $responseData');

        final data = responseData['data'] ?? {};

        setState(() {
          fetchedFullName = data['full_name'] ?? '';
          verificationStatus = data['VerificationStatus'] ?? '';
          clientId = data['client_id'] ?? '';
          otpStatus = data['otp_sent'] == true ? 'OTP Sent' : 'OTP Not Sent';
          isOtpFieldVisible = data['otp_sent'] == true;
          isVerificationSuccessful = true;
        });

        print('Message: ${responseData['message']}');
      } else {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> errorData = json.decode(responseBody);
        await showErrorDialog(
            'Failed to verify Aadhar number Check Your Aadhar Number. ${errorData['message'] ?? ''}\nआधार क्रमांकाची पडताळणी करण्यात अयशस्वी तुमचा आधार क्रमांक तपासा',
            shouldNavigate: true);
      }
    } catch (error) {
      print('Exception in verifyAadhar: $error');
      await showErrorDialog('An error occurred: $error');
    } finally {
      if (mounted) {
        setState(() {
          isVerifyingAadharLoading = false;
        });
      }
    }
  }

  Future<void> submitOtp() async {
    try {
      setState(() {
        isSubmittingOtpLoading = true;
      });

      final HttpClient client = HttpClient()
        ..badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;

      final String apiUrl =
          'https://nagpurpensioner.altwise.in/api/aadhar/SubmitAadharOtp?AadharNumber=${widget.aadharNumber}&ClientId=$clientId&Otp=${otpController.text}';

      final request = await client.getUrl(Uri.parse(apiUrl));
      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> responseData = json.decode(responseBody);

        print('OTP API Response: $responseData');

        if (responseData['Success'] == true) {
          final combinedData = responseData['combinedViewModel'];
          final aadhaarDetails = combinedData['AadhaarDetails'];

          setState(() {
            profilePhotoUrl = aadhaarDetails['ProfilePhotoUrl'] ?? '';
            aadhaarName = aadhaarDetails['FullName'] ?? '';
            aadhaarAddress = aadhaarDetails['Address'] ?? '';
            gender = aadhaarDetails['Gender'] ?? '';
            dateOfBirth = aadhaarDetails['DateOfBirth'] ?? '';
            pincode = aadhaarDetails['Pincode'] ?? '';
            liveAddress = aadhaarDetails['LiveAddress'] ?? '';
            verificationStatus = aadhaarDetails['VerificationStatus'] ?? '';
            verificationNote = aadhaarDetails['VerificationNote'] ?? '';

            isResponseDataVisible = true;
            isNextButtonVisible = true;
            isSubmitOtpButtonVisible = false;
            isOtpFieldVisible = false;
          });

          await showSuccessDialog('Aadhaar verified successfully!');
        } else {
          await showErrorDialog(
              responseData['Message'] ?? 'OTP verification failed');
        }
      } else {
        final responseBody = await response.transform(utf8.decoder).join();
        final Map<String, dynamic> errorData = json.decode(responseBody);
        await showErrorDialog(
            'Failed to verify OTP, Please check your OTP is correct. Otp already generated for this aadhaar, please try after some time. ${errorData['message'] ?? ''}\nOTP पडताळणी करण्यात अयशस्वी,कृपया तुमचा OTP बरोबर आहे का ते तपासा\nया आधारसाठी ओटीपी आधीच तयार केला आहे, कृपया काही वेळाने प्रयत्न करा.',
            shouldNavigate: true);
      }
    } catch (error) {
      print('Exception in submitOtp: $error');
      await showErrorDialog('An error occurred: $error');
    } finally {
      if (mounted) {
        setState(() {
          isSubmittingOtpLoading = false;
        });
      }
    }
  }

  Future<void> showSuccessDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 10),
              Text(
                'Success',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(thickness: 2.5),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const Divider(thickness: 2.5),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Ok'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showErrorDialog(String message,
      {bool shouldNavigate = false}) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          title: const Row(
            children: [
              SizedBox(width: 10),
              Text(
                'Note',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Divider(thickness: 2.5),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const Divider(thickness: 2.5),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              onPressed: () {
                // Navigator.of(context).pop(); // Close the dialog

                // if (shouldNavigate) {
                //   // Go back until the 3rd screen from the top (current screen is 0, previous is 1, etc.)
                //   int count = 0;
                //   Navigator.of(context).popUntil((_) => count++ >= 1);
                // }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UploadAadharPhotos(
                      aadhaarNumber: widget.aadharNumber,
                      ppoNumber: widget.ppoNumber,
                      mobileNumber: widget.mobileNumber,
                      addressEnter: widget.addressEnter,
                      gender: widget.gender,
                      fullName: widget.fullName,
                    ),
                  ),
                );
              },
              child: const Text('Ok', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text(
            'Aadhar Verification [Step-3]',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 27, 107, 212),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF92B7F7), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x9B9B9BC1),
                      blurRadius: 10,
                      spreadRadius: 0,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.perm_identity,
                        color: Colors.blue, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Aadhar Number: ${widget.aadharNumber}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Center(
                  child: Text(
                'Full Name: ${widget.fullName}',
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              )),
              const SizedBox(height: 20),

              // Center(
              //   child: ElevatedButton(
              //     onPressed: isVerifyingAadharLoading ? null : verifyAadhar,
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: Color.fromARGB(255, 27, 107, 212),
              //       foregroundColor: Colors.black,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(30),
              //       ),
              //       padding: const EdgeInsets.symmetric(
              //           horizontal: 40, vertical: 10),
              //     ),
              //     child: isVerifyingAadharLoading
              //         ? const CircularProgressIndicator(color: Colors.white)
              //         : Text(
              //             "Verify Your Aadhar Number\nआधार क्रमांकाची पडताळणी करा",
              //             style: const TextStyle(
              //               fontSize: 18,
              //               fontWeight: FontWeight.bold,
              //               color: Colors.white,
              //             ),
              //           ),
              //   ),
              // ),

              Center(
                child: !isVerificationSuccessful
                    ? ElevatedButton(
                        onPressed:
                            isVerifyingAadharLoading ? null : verifyAadhar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 27, 107, 212),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 10),
                        ),
                        child: isVerifyingAadharLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : Text(
                                "Verify Your Aadhar Number\nआधार क्रमांकाची पडताळणी करा",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      )
                    : null, // This will hide the button when verification is successful
              ),
              const SizedBox(height: 20),
              if (isOtpFieldVisible) ...[
                const Text(
                  'Enter Aadhar OTP:',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFF92B7F7), width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x9B9B9BC1),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: TextField(
                      controller: otpController,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: 'OTP टाका',
                        hintStyle: TextStyle(color: Colors.grey[600]),
                        counterText: '',
                      ),
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                if (isSubmitOtpButtonVisible)
                  Center(
                    child: ElevatedButton(
                      onPressed: isSubmittingOtpLoading ? null : submitOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 27, 107, 212),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 10),
                      ),
                      child: isSubmittingOtpLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Submit OTP\nOTP सबमिट करा",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              textAlign: TextAlign.center,
                            ),
                    ),
                  ),
              ],
              if (isResponseDataVisible) ...[
                const SizedBox(height: 20),
                const Text(
                  'Aadhar Details:',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
                const Divider(),
                if (profilePhotoUrl.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Color(0xFF92B7F7), width: 2),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              height: 120.0,
                              width: 120.0,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.3),
                                    spreadRadius: 2,
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  profilePhotoUrl,
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Center(
                                      child: Icon(Icons.error,
                                          size: 50, color: Colors.red),
                                    );
                                  },
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        value: loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                    .cumulativeBytesLoaded /
                                                loadingProgress
                                                    .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Name:',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    aadhaarName,
                                    style: const TextStyle(
                                      fontSize: 18.0,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 2,
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    'Gender:',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    gender,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const Divider(
                                    color: Colors.grey,
                                    thickness: 2,
                                  ),
                                  const SizedBox(height: 12.0),
                                  Text(
                                    'Aadhar Address:',
                                    style: TextStyle(
                                      fontSize: 16.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                  Text(
                                    aadhaarAddress,
                                    style: const TextStyle(
                                      fontSize: 16.0,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                SizedBox(height: 20),
              ],
              if (isNextButtonVisible) ...[
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PhotoClickKYCScreen(
                            aadhaarNumber: widget.aadharNumber,
                            ppoNumber: widget.ppoNumber,
                            mobileNumber: widget.mobileNumber,
                            addressEnter: widget.addressEnter,
                            gender: widget.gender,
                            fullName: widget.fullName,
                             frontImagePath: _frontImage?.path ??
                                '', // Provide empty string as default
                            backImagePath: _backImage?.path ??
                                '', 
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 27, 107, 212),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 10),
                    ),
                    child: const Text(
                      'Next',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}


// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:http/io_client.dart';
// import 'package:nagpur_mahanagarpalika/KYC_Screens/capture_photo_screen.dart';

// class AadharVerificationKYCScreen extends StatefulWidget {
//   final String fullName;
//   final String aadharNumber;
//   final String mobileNumber;
//   final String addressEnter;

//   // final String verificationStatusNote;

//   final String ppoNumber;
//   final String gender;

//   const AadharVerificationKYCScreen({
//     super.key,
//     required this.fullName,
//     required this.aadharNumber,
//     required this.mobileNumber,
//     required this.addressEnter,

//     // required this.verificationStatusNote,
//     // required this.inputFieldOneValue,

//     required this.ppoNumber,
//     required this.gender,
//   });

//   @override
//   _AadharVerificationKYCScreenState createState() =>
//       _AadharVerificationKYCScreenState();
// }

// class _AadharVerificationKYCScreenState
//     extends State<AadharVerificationKYCScreen> {
//   String fetchedFullName = '';
//   String verificationStatus = '';
//   String clientId = '';
//   String otpStatus = '';
//   String profilePhotoUrl = '';
//   String aadhaarName = '';
//   String aadhaarAddress = '';
//   String gender = '';
//   String tblDivyangFullName = '';
//   String tblDivyangAddress = '';

//   final TextEditingController otpController = TextEditingController();
//   bool isOtpFieldVisible = false;
//   bool isSubmitOtpButtonVisible = true;
//   bool isNextButtonVisible = false;

//   // Loading state variables
//   bool isVerifyingAadharLoading = false;
//   bool isSubmittingOtpLoading = false;

//   Future<void> verifyAadhar() async {
//     try {
//       setState(() {
//         isVerifyingAadharLoading = true;
//       });

//       // Create a custom HttpClient with bad certificate callback
//       final HttpClient client = HttpClient()
//         ..badCertificateCallback =
//             (X509Certificate cert, String host, int port) => true;

//       final String apiUrl =
//           'https://nagpurpensioner.altwise.in/api/aadhar/GetAadharOtp?AadhaarNumber=${widget.aadharNumber}';

//       // Create the request using the custom client
//       final request = await client.getUrl(Uri.parse(apiUrl));
//       final response = await request.close();

//       if (response.statusCode == 200) {
//         final responseBody = await response.transform(utf8.decoder).join();
//         final Map<String, dynamic> responseData = json.decode(responseBody);

//         // Print the entire response for debugging
//         print('API Response: $responseData');

//         // Access the nested data object
//         final data = responseData['data'] ?? {};

//         setState(() {
//           fetchedFullName = data['full_name'] ?? '';
//           verificationStatus = data['VerificationStatus'] ?? '';
//           clientId = data['client_id'] ?? '';
//           otpStatus = data['otp_sent'] == true ? 'OTP Sent' : 'OTP Not Sent';
//           isOtpFieldVisible = data['otp_sent'] == true;
//         });

//         // Print the success message
//         print('Message: ${responseData['message']}');
//       } else {
//         final responseBody = await response.transform(utf8.decoder).join();
//         final Map<String, dynamic> errorData = json.decode(responseBody);
//         await showErrorDialog(
//             'Failed to verify Aadhar number. ${errorData['message'] ?? ''}\nआधार क्रमांकाची पडताळणी करण्यात अयशस्वी');
//       }
//     } catch (error) {
//       print('Exception in verifyAadhar: $error');
//       await showErrorDialog('An error occurred: $error');
//     } finally {
//       if (mounted) {
//         setState(() {
//           isVerifyingAadharLoading = false;
//         });
//       }
//     }
//   }

//   Future<http.Client> getHttpClient() async {
//     final HttpClient client = HttpClient();
//     client.badCertificateCallback =
//         (X509Certificate cert, String host, int port) => true;
//     return IOClient(client);
//   }

//   Future<void> showErrorDialog(String message) async {
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(20.0),
//           ),
//           title: const Row(
//             children: [
//               SizedBox(width: 10),
//               Text(
//                 'Note',
//                 style: TextStyle(
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//             ],
//           ),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Divider(thickness: 2.5),
//               Text(
//                 message,
//                 style: const TextStyle(fontSize: 16),
//                 textAlign: TextAlign.center,
//               ),
//               const Divider(thickness: 2.5),
//             ],
//           ),
//           actions: <Widget>[
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.green,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(12.0),
//                 ),
//               ),
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Ok'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         appBar: AppBar(
//           title: const Text(
//             'Aadhar Verification [Step-3]',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: const Color.fromARGB(255, 27, 107, 212),
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const SizedBox(height: 10),
//               Container(
//                 padding: const EdgeInsets.all(16.0),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(10),
//                   border: Border.all(color: const Color(0xFF92B7F7), width: 2),
//                   boxShadow: const [
//                     BoxShadow(
//                       color: Color(0x9B9B9BC1),
//                       blurRadius: 10,
//                       spreadRadius: 0,
//                       offset: Offset(0, 2),
//                     )
//                   ],
//                 ),
//                 child: Row(
//                   children: [
//                     const Icon(Icons.perm_identity,
//                         color: Colors.blue, size: 24),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       child: Text(
//                         'Aadhar Number: ${widget.aadharNumber}',
//                         style: const TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 10),
//               Center(
//                   child: Text(
//                 'Full Name: ${widget.fullName}',
//                 style: const TextStyle(
//                   color: Colors.black,
//                   fontSize: 20,
//                   fontWeight: FontWeight.bold,
//                 ),
//               )),
//               const SizedBox(height: 20),
//               Center(
//                 child: ElevatedButton(
//                   onPressed: isVerifyingAadharLoading ? null : verifyAadhar,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color.fromARGB(255, 27, 107, 212),
//                     foregroundColor: Colors.black,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(30),
//                     ),
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 40, vertical: 10),
//                   ),
//                   child: isVerifyingAadharLoading
//                       ? const CircularProgressIndicator(color: Colors.blue)
//                       : Text(
//                           "Verify Your Aadhar Number\nआधार क्रमांकाची पडताळणी करा",
//                           style: const TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                         ),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               if (isOtpFieldVisible) ...[
//                 const Text(
//                   'Enter Aadhar OTP:',
//                   style: TextStyle(
//                     fontSize: 18,
//                     color: Colors.black54,
//                   ),
//                 ),
//                 const SizedBox(height: 10),
//                 Container(
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     border:
//                         Border.all(color: const Color(0xFF92B7F7), width: 2),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Color(0x9B9B9BC1),
//                         blurRadius: 10,
//                         spreadRadius: 0,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                     child: TextField(
//                       controller: otpController,
//                       decoration: InputDecoration(
//                         border: InputBorder.none,
//                         hintText: 'OTP टाका',
//                         hintStyle: TextStyle(color: Colors.grey[600]),
//                         counterText: '',
//                       ),
//                       keyboardType: TextInputType.number,
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 40),
//                 if (isSubmitOtpButtonVisible)
//                   Center(
//                     child: ElevatedButton(
//                       // onPressed: isSubmittingOtpLoading ? null : submitOtp,
//                       onPressed: () {},
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color.fromARGB(255, 27, 107, 212),
//                         foregroundColor: Colors.black,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 40, vertical: 10),
//                       ),
//                       child: isSubmittingOtpLoading
//                           ? const CircularProgressIndicator(color: Colors.blue)
//                           : Text(
//                               "Submit OTP\nOTP सबमिट करा",
//                               style: const TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                               textAlign: TextAlign.center,
//                             ),
//                     ),
//                   ),
//               ],
//               if (isNextButtonVisible) ...[
//                 Container(
//                   padding: const EdgeInsets.all(16.0),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(10),
//                     border:
//                         Border.all(color: const Color(0xFF92B7F7), width: 2),
//                   ),
                
//                 ),
//                 const SizedBox(height: 20),
//                 Center(
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => PhotoClickKYCScreen(
//                             aadhaarNumber: widget.aadharNumber,
//                             ppoNumber: widget.ppoNumber,
//                             mobileNumber: widget.mobileNumber,
//                             addressEnter: widget.addressEnter,
//                             gender: widget.gender,
//                             fullName: widget.fullName,
//                           ),
//                         ),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: Color.fromARGB(255, 27, 107, 212),
//                       foregroundColor: Colors.black,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(30),
//                       ),
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 40, vertical: 10),
//                     ),
//                     child: const Text(
//                       'Next',
//                       style: TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.white,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                 ),
//               ],
//               const SizedBox(height: 20),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


