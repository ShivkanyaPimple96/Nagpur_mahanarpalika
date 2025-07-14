import 'package:flutter/material.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/aadhar_verification_screen.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/view_certificate_screen.dart';

class ViewButtonPensionerDetailesScreen extends StatefulWidget {
  final String ppoNumber;
  final String mobileNumber;
  final String fullName;
  final String verificationStatus;
  final String url;
  final String aadhaarNumber;
  final String addresss;
  final String gender;
  final String bankName;

  const ViewButtonPensionerDetailesScreen({
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
  State<ViewButtonPensionerDetailesScreen> createState() =>
      _ViewButtonPensionerDetailesScreenState();
}

class _ViewButtonPensionerDetailesScreenState
    extends State<ViewButtonPensionerDetailesScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _aadharController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _genderController = TextEditingController();

  @override
  void dispose() {
    _aadharController.dispose();
    _addressController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _validateAndProceed() {
    bool isValid = true;
    String? errorMessage;

    // Validate Aadhar
    if (_aadharController.text.isEmpty) {
      errorMessage = 'Please enter Aadhar number';
      isValid = false;
    } else if (_aadharController.text.length != 12) {
      errorMessage = 'Aadhar must be exactly 12 digits';
      isValid = false;
    }
    // Validate Address
    else if (_addressController.text.isEmpty) {
      errorMessage = 'Please enter your address';
      isValid = false;
    }
    // Validate Gender
    else if (_genderController.text.isEmpty) {
      errorMessage = 'Please enter your gender';
      isValid = false;
    }

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage!),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // If all validations pass, proceed
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AadharVerificationKYCScreen(
          ppoNumber: widget.ppoNumber,
          fullName: widget.fullName,
          mobileNumber: widget.mobileNumber,
          aadharNumber: _aadharController.text,
          addressEnter: _addressController.text,
          gender: _genderController.text,
        ),
      ),
    );
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
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: const Color(0xFF92B7F7), width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildInfoCard('PPO Number', widget.ppoNumber),
                        const SizedBox(height: 15),
                        _buildInfoCard('Full Name', widget.fullName),
                        const SizedBox(height: 15),
                        _buildInfoCard('Mobile Number', widget.mobileNumber),
                        const SizedBox(height: 25),
                        _buildInfoCard('Date of Birth', '01/01/1950'),
                        const SizedBox(height: 20),
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
                            errorText: _aadharController.text.isNotEmpty &&
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

                        DropdownButtonFormField<String>(
                          value: _genderController.text.isNotEmpty
                              ? _genderController.text
                              : null,
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
                            // hint: const Text('Select Gender'),
                            labelText: ' Select Gender',
                          ),
                          items: ['Male', 'Female'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _genderController.text = newValue ?? '';
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select gender';
                            }
                            return null;
                          },
                        ),
                        // TextFormField(
                        //   controller: _genderController,
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
                        // ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 25),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: const Color(0xFF92B7F7), width: 2),
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
                                onPressed: _validateAndProceed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 27, 107, 212),
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
                                onPressed: _validateAndProceed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 27, 107, 212),
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
                                onPressed: null, // Disabled button
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueGrey,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 40, vertical: 10),
                                ),
                                child: const Text(
                                  'Verification in Process\nसत्यापन प्रक्रियेत आहे',
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
