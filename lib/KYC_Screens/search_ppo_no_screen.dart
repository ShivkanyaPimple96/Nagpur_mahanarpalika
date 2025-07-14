import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SearchPPONumberScreen extends StatefulWidget {
  const SearchPPONumberScreen({super.key});

  @override
  State<SearchPPONumberScreen> createState() => _SearchPPONumberScreenState();
}

class _SearchPPONumberScreenState extends State<SearchPPONumberScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();

  List<dynamic> _searchResults = [];
  bool _isLoading = false;
  bool _hasSearched = false;

  Future<void> _searchPensioners() async {
    if (_firstNameController.text.isEmpty && _lastNameController.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _searchResults = []; // Clear previous results
      });
      _showValidationErrorDialog(
          'Please enter at least first name or last name\nकृपया किमान नाव किंवा आडनाव प्रविष्ट करा.');
      return;
    }

    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _searchResults = []; // Clear previous results when starting new search
    });

    try {
      final Map<String, String> queryParams = {};
      if (_firstNameController.text.isNotEmpty) {
        queryParams['firstName'] = _firstNameController.text.trim();
      }
      if (_lastNameController.text.isNotEmpty) {
        queryParams['lastName'] = _lastNameController.text.trim();
      }

      final Uri uri = Uri.https(
        'nagpurpensioner.altwise.in',
        '/api/aadhar/GetUserDetailsByName',
        queryParams,
      );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['Data'] != null && responseData['Data'] is List) {
          setState(() {
            _searchResults = responseData['Data'];
          });
        } else {
          setState(() {
            _searchResults =
                []; // Ensure results are cleared when no data found
          });
          _showValidationErrorDialog('No pensioners found with that name');
        }
      } else {
        setState(() {
          _searchResults = []; // Ensure results are cleared when API fails
        });
        _showValidationErrorDialog('Note: No PPO Number Found');
      }
    } catch (e) {
      setState(() {
        _searchResults = []; // Ensure results are cleared on error
      });
      _showValidationErrorDialog('Failed to search: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showValidationErrorDialog(String message) async {
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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search PPO Number by Name',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF1B6BD4),
        centerTitle: true,
        elevation: 4,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSearchForm(),
            // const SizedBox(height: 20),
            Text(
              'Enter Your First And Last Number',
              style: TextStyle(fontSize: 18, color: Colors.black),
            ),
            const SizedBox(height: 20),
            if (_isLoading) const CircularProgressIndicator(),
            if (_hasSearched && !_isLoading) _buildSearchResults(),
            if (_hasSearched && _searchResults.isEmpty && !_isLoading)
              const Center(
                child: Text(
                  'No results found',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchForm() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: const BorderSide(color: Colors.blue, width: 1.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _firstNameController,
              decoration: const InputDecoration(
                labelText: 'First Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lastNameController,
              decoration: const InputDecoration(
                labelText: 'Last Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _searchPensioners,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Search PPO Number',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ),
            // Text(
            //   'Enter Your First And Last Number',
            //   style: TextStyle(fontSize: 18, color: Colors.white),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResults() {
    if (_searchResults.isEmpty) {
      return const SizedBox.shrink(); // Return an empty widget if no results
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final pensioner = _searchResults[index];
          return _buildPensionerCard(pensioner, index + 1);
        },
      ),
    );
  }

  Widget _buildPensionerCard(Map<String, dynamic> pensioner, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('PPO Number', pensioner['PPONumber']),
            _buildDetailRow(
              'Full Name',
              '${pensioner['FirstName']} ${pensioner['MiddleName'] ?? ''} ${pensioner['LastName']}'
                  .trim(),
            ),
            const Divider(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value?.toString() ?? 'Not available',
              softWrap: true,
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

// class SearchPPONumberScreen extends StatefulWidget {
//   const SearchPPONumberScreen({super.key});

//   @override
//   State<SearchPPONumberScreen> createState() => _SearchPPONumberScreenState();
// }

// class _SearchPPONumberScreenState extends State<SearchPPONumberScreen> {
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();

//   List<dynamic> _searchResults = [];
//   bool _isLoading = false;
//   bool _hasSearched = false;

//   Future<void> _searchPensioners() async {
//     if (_firstNameController.text.isEmpty && _lastNameController.text.isEmpty) {
//       setState(() {
//         _isLoading = false;
//       });
//       _showValidationErrorDialog(
//           'Please enter at least first name or last name\nकृपया किमान नाव किंवा आडनाव प्रविष्ट करा.');
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _hasSearched = true;
//     });

//     try {
//       final Map<String, String> queryParams = {};
//       if (_firstNameController.text.isNotEmpty) {
//         queryParams['firstName'] = _firstNameController.text.trim();
//       }
//       if (_lastNameController.text.isNotEmpty) {
//         queryParams['lastName'] = _lastNameController.text.trim();
//       }

//       final Uri uri = Uri.https(
//         'nagpurpensioner.altwise.in',
//         '/api/aadhar/GetUserDetailsByName',
//         queryParams,
//       );

//       final response = await http.get(uri);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         if (responseData['Data'] != null && responseData['Data'] is List) {
//           setState(() {
//             _searchResults = responseData['Data'];
//           });
//         } else {
//           _showValidationErrorDialog('No pensioners found with that name');
//         }
//       } else {
//         _showValidationErrorDialog('Note: No PPO Number Found');
//       }
//     } catch (e) {
//       _showValidationErrorDialog('Failed to search: ${e.toString()}');
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   Future<void> _showValidationErrorDialog(String message) async {
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

//   // void _showValidationErrorDialog(String message) {
//   //   showDialog(
//   //     context: context,
//   //     builder: (BuildContext context) {
//   //       return AlertDialog(
//   //         title: const Text('Error'),
//   //         content: Text(message),
//   //         actions: <Widget>[
//   //           TextButton(
//   //             child: const Text('OK'),
//   //             onPressed: () {
//   //               Navigator.of(context).pop();
//   //             },
//   //           ),
//   //         ],
//   //       );
//   //     },
//   //   );
//   // }

//   @override
//   void dispose() {
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Search PPO Number by Name',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: const Color(0xFF1B6BD4),
//         centerTitle: true,
//         elevation: 4,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             _buildSearchForm(),
//             const SizedBox(height: 20),
//             if (_isLoading) const CircularProgressIndicator(),
//             if (_hasSearched && !_isLoading) _buildSearchResults(),
//             if (_hasSearched && _searchResults.isEmpty && !_isLoading)
//               const Text('No results found'),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchForm() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16.0),
//         side: const BorderSide(color: Colors.blue, width: 1.0),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _firstNameController,
//               decoration: const InputDecoration(
//                 labelText: 'First Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _lastNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Last Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _searchPensioners,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[800],
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                 ),
//                 child: const Text(
//                   'Search PPO Number',
//                   style: TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchResults() {
//     if (_searchResults.isEmpty) {
//       return const SizedBox.shrink(); // Return an empty widget if no results
//     }

//     return Expanded(
//       child: ListView.builder(
//         itemCount: _searchResults.length,
//         itemBuilder: (context, index) {
//           final pensioner = _searchResults[index];
//           return _buildPensionerCard(pensioner, index + 1);
//         },
//       ),
//     );
//   }

//   Widget _buildPensionerCard(Map<String, dynamic> pensioner, int index) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             _buildDetailRow('PPO Number', pensioner['PPONumber']),
//             _buildDetailRow(
//               'Full Name',
//               '${pensioner['FirstName']} ${pensioner['MiddleName'] ?? ''} ${pensioner['LastName']}'
//                   .trim(),
//             ),
//             const Divider(height: 20),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, dynamic value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               '$label:',
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value?.toString() ?? 'Not available',
//               softWrap: true,
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

// class SearchPPONumberScreen extends StatefulWidget {
//   const SearchPPONumberScreen({super.key});

//   @override
//   State<SearchPPONumberScreen> createState() => _SearchPPONumberScreenState();
// }

// class _SearchPPONumberScreenState extends State<SearchPPONumberScreen> {
//   final TextEditingController _firstNameController = TextEditingController();
//   final TextEditingController _lastNameController = TextEditingController();

//   List<dynamic> _searchResults = [];
//   bool _isLoading = false;
//   String _errorMessage = '';
//   bool _hasSearched = false;

//   Future<void> _searchPensioners() async {
//     if (_firstNameController.text.isEmpty && _lastNameController.text.isEmpty) {
//       setState(() {
//         _errorMessage = 'Please enter at least first name or last name';
//       });
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//       _errorMessage = '';
//       _hasSearched = true;
//     });

//     try {
//       final Map<String, String> queryParams = {};
//       if (_firstNameController.text.isNotEmpty) {
//         queryParams['firstName'] = _firstNameController.text.trim();
//       }
//       if (_lastNameController.text.isNotEmpty) {
//         queryParams['lastName'] = _lastNameController.text.trim();
//       }

//       final Uri uri = Uri.https(
//         'nagpurpensioner.altwise.in',
//         '/api/aadhar/GetUserDetailsByName',
//         queryParams,
//       );

//       final response = await http.get(uri);

//       if (response.statusCode == 200) {
//         final Map<String, dynamic> responseData = json.decode(response.body);
//         if (responseData['Data'] != null && responseData['Data'] is List) {
//           setState(() {
//             _searchResults = responseData['Data'];
//           });
//         } else {
//           setState(() {
//             _errorMessage = 'No pensioners found with that name';
//           });
//         }
//       } else {
//         setState(() {
//           _errorMessage =
//               'Error: ${response.statusCode} - ${response.reasonPhrase}';
//         });
//       }
//     } catch (e) {
//       setState(() {
//         _errorMessage = 'Failed to search: ${e.toString()}';
//       });
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   @override
//   void dispose() {
//     _firstNameController.dispose();
//     _lastNameController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Search PPO Number by Name',
//           style: TextStyle(
//             color: Colors.white,
//             fontSize: 20,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         backgroundColor: const Color(0xFF1B6BD4),
//         centerTitle: true,
//         elevation: 4,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             _buildSearchForm(),
//             const SizedBox(height: 20),
//             if (_isLoading) const CircularProgressIndicator(),
//             // if (_errorMessage.isNotEmpty) _buildErrorMessage(),
//             if (_hasSearched && !_isLoading) _buildSearchResults(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildSearchForm() {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(16.0), // Circular border radius
//         side: BorderSide(color: Colors.blue, width: 1.0), // Blue border
//       ),
//       child: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: _firstNameController,
//               decoration: const InputDecoration(
//                 labelText: 'First Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 12),
//             TextField(
//               controller: _lastNameController,
//               decoration: const InputDecoration(
//                 labelText: 'Last Name',
//                 border: OutlineInputBorder(),
//               ),
//             ),
//             const SizedBox(height: 16),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: _searchPensioners,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue[800],
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                 ),
//                 child: const Text(
//                   'Search PPO Number',
//                   style: TextStyle(fontSize: 18, color: Colors.white),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

 

//   Widget _buildSearchResults() {
//     if (_searchResults.isEmpty) {
//       return const Text(
//         'No PPO Number found \nपीपीओ नंबर सापडला नाही.',
//         style: TextStyle(fontSize: 16),
//       );
//     }

//     return Expanded(
//       child: ListView.builder(
//         itemCount: _searchResults.length,
//         itemBuilder: (context, index) {
//           final pensioner = _searchResults[index];
//           return _buildPensionerCard(pensioner, index + 1);
//         },
//       ),
//     );
//   }

//   Widget _buildPensionerCard(Map<String, dynamic> pensioner, int index) {
//     return Card(
//       margin: const EdgeInsets.only(bottom: 12),
//       elevation: 2,
//       child: Padding(
//         padding: const EdgeInsets.all(12.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
        
//             // const Divider(height: 20),
//             _buildDetailRow('PPO Number', pensioner['PPONumber']),
//             _buildDetailRow(
//               'Full Name',
//               '${pensioner['FirstName']} ${pensioner['MiddleName'] ?? ''} ${pensioner['LastName']}'
//                   .trim(),
//             ),
//             const Divider(height: 20),
//             // _buildDetailRow('Mobile', pensioner['MobileNo']),
//             // _buildDetailRow('Address', pensioner['Address']),
//             // _buildDetailRow(
//             //     'Pension Type', _getPensionType(pensioner['PensionType'])),
//             // if (pensioner['NomineeName'] != null)
//             //   _buildDetailRow('Nominee', pensioner['NomineeName']),
//             // _buildDetailRow('Status Note', pensioner['VerificationStatusNote']),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildDetailRow(String label, dynamic value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 4),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           SizedBox(
//             width: 100,
//             child: Text(
//               '$label:',
//               style: const TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ),
//           Expanded(
//             child: Text(
//               value?.toString() ?? 'Not available',
//               softWrap: true,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

// }


