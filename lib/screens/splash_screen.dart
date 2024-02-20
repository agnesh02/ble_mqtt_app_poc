import 'package:ble_mqtt_app/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Adding delay here for splash screen
    Future.delayed(
      const Duration(seconds: 2),
      () {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (cntxt) => const HomeScreen(),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual,
        overlays: SystemUiOverlay.values);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 177, 140, 247),
              Color.fromARGB(255, 11, 128, 182),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 30),
                    child: Image.asset(
                      'assets/images/logo-2.png',
                      width: 200,
                    ),
                  ),
                  const Positioned(
                    left: 240,
                    top: 50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Multi",
                          style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w400),
                        ),
                        Text(
                          "Comms",
                          style: TextStyle(
                              fontSize: 27,
                              color: Colors.white,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const Spacer(),
            const Align(
              alignment: Alignment.center,
              child: Padding(
                padding: EdgeInsets.only(bottom: 10),
                child: Text(
                  "Developed by @agnesh",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w300,
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
