import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/enter_ppo_number_screen.dart';
import 'package:nagpur_mahanagarpalika/Services/inAppUpdateService.dart';
import 'package:permission_handler/permission_handler.dart';

class StartingProjectScreen extends StatefulWidget {
  const StartingProjectScreen({super.key});

  @override
  State<StartingProjectScreen> createState() => _StartingProjectScreenState();
}

Future<void> _requestLocationPermission(BuildContext context) async {
  bool serviceEnabled;
  LocationPermission permission;
  // Check if location services are enabled
  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    // Show a dialog to enable location services
    _showEnableLocationDialog(context);
    return;
  }

  // Check permission status
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      _showPermissionDeniedDialog(context);
      return;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    _showPermissionDeniedDialog(context);
    return;
  }

  // If permission granted, proceed to AadharInputScreen
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => EnterMobileNumberScreen()),
  );
}

void _showEnableLocationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0), // Rounded corners
        ),
        title: const Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue, size: 28), // Icon
            SizedBox(width: 10),
            Text(
              'Enable Location', // Title text
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Divider(thickness: 2.5), // Top divider
            Text(
              'Location services are disabled. Please enable location to continue.\n'
              'स्थान सेवा अक्षम आहेत. कृपया स्थान सक्षम करा.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            Divider(thickness: 2.5), // Bottom divider
          ],
        ),
        actions: <Widget>[
          TextButton(
            child: const Text('Cancel', style: TextStyle(color: Colors.red)),
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue, // Button color
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            onPressed: () async {
              await Geolocator.openLocationSettings();
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Enable'),
          ),
        ],
      );
    },
  );
}

//

void _showInfoPopup(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.only(top: 233.0), // Add 40px top padding
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Stack(
              alignment: Alignment.topRight,
              children: [
                Image.asset(
                  // 'assets/images/policy_image.jpeg',
                  'assets/icon/policy_image.png',
                  fit: BoxFit.contain,
                ),
                Padding(
                  padding: const EdgeInsets.all(05.0),
                  child: IconButton(
                    icon:
                        const Icon(Icons.cancel, size: 40, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

void _showPermissionDeniedDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Location Permission Denied"),
        content: const Text(
            "You have denied location access. Please allow it from app settings."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              await openAppSettings();
              Navigator.pop(context);
            },
            child: const Text("Open Settings"),
          ),
        ],
      );
    },
  );
}

class _StartingProjectScreenState extends State<StartingProjectScreen> {
  final InAppUpdateService _updateService = InAppUpdateService();
  bool _isCheckingUpdate = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleInitialUpdateCheck();
    });
    // checkForUpdate();

    Future.wait([
      // checkForUpdate(),
      Future.delayed(const Duration(seconds: 2)),
    ]).then((_) {
      if (mounted) {
        _showInfoPopup(context);
      }
    });
  }

  Future<void> _handleInitialUpdateCheck() async {
    if (!mounted) return;

    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      // Use the enhanced update handling
      await _updateService.handleAppUpdate(context);
    } catch (e) {
      debugPrint('Error during initial update check: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  Future<void> _manualUpdateCheck() async {
    if (_isCheckingUpdate) return;

    setState(() {
      _isCheckingUpdate = true;
    });

    try {
      await _updateService.manualUpdateCheck(context);
    } catch (e) {
      _showSnackBar('Error checking for updates: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingUpdate = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget build(BuildContext context) {
    if (kDebugMode) // Only show in debug mode
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () async {
                try {
                  final updateInfo = await _updateService.checkForUpdate();
                  if (updateInfo != null) {
                    print('Update Available: ${updateInfo.updateAvailability}');
                    print('Install Status: ${updateInfo.installStatus}');
                    print(
                        'Available Version Code: ${updateInfo.availableVersionCode}');
                  } else {
                    print('No update info or checked recently');
                  }
                } catch (e) {
                  print('Error: $e');
                }
              },
              child: Text('Test Check Update'),
            ),
            ElevatedButton(
              onPressed: () async {
                await _updateService.handleAppUpdate(context,
                    showNoUpdateMessage: true);
              },
              child: Text('Test Handle Update'),
            ),
          ],
        ),
      );
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Top section (40% of screen)
            Expanded(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _isCheckingUpdate ? null : _manualUpdateCheck,
                    icon: _isCheckingUpdate
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(
                                Icons.refresh,
                                color: Colors.blue,
                              ),
                            ],
                          ),
                    tooltip: 'Check for updates',
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  Image.asset(
                    'assets/icon/Nagpur_Municipal_Corporation_logo.png',
                    height: 150,
                    width: 200,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'नागपूर महानगरपालिका',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Text(
                    "नागपूर- 440002",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Text(
                    "निवृत्ती वेतनधारक हयातीचे प्रमाणपत्र",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const Text(
                    "(2026-2027)",
                    style:
                        TextStyle(fontWeight: FontWeight.normal, fontSize: 18),
                  ),
                ],
              ),
            ),
            if (_isCheckingUpdate) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Checking for updates...',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 10),
            ],
            Expanded(
              flex: 6,
              child: ClipPath(
                clipper: BottomWaveClipper(),
                child: Container(
                  color: const Color(0xFF007BFF),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10), // Reduced vertical padding
                      child: Container(
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007BFF),
                          borderRadius: BorderRadius.circular(10),
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
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(height: 20), // Reduced height
                            Flexible(
                              // Added Flexible for text
                              child: Text(
                                'Generate Life Certificate\n(जीवन प्रमाणपत्र तैयार करा)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20, // Reduced font size
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10), // Reduced height
                            ElevatedButton(
                              onPressed: () =>
                                  _requestLocationPermission(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 40, vertical: 10),
                              ),
                              child: const Text(
                                'Click Here\nयेथे क्लिक करा',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.black),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 10), // Reduced height
                            Flexible(
                              // Added Flexible for long text
                              child: const Text(
                                "नोट : कृपया वेतनधारक व्यक्तींनी हयातीचा दाखला \nकाढण्याच्या अगोदर त्यांचा आधार मोबाईल \nनंबर सोबत लिंक करावा हि विनंती.",
                                style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white), // Reduced font size
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 20), // Reduced height
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 15),
                                    child: Text(
                                      'Powered by:',
                                      style: TextStyle(
                                          fontSize: 16,
                                          color: Colors
                                              .white), // Reduced font size
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Image.asset(
                                  'assets/icon/Bank_of_Maharashtra_logo.png',
                                  height: 40, // Reduced height
                                ),
                              ],
                            ),

                            Container(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                'Tap refresh icon to check for updates',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BottomWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Move to starting point on the left edge, higher up
    path.lineTo(0, size.height * 0.1); // increased from 0.3

    // Create a deeper wave
    path.cubicTo(
      size.width * 0.25,
      size.height * 0.3, // increased from 0.15
      size.width * 0.75,
      size.height * 0.05, // increased from 0.45
      size.width,
      size.height * 0.1, // increased from 0.3
    );

    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
