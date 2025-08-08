import 'package:flutter/material.dart';

class DonationEligibilityScreen extends StatefulWidget {
  const DonationEligibilityScreen({super.key});

  @override
  _DonationEligibilityScreenState createState() =>
      _DonationEligibilityScreenState();
}

class _DonationEligibilityScreenState extends State<DonationEligibilityScreen> {
  bool isHealthy = false;
  bool donatedRecently = false;
  bool traveledAbroad = false;
  bool onMedication = false;

  void checkEligibility() {
    if (isHealthy && !donatedRecently && !traveledAbroad && !onMedication) {
      Navigator.pushNamed(context, '/donation_confirm');
    } else {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("ليس متوافق"),
          content: const Text(
              "علي حسب اجاباتك السابقة انت ليس قادر بالتبرع"),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("نعم")),
          ],
        ),
      );
    }
  }

  Widget buildSwitchTile(
      {required String title,
        required IconData icon,
        required bool value,
        required void Function(bool) onChanged}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SwitchListTile(
        title: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        secondary: Icon(icon, color: Colors.redAccent),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("التحقق من صحتك"),
        backgroundColor: Colors.redAccent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.redAccent,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: const Text(
              "الرجاء الاجابة علي الاسئلة الاتية لكي نتحقق من امكانية التبرع",
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                const SizedBox(height: 20),
                buildSwitchTile(
                  title: "هل تشعر بصحة جيدة",
                  icon: Icons.favorite,
                  value: isHealthy,
                  onChanged: (val) => setState(() => isHealthy = val),
                ),
                buildSwitchTile(
                  title: "هل قمت بالتبرع بالدم في الثلاثة الشهور السابقة؟",
                  icon: Icons.bloodtype,
                  value: donatedRecently,
                  onChanged: (val) => setState(() => donatedRecently = val),
                ),
                buildSwitchTile(
                  title: "هل قمت بالسفر مؤخرا؟",
                  icon: Icons.flight,
                  value: traveledAbroad,
                  onChanged: (val) => setState(() => traveledAbroad = val),
                ),
                buildSwitchTile(
                  title: "هل انت الان تتعاطى اي نوع من الادوية؟",
                  icon: Icons.medication,
                  value: onMedication,
                  onChanged: (val) => setState(() => onMedication = val),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward),
                onPressed: checkEligibility,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
                  "أكمل الي التأكد",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
