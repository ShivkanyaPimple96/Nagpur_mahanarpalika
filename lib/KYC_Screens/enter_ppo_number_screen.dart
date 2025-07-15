import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/pensioner_detailes_screen.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/search_ppo_no_screen.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/view_button_pensioner_detailes_screen.dart';

class EnterMobileNumberScreen extends StatefulWidget {
  const EnterMobileNumberScreen({super.key});

  @override
  _EnterMobileNumberScreenState createState() =>
      _EnterMobileNumberScreenState();
}

class _EnterMobileNumberScreenState extends State<EnterMobileNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _mobileController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _ppoController = TextEditingController();

  final List<TextEditingController> _digitControllers =
      List.generate(5, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(5, (_) => FocusNode());

  bool _isMobileSubmitted = false;
  bool _isPpoSubmitted = false;
  bool _isLoadingPPO = false;
  bool _apiError = false;
  String _apiErrorMessage = '';
  String _fullName = '';
  bool _isLoadingOTP = false;
  bool _otpApiError = false;
  String _otpApiErrorMessage = '';
  bool _isVerifyingOTP = false;
  bool _otpVerificationError = false;
  String _otpVerificationErrorMessage = '';

  String _apiMobileNumber = '';

  Future<void> _verifyOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isVerifyingOTP = true;
        _otpVerificationError = false;
        _otpVerificationErrorMessage = '';
      });

      try {
        final apiUrl =
            'https://nagpurpensioner.altwise.in/api/aadhar/SubmitOtpUsingPPONo?PPONumber=${_ppoController.text}&MobileNo=${_mobileController.text}&Otp=${_otpController.text}';
        print('Calling OTP Verification API: $apiUrl');

        final response = await CustomHttpClient.get(apiUrl);
        print(
            'OTP Verification API Response Status Code: ${response.statusCode}');
        print('OTP Verification API Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Parsed OTP Verification Data: $data');

          if ((data['Message']
                      ?.toString()
                      .toLowerCase()
                      .contains('success') ??
                  false) ||
              (data['message']?.toString().toLowerCase().contains('success') ??
                  false) ||
              (data['Success'] == true)) {
            print('OTP verified successfully!');

            // Extract all the data from the response
            final responseData = data['Data'];
            final verificationStatusNote =
                responseData['VerificationStatusNote'] ?? '';

            // Check if application is approved
            if (verificationStatusNote
                .toLowerCase()
                .contains('application approved')) {
              // Navigate to approved screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewButtonPensionerDetailesScreen(
                    ppoNumber: _ppoController.text,
                    mobileNumber: _mobileController.text,
                    fullName: responseData['FullName'] ?? '',
                    url: responseData['Url'] ?? '',
                    aadhaarNumber: responseData['AadhaarNumber'] ?? '',
                    addresss: responseData['Addresss'] ?? '',
                    gender: responseData['Gender'] ?? '',
                    bankName: responseData['BankName'] ?? '',
                    verificationStatus:
                        responseData['VerificationStatus'] ?? '',
                  ),
                ),
              );
            } else {
              // Navigate to regular details screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PensionerDetailesScreen(
                    ppoNumber: _ppoController.text,
                    mobileNumber: _mobileController.text,
                    fullName: responseData['FullName'] ?? '',
                    url: responseData['Url'] ?? '',
                    aadhaarNumber: responseData['AadhaarNumber'] ?? '',
                    addresss: responseData['Addresss'] ?? '',
                    gender: responseData['Gender'] ?? '',
                    verificationStatus:
                        responseData['VerificationStatus'] ?? '', 
                    bankName: responseData['BankName'] ?? '',
                  ),
                ),
              );
            }
          } else {
            print('OTP verification failed');
            final errorMessage =
                data['Message'] ?? data['message'] ?? 'Invalid OTP';
            showErrorDialog(errorMessage);
            setState(() {
              _otpVerificationError = true;
              _otpVerificationErrorMessage = errorMessage;
            });
          }
        } else {
          print('OTP Verification API returned non-200 status code');
          final errorMessage =
              'Please Enter Correct OTP\nकृपया योग्य OTP एंटर करा';
          showErrorDialog(errorMessage);
          setState(() {
            _otpVerificationError = true;
            _otpVerificationErrorMessage = errorMessage;
          });
        }
      } catch (e) {
        print('Error in OTP verification API call: $e');
        final errorMessage =
            'Network error: Please Check Your Internet Connection';
        showErrorDialog(errorMessage);
        setState(() {
          _otpVerificationError = true;
          _otpVerificationErrorMessage = errorMessage;
        });
      } finally {
        setState(() {
          _isVerifyingOTP = false;
        });
      }
    }
  }

  Future<void> _sendOtpRequest() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoadingOTP = true;
        _otpApiError = false;
        _otpApiErrorMessage = '';
      });

      try {
        final apiUrl =
            'https://nagpurpensioner.altwise.in/api/aadhar/GetOtpUsingMobileNo?PPONumber=${_ppoController.text}&MobileNo=${_mobileController.text}';
        print('Calling API: $apiUrl');

        final response = await CustomHttpClient.get(apiUrl);
        print('API Response Status Code: ${response.statusCode}');
        print('API Response Body: ${response.body}');

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          print('Parsed API Data: $data');

          // Check if the message indicates success regardless of the 'success' flag
          if ((data['Message']?.toString().toLowerCase().contains('success') ??
                  false) ||
              (data['message']?.toString().toLowerCase().contains('success') ??
                  false)) {
            print('OTP sent successfully!');
            setState(() {
              _isMobileSubmitted = true;
            });
          } else {
            print('API did not return success message');
            final errorMessage =
                data['Message'] ?? data['message'] ?? 'Failed to send OTP';
            showErrorDialog(errorMessage);
            setState(() {
              _otpApiError = true;
              _otpApiErrorMessage = errorMessage;
              _isMobileSubmitted = false;
            });
          }
        } else {
          print('API returned non-200 status code');
          final errorMessage =
              'Please Enter Correct OTP: ${response.statusCode}';
          showErrorDialog(errorMessage);
          setState(() {
            _otpApiError = true;
            _otpApiErrorMessage = errorMessage;
            _isMobileSubmitted = false;
          });
        }
      } catch (e) {
        print('Error in OTP API call: $e');
        final errorMessage =
            'Network error: Please Check Your Internet Connection\nकृपया तुमचे इंटरनेट नेटवर्क तपासा.';
        showErrorDialog(errorMessage);
        setState(() {
          _otpApiError = true;
          _otpApiErrorMessage = errorMessage;
          _isMobileSubmitted = false;
        });
      } finally {
        setState(() {
          _isLoadingOTP = false;
        });
      }
    }
  }

  // Future<void> _fetchPensionerDetails(String ppoNumber,
  //     {bool showErrors = true}) async {
  //   setState(() {
  //     _isLoadingPPO = true;
  //     _apiError = false;
  //     _apiErrorMessage = '';
  //   });

  //   try {
  //     final response = await CustomHttpClient.get(
  //       'https://nagpurpensioner.altwise.in/api/aadhar/GetDetailsUsingPPONo?PPONumber=$ppoNumber',
  //     );

  //     print('Response status: ${response.statusCode}');
  //     print('Response body: ${response.body}');

  //     if (response.statusCode == 200) {
  //       final data = json.decode(response.body);
  //       if (data['success'] == true) {
  //         setState(() {
  //           _fullName = data['data']['FullName'];
  //           _isPpoSubmitted = true;
  //         });
  //       } else if (showErrors) {
  //         // Only show error if flag is true
  //         final errorMessage = data['message'] ?? 'Failed to fetch details';
  //         showErrorDialog(errorMessage);
  //       }
  //     } else if (showErrors) {
  //       // Only show error if flag is true
  //       showErrorDialog('PPO Number Not Found\nपीपीओ नंबर सापडला नाही');
  //     }
  //   } catch (e) {
  //     if (showErrors) {
  //       // Only show error if flag is true
  //       showErrorDialog(
  //           'Network error: Please Check Your Internet Network\nकृपया तुमचे इंटरनेट नेटवर्क तपासा.');
  //     }
  //   } finally {
  //     setState(() {
  //       _isLoadingPPO = false;
  //     });
  //   }
  // }

  Future<void> _fetchPensionerDetails(String ppoNumber,
      {bool showErrors = true}) async {
    setState(() {
      _isLoadingPPO = true;
      _apiError = false;
      _apiErrorMessage = '';
      _apiMobileNumber = ''; // Reset mobile number
    });

    try {
      final response = await CustomHttpClient.get(
        'https://nagpurpensioner.altwise.in/api/aadhar/GetDetailsUsingPPONo?PPONumber=$ppoNumber',
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          setState(() {
            _fullName = data['data']['FullName'] ?? '';
            _apiMobileNumber = data['data']['MobileNumber'] ?? '';
            _isPpoSubmitted = true;

            // If mobile number is available from API, set it in the controller
            if (_apiMobileNumber.isNotEmpty) {
              _mobileController.text = _apiMobileNumber;
            }
          });

          // If mobile number is available, automatically proceed to OTP
          // if (_apiMobileNumber.isNotEmpty) {
          //   _sendOtpRequest();
          // }
        } else if (showErrors) {
          final errorMessage = data['message'] ?? 'Failed to fetch details';
          showErrorDialog(errorMessage);
        }
      } else if (showErrors) {
        showErrorDialog('PPO Number Not Found\nपीपीओ नंबर सापडला नाही');
      }
    } catch (e) {
      if (showErrors) {
        showErrorDialog(
            'Network error: Please Check Your Internet Network\nकृपया तुमचे इंटरनेट नेटवर्क तपासा.');
      }
    } finally {
      setState(() {
        _isLoadingPPO = false;
      });
    }
  }

  Future<void> showErrorDialog(String message) async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Enter PPO Number  [Step-1]',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 27, 107, 212),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Row(
              //   mainAxisAlignment: MainAxisAlignment.end,
              //   children: [
              //     ElevatedButton(
              //       onPressed: () {
              //         Navigator.push(
              //           context,
              //           MaterialPageRoute(
              //               builder: (context) => SearchPPONumberScreen()),
              //           // OR using named routes:
              //           // Navigator.pushNamed(context, '/search-ppo');
              //         );
              //       },
              //       style: ElevatedButton.styleFrom(
              //         backgroundColor: Color.fromARGB(255, 235, 149, 38),
              //         foregroundColor: Colors.black,
              //         shape: RoundedRectangleBorder(
              //           borderRadius: BorderRadius.circular(5),
              //         ),
              //       ),
              //       child: const Text(
              //         'Know your PPO Number\nतुमचा पीपीओ नंबर जाणून घ्या',
              //         style: TextStyle(fontSize: 15, color: Colors.white),
              //         textAlign: TextAlign.center,
              //       ),
              //     ),
              //   ],
              // ),
              const SizedBox(height: 10),
              const Text(
                'Enter your PPO number\nPPO नंबर टाका',
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Center(
                child: Container(
                  height: 70,
                  width: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: const Color(0xFF92B7F7), width: 2),
                  ),
                  child: TextFormField(
                    style: TextStyle(fontSize: 24),
                    keyboardType: TextInputType.number,
                    controller: _ppoController,
                    enabled: !_isPpoSubmitted,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter PPO number',
                      hintStyle: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(5),
                    ],
                    validator: (value) {
                      if (!_isPpoSubmitted) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter PPO number';
                        }
                        if (!RegExp(r'^\d{1,5}$').hasMatch(value)) {
                          return 'PPO number must be 1 to 5 digits';
                        }
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Visibility(
                visible: !_isPpoSubmitted,
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _fetchPensionerDetails(_ppoController.text);
                    }
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
                    'Submit PPO Number\nPPO क्रमांक सबमिट करा',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Visibility(
                  visible: !_isPpoSubmitted,
                  child: ElevatedButton(
                    // onPressed: () {
                    //   _fetchPensionerDetails(_ppoController.text);
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //         builder: (context) => SearchPPONumberScreen()),
                    //   );
                    // },
                    onPressed: () {
                      _fetchPensionerDetails(_ppoController.text,
                          showErrors: false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => SearchPPONumberScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color.fromARGB(255, 235, 149, 38),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                      ),
                      padding: EdgeInsets.symmetric(
                          horizontal: 10, vertical: 0), // Inner padding
                    ),
                    child: const Text(
                      'Know your PPO Number\nतुमचा पीपीओ नंबर जाणून घ्या',
                      style: TextStyle(fontSize: 18, color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              if (_isLoadingPPO) ...[
                const SizedBox(height: 30),
                const Center(child: CircularProgressIndicator()),
              ],
              if (_isPpoSubmitted && _fullName.isNotEmpty) ...[
                Center(
                  child: Text(
                    'निवृत्ती वेतनधारका चे नाव:\n$_fullName',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Text(
                      'Enter your mobile number\n मोबाईल नंबर टाका',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    height: 60,
                    width: 250,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFF92B7F7), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextFormField(
                        controller: _mobileController,
                        enabled: !_isMobileSubmitted &&
                            _apiMobileNumber
                                .isEmpty, // Only enable if no mobile from API
                        keyboardType: TextInputType.phone,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontSize: 25,
                          color: Colors.black,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter mobile number',
                          hintStyle: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 18,
                          ),
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        validator: (value) {
                          if (!_isMobileSubmitted) {
                            if (_apiMobileNumber.isEmpty &&
                                (value == null || value.isEmpty)) {
                              return '  Please enter mobile number';
                            }
                            if (_apiMobileNumber.isEmpty &&
                                !RegExp(r'^[0-9]{10}$').hasMatch(value!)) {
                              return '  Please Enter 10 digit mobile number';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  // child: Container(
                  //   height: 60,
                  //   width: 250,
                  //   decoration: BoxDecoration(
                  //     color: Colors.white,
                  //     borderRadius: BorderRadius.circular(10),
                  //     border:
                  //         Border.all(color: const Color(0xFF92B7F7), width: 2),
                  //   ),
                  //   child: Padding(
                  //     padding: const EdgeInsets.only(top: 10),
                  //     child: TextFormField(
                  //       controller: _mobileController,
                  //       enabled: !_isMobileSubmitted,
                  //       keyboardType: TextInputType.phone,
                  //       textAlign: TextAlign.center,
                  //       textAlignVertical: TextAlignVertical.center,
                  //       style: const TextStyle(
                  //         fontSize: 25,
                  //         color: Colors.black,
                  //       ),
                  //       inputFormatters: [
                  //         FilteringTextInputFormatter.digitsOnly,
                  //         LengthLimitingTextInputFormatter(10),
                  //       ],
                  //       decoration: InputDecoration(
                  //         border: InputBorder.none,
                  //         hintText: 'Enter mobile number',
                  //         hintStyle: TextStyle(
                  //           color: Colors.grey[600],
                  //           fontSize: 18,
                  //         ),
                  //         contentPadding: EdgeInsets.zero,
                  //         isDense: true,
                  //       ),
                  //       validator: (value) {
                  //         if (!_isMobileSubmitted) {
                  //           if (value == null || value.isEmpty) {
                  //             return '  Please enter mobile number';
                  //           }
                  //           if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                  //             return '  Please Enter 10 digit mobile number';
                  //           }
                  //         }
                  //         return null;
                  //       },
                  //     ),
                  //   ),
                  // ),
                ),
                const SizedBox(height: 30),
                Visibility(
                  visible: !_isMobileSubmitted,
                  child: Column(
                    children: [
                      if (_otpApiError)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            _otpApiErrorMessage,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      if (_isLoadingOTP)
                        const Center(child: CircularProgressIndicator())
                      else
                        ElevatedButton(
                          onPressed: _sendOtpRequest,
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
                            "Submit Mobile Number\nमोबाईल नंबर सबमिट करा",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (_isMobileSubmitted) ...[
                const SizedBox(height: 30),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Center(
                    child: Text(
                      'Enter OTP\n OTP टाका',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border:
                          Border.all(color: const Color(0xFF92B7F7), width: 2),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        textAlignVertical: TextAlignVertical.center,
                        style: const TextStyle(
                          fontSize: 25,
                          color: Colors.black,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(4),
                        ],
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Enter OTP',
                          hintStyle:
                              TextStyle(color: Colors.grey[600], fontSize: 18),
                        ),
                        validator: (value) {
                          if (_isMobileSubmitted) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter OTP';
                            }
                            if (value.length != 4) {
                              return 'OTP must be 4 digits';
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Center(
                  child: _isVerifyingOTP
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 27, 107, 212),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 10),
                          ),
                          child: const Text(
                            "Submit OTP\nOTP सबमिट करा",
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mobileController.dispose();
    _otpController.dispose();
    _ppoController.dispose();
    for (var controller in _digitControllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }
}

class CustomHttpClient {
  static Future<http.Client> get _instance async {
    final ioClient = HttpClient()
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
    return IOClient(ioClient);
  }

  static Future<http.Response> get(String url) async {
    final client = await _instance;
    return client.get(Uri.parse(url));
  }
}

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:nagpur_mahanagarpalika/KYC_Screens/pensioner_detailes_screen.dart';

// class EnterMobileNumberScreen extends StatefulWidget {
//   const EnterMobileNumberScreen({super.key});

//   @override
//   _EnterMobileNumberScreenState createState() =>
//       _EnterMobileNumberScreenState();
// }

// class _EnterMobileNumberScreenState extends State<EnterMobileNumberScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _mobileController = TextEditingController();
//   final TextEditingController _otpController = TextEditingController();
//   final TextEditingController _pppController = TextEditingController();

//   bool _isMobileSubmitted = false;
//   bool _isPpoSubmitted = false;
//   final bool _isLoadingPPO = false;

//   final String _fullName = 'Shivani Rajendra Pimple';

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Scaffold(
//         appBar: AppBar(
//           centerTitle: true, // This centers the title
//           title: Text(
//             'Enter PPO Number  [Step-1]',
//             style: TextStyle(
//               color: Colors.white,
//               fontSize: 20,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           backgroundColor: const Color.fromARGB(255, 27, 107, 212),
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(16.0),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 const SizedBox(height: 10),
//                 const Text(
//                   'Enter your PPO number\nPPO नंबर टाका',
//                   style: TextStyle(
//                     fontSize: 22,
//                     color: Colors.black,
//                   ),
//                   textAlign: TextAlign.center,
//                 ),
//                 const SizedBox(height: 10),
//                 Center(
//                   child: Container(
//                     height: 60,
//                     width: 150,
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(10),
//                       border:
//                           Border.all(color: const Color(0xFF92B7F7), width: 2),
//                     ),
//                     child: Padding(
//                       padding: const EdgeInsets.only(top: 10),
//                       child: TextFormField(
//                         controller: _pppController,
//                         enabled: !_isPpoSubmitted,
//                         keyboardType: TextInputType.phone,
//                         textAlign: TextAlign.center,
//                         textAlignVertical: TextAlignVertical.center,
//                         style: TextStyle(
//                           fontSize: 25,
//                           color: Colors.black,
//                         ),
//                         inputFormatters: [
//                           FilteringTextInputFormatter.digitsOnly,
//                           LengthLimitingTextInputFormatter(
//                               5), // Allow < 5 digits only
//                         ],
//                         decoration: InputDecoration(
//                           border: InputBorder.none,
//                           hintStyle: TextStyle(
//                             color: Colors.grey[600],
//                             fontSize: 18,
//                           ),
//                           contentPadding: EdgeInsets.zero,
//                           isDense: true,
//                         ),
//                         validator: (value) {
//                           if (!_isPpoSubmitted) {
//                             if (value == null || value.isEmpty) {
//                               return 'Please enter PPO number';
//                             }
//                           }
//                           return null;
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(height: 30),
//                 Visibility(
//                   visible: !_isPpoSubmitted,
//                   child: Center(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         if (_formKey.currentState!.validate()) {
//                           setState(() {
//                             _isPpoSubmitted = true;
//                           });
//                         }
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color.fromARGB(255, 27, 107, 212),
//                         foregroundColor: Colors.black,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 40, vertical: 10),
//                       ),
//                       child: const Text(
//                         'Submit PPO Number\nPPO क्रमांक सबमिट करा',
//                         style: TextStyle(fontSize: 16, color: Colors.white),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//                 if (_isLoadingPPO) ...[
//                   const SizedBox(height: 30),
//                   const Center(child: CircularProgressIndicator()),
//                 ],
//                 if (_isPpoSubmitted) ...[
//                   Center(
//                     child: Text(
//                       'निवृत्ती वेतनधारका चे नाव:\n$_fullName',
//                       style: const TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   const Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 8.0),
//                     child: Center(
//                       child: Text(
//                         'Enter your mobile number\n मोबाईल नंबर टाका',
//                         style: TextStyle(
//                           fontSize: 22,
//                           // fontWeight: FontWeight.bold,
//                           color: Colors.black,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Center(
//                     child: Container(
//                       height: 60,
//                       width: 250,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(
//                             color: const Color(0xFF92B7F7), width: 2),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.only(top: 10),
//                         child: TextFormField(
//                           controller: _mobileController,
//                           enabled: !_isMobileSubmitted,
//                           keyboardType: TextInputType.phone,
//                           textAlign: TextAlign.center,
//                           textAlignVertical: TextAlignVertical.center,
//                           style: const TextStyle(
//                             fontSize: 25,
//                             color: Colors.black,
//                           ),
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly,
//                             LengthLimitingTextInputFormatter(10),
//                           ],
//                           decoration: InputDecoration(
//                             border: InputBorder.none,
//                             hintText: 'Enter mobile number',
//                             hintStyle: TextStyle(
//                               color: Colors.grey[600],
//                               fontSize: 18,
//                             ),
//                             contentPadding: EdgeInsets.zero,
//                             isDense: true,
//                           ),
//                           validator: (value) {
//                             if (!_isMobileSubmitted) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please enter mobile number';
//                               }
//                               if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
//                                 return 'Invalid mobile number';
//                               }
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   Visibility(
//                     visible: !_isMobileSubmitted,
//                     child: Center(
//                       child: ElevatedButton(
//                         onPressed: () {
//                           if (_formKey.currentState!.validate()) {
//                             setState(() {
//                               _isMobileSubmitted = true;
//                             });
//                           }
//                         },
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: Color.fromARGB(255, 27, 107, 212),
//                           foregroundColor: Colors.black,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(30),
//                           ),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 40, vertical: 10),
//                         ),
//                         child: const Text(
//                           "Submit Mobile Number\nमोबाईल नंबर सबमिट करा",
//                           style: TextStyle(
//                             fontSize: 18,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.white,
//                           ),
//                           textAlign: TextAlign.center,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//                 if (_isMobileSubmitted) ...[
//                   const SizedBox(height: 30),
//                   const Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 8.0),
//                     child: Center(
//                       child: Text(
//                         'Enter OTP\n OTP टाका',
//                         style: TextStyle(
//                           fontSize: 22,
//                           color: Colors.black,
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   Center(
//                     child: Container(
//                       width: 200,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(
//                             color: const Color(0xFF92B7F7), width: 2),
//                       ),
//                       child: Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 12),
//                         child: TextFormField(
//                           controller: _otpController,
//                           keyboardType: TextInputType.number,
//                           textAlign: TextAlign.center,
//                           textAlignVertical: TextAlignVertical.center,
//                           style: const TextStyle(
//                             fontSize: 25,
//                             color: Colors.black,
//                           ),
//                           inputFormatters: [
//                             FilteringTextInputFormatter.digitsOnly,
//                             LengthLimitingTextInputFormatter(4),
//                           ],
//                           decoration: InputDecoration(
//                             border: InputBorder.none,
//                             hintText: 'Enter OTP',
//                             hintStyle: TextStyle(
//                                 color: Colors.grey[600], fontSize: 18),
//                           ),
//                           validator: (value) {
//                             if (_isMobileSubmitted) {
//                               if (value == null || value.isEmpty) {
//                                 return 'Please enter OTP';
//                               }
//                               if (value.length != 4) {
//                                 return 'OTP must be 4 digits';
//                               }
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   Center(
//                     child: ElevatedButton(
//                       onPressed: () {
//                         if (_formKey.currentState!.validate()) {
//                           // Collect PPO number from the digitControllers

//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => PensionerDetailesScreen(
//                                 ppoNumber: _pppController.text,
//                                 mobileNumber: _mobileController.text,
//                                 fullName: _fullName,
//                               ),
//                             ),
//                           );
//                         }
//                       },

//                       // onPressed: () {
//                       //   if (_formKey.currentState!.validate()) {
//                       //     // Navigate to next screen
//                       //   }
//                       // },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color.fromARGB(255, 27, 107, 212),
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         padding: const EdgeInsets.symmetric(
//                             horizontal: 40, vertical: 10),
//                       ),
//                       child: const Text(
//                         "Submit OTP\nOTP सबमिट करा",
//                         style: TextStyle(
//                           fontSize: 18,
//                           fontWeight: FontWeight.bold,
//                           color: Colors.white,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ),
//                   ),
//                 ],
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     _mobileController.dispose();
//     _otpController.dispose();

//     super.dispose();
//   }
// }
