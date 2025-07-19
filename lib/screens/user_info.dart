import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';

class ProfileFormPage extends StatefulWidget {
  const ProfileFormPage({Key? key}) : super(key: key);

  @override
  State<ProfileFormPage> createState() => _ProfileFormPageState();
}

class _ProfileFormPageState extends State<ProfileFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nationalNumController = TextEditingController();

  String? _selectedBloodType;
  String? _selectedCity;

  final List<String> _bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-',
  ];

  final List<String> _city = [
    'Tripoli',
    'Benghazi',
    'Sabha',
    'Yefren',
    'khumes',
    'Alzawyah',
  ];

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'age': int.parse(_ageController.text.trim()),
        'bloodType': _selectedBloodType,
        'city': _selectedCity,
        'phone': _phoneController.text.trim(),
        'nationalNum': _nationalNumController.text.trim(),
      }, SetOptions(merge: true));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Home()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                // 🔥 Top Section with Icon and Text
                Column(
                  children: [

                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(40),
                          bottomRight: Radius.circular(40),
                        ),
                      ),
                      height: 200,
                      width: double.infinity,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 60.0),
                        child:  Icon(
                          Icons.medical_information,
                          size: 80,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Please Add Your Information",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    /*
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      height: 350,
                      width: double.infinity,
                      child: Column(
                        children: const [
                          Icon(
                            Icons.medical_information,
                            size: 80,
                            color: Colors.white,
                          ),
                          SizedBox(height: 10),
                          Text(
                            "Please Add Your Information",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                     */
                    const SizedBox(height: 30),
                  ],
                ),

                // 🌟 Text Fields
                _buildTextField(_nameController, "Name", TextInputType.text),
                const SizedBox(height: 16),
                _buildTextField(_ageController, "Age", TextInputType.number),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, "Phone", TextInputType.phone),
                const SizedBox(height: 16),
                _buildTextField(_nationalNumController, "National Number", TextInputType.number),
                const SizedBox(height: 16),
                _buildDropdownBloodType(),
                const SizedBox(height: 16),
                _buildDropdownCity(),
                const SizedBox(height: 30),

                // 🔥 Save Button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, TextInputType type) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) => value!.isEmpty ? "Enter your $label" : null,
    );
  }

  Widget _buildDropdownBloodType() {
    return DropdownButtonFormField<String>(
      value: _selectedBloodType,
      hint: const Text("Select Blood Type"),
      onChanged: (val) => setState(() => _selectedBloodType = val),
      items: _bloodTypes
          .map((type) => DropdownMenuItem(
        value: type,
        child: Text(type),
      ))
          .toList(),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) => value == null ? "Select a blood type" : null,
    );
  }


  Widget _buildDropdownCity() {
    return DropdownButtonFormField<String>(
      value: _selectedCity,
      hint: const Text("Select City"),
      onChanged: (val) => setState(() => _selectedCity = val),
      items: _city
          .map((type) => DropdownMenuItem(
        value: type,
        child: Text(type),
      ))
          .toList(),
      decoration: InputDecoration(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) => value == null ? "Select City" : null,
    );
  }



}



