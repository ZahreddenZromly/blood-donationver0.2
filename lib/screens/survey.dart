import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class Survey extends StatefulWidget {
  const Survey({Key? key}) : super(key: key);

  @override
  State<Survey> createState() => _SurveyState();
}

class _SurveyState extends State<Survey> {
  String? selectedType; // A, B, O, AB
  String? selectedSign; // + or -

  void selectType(String type) {
    setState(() {
      selectedType = type;
    });
  }

  void selectSign(String sign) {
    setState(() {
      selectedSign = sign;
    });
  }


  void finishSurvey() async {
    if (selectedType != null && selectedSign != null) {
      String finalBloodType = selectedType! + selectedSign!;
      print('User selected: $finalBloodType');

      try {
        final user = FirebaseAuth.instance.currentUser;

        if (user != null) {
          // Save to 'survey' collection
          await FirebaseFirestore.instance.collection('survey').add({
            'user': user.email,
            'userId': user.uid,
            'bloodType': finalBloodType,
            'timestamp': FieldValue.serverTimestamp(),
          });

          // 💾 Update user's bloodType in 'users' collection
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
            'bloodType': finalBloodType,
          }, SetOptions(merge: true)); // Merge keeps existing data

          print("Survey + user bloodType saved successfully!");

          // Navigate to booking page
          Navigator.of(context).pushNamed('/booking');
        } else {
          print("No user logged in");
        }
      } catch (e) {
        print("Error saving survey: $e");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Something went wrong. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select both blood type and sign')),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: content(),
    );
  }

  Widget content() {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 30.0),
          child: Column(
            children: [
              const SizedBox(height: 30),
              Center(
                child: Icon(
                  Icons.bloodtype,
                  size: 180,
                  color: Colors.redAccent,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "الرجاء اختيار فصيلة الدم",
                style: TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 10),
              bloodTypeRow("A", "B"),
              const SizedBox(height: 15),
              bloodTypeRow("O", "AB"),
              const SizedBox(height: 15),
              signRow(),
              const SizedBox(height: 20),
              LoginButton("انهاء", finishSurvey),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/booking');
                },
                child: const Text(
                  "الطلب",
                  style: TextStyle(color: Colors.redAccent, fontSize: 15),
                ),
              )
            ],
          ),
        ),
        Positioned(
          top: 20,
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.arrow_back_outlined, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    );
  }

  Widget bloodTypeRow(String type1, String type2) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        bloodTypeBox(type1),
        const SizedBox(width: 20),
        bloodTypeBox(type2),
      ],
    );
  }

  Widget bloodTypeBox(String type) {
    bool isSelected = selectedType == type;
    return GestureDetector(
      onTap: () => selectType(type),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: isSelected ? Colors.redAccent : Colors.grey[350],
        ),
        width: 180,
        height: 100,
        child: Center(
          child: Text(
            type,
            style: TextStyle(
              fontSize: 20,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget signRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        signBox("+"),
        const SizedBox(width: 50),
        signBox("-"),
      ],
    );
  }

  Widget signBox(String sign) {
    bool isSelected = selectedSign == sign;
    return GestureDetector(
      onTap: () => selectSign(sign),
      child: Container(
        height: 50,
        width: 50,
        decoration: BoxDecoration(
          color: isSelected ? Colors.redAccent : Colors.grey[350],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            sign,
            style: TextStyle(
              fontSize: 25,
              color: isSelected ? Colors.white : Colors.black,
            ),
          ),
        ),
      ),
    );
  }
}

// Reusable LoginButton
Widget LoginButton(String title, VoidCallback onPressed) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Container(
      height: 60,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextButton(
        onPressed: onPressed,
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
