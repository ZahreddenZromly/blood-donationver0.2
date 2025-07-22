import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Splash extends StatefulWidget {
  const Splash({Key? key}) : super(key: key);

  @override
  State<Splash> createState() => _SplashState();
}
class _SplashState extends State<Splash> {


  @override
  void initState() {
    startTimer();
    super.initState();
  }
  startTimer(){
    var duration = Duration(seconds:2 , milliseconds: 500 );
    return Timer(duration, route);
  }
  route(){
    Navigator.of(context).pushNamed('/login');
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset("assets/splash.png"),
              SizedBox(
                height: 5,
              ),
              Text("تطبيق التبرع بالدم",
              style: TextStyle(fontSize: 30),
              )
            ],
          ),
        ),
      ),
    );
  }
}