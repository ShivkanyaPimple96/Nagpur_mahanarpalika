import 'package:flutter/material.dart';
import 'package:nagpur_mahanagarpalika/KYC_Screens/starting_Project_Screen.dart';

class ResponseScreen extends StatelessWidget {
  final String message;
  final bool success;

  const ResponseScreen(
      {super.key, required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white, // Dim background like a dialog effect
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85, // Dialog width
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20.0), // Rounded corners
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF92B7F7),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      success
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: success ? Colors.green : Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      success ? 'Success' : 'Error',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 2.5),
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                const Divider(thickness: 2.5),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => StartingProjectScreen()),
                          (Route<dynamic> route) => false,
                        );

                        // Navigator.pushReplacement(
                        //   context,
                        //   MaterialPageRoute(builder: (context) => SplashScreen()),
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: success ? Colors.green : Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text("OK"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
