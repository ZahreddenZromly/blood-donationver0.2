import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AdminMainDashboardPage extends StatefulWidget {
  const AdminMainDashboardPage({super.key});

  @override
  State<AdminMainDashboardPage> createState() => _AdminMainDashboardPageState();
}

class _AdminMainDashboardPageState extends State<AdminMainDashboardPage> {
  int totalUsers = 0;
  int uniqueBloodTypes = 0;
  int uniqueCities = 0;
  int totalDonations = 0;
  bool isLoading = true;
  Map<String, int> bloodTypeCounts = {};

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final userDocs = usersSnapshot.docs;

      final Set<String> bloodTypes = {};
      final Set<String> cities = {};
      final Map<String, int> bloodTypeCountsMap = {};

      for (var doc in userDocs) {
        final data = doc.data();
        final bloodType = data['bloodType'];
        if (bloodType != null) {
          bloodTypes.add(bloodType);
          bloodTypeCountsMap[bloodType] =
              (bloodTypeCountsMap[bloodType] ?? 0) + 1;
        }
        if (data['city'] != null) cities.add(data['city']);
      }

      int donationsCount = 0;
      try {
        final donationSnapshot =
            await FirebaseFirestore.instance.collection('donations').get();
        donationsCount = donationSnapshot.docs.length;
      } catch (_) {}

      setState(() {
        totalUsers = userDocs.length;
        uniqueBloodTypes = bloodTypes.length;
        uniqueCities = cities.length;
        totalDonations = donationsCount;
        bloodTypeCounts = bloodTypeCountsMap;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching data: $e");
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chartData = [
      _DashboardData('Donors', totalUsers, Colors.blue),
      _DashboardData('Blood Types', uniqueBloodTypes, Colors.red),
      _DashboardData('Cities', uniqueCities, Colors.green),
      _DashboardData('Donations', totalDonations, Colors.purple),
    ];

    final sortedBloodTypes =
        bloodTypeCounts.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final top5BloodTypes = sortedBloodTypes.take(5).toList();

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: const Text(
            "Dashboard",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 36,
            ),
          ),
        ),
        backgroundColor: Colors.redAccent,
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    dashboardCard(
                      "Total Donors",
                      totalUsers,
                      Icons.people,
                      Colors.blue,
                    ),
                    dashboardCard(
                      "Blood Types",
                      uniqueBloodTypes,
                      Icons.water_drop,
                      Colors.red,
                    ),
                    dashboardCard(
                      "Unique Cities",
                      uniqueCities,
                      Icons.location_city,
                      Colors.green,
                    ),
                    dashboardCard(
                      "Total Donations",
                      totalDonations,
                      Icons.volunteer_activism,
                      Colors.deepPurple,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Dashboard Summary (Chart)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              ([
                                        totalUsers,
                                        uniqueBloodTypes,
                                        uniqueCities,
                                        totalDonations,
                                      ].reduce((a, b) => a > b ? a : b) *
                                      1.2)
                                  .ceilToDouble(),
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (
                                  double value,
                                  TitleMeta meta,
                                ) {
                                  const labels = [
                                    'Donors',
                                    'Blood Types',
                                    'Cities',
                                    'Donations',
                                  ];
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8.0,
                                    child: Text(labels[value.toInt()]),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups:
                              chartData.asMap().entries.map((entry) {
                                final index = entry.key;
                                final data = entry.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: data.value.toDouble(),
                                      color: data.color,
                                      width: 22,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Blood Type Distribution',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 0,
                          centerSpaceRadius: 40,
                          sections:
                              bloodTypeCounts.entries.map((entry) {
                                return PieChartSectionData(
                                  color: _getBloodTypeColor(entry.key),
                                  value: entry.value.toDouble(),
                                  title: '${entry.value}',
                                  radius: 50,
                                  titleStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (var bloodType in _getBloodTypeLabels().keys)
                          Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: _getBloodTypeColor(bloodType),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(bloodType),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Donation Trend (Mock Data)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 250,
                      child: LineChart(
                        LineChartData(
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                FlSpot(0, 5),
                                FlSpot(1, 10),
                                FlSpot(2, 7),
                                FlSpot(3, 12),
                                FlSpot(4, 9),
                                FlSpot(5, 13),
                                FlSpot(6, 11),
                              ],
                              isCurved: true,
                              color: Colors.teal,
                              barWidth: 4,
                              belowBarData: BarAreaData(
                                show: true,
                                color: Colors.teal.withOpacity(0.3),
                              ),
                            ),
                          ],
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  const days = [
                                    'Mon',
                                    'Tue',
                                    'Wed',
                                    'Thu',
                                    'Fri',
                                    'Sat',
                                    'Sun',
                                  ];
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    child: Text(
                                      days[value.toInt() % days.length],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                          gridData: FlGridData(show: true),
                          borderData: FlBorderData(show: true),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Top Blood Types (Top 5)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 300,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY:
                              top5BloodTypes.isNotEmpty
                                  ? top5BloodTypes
                                          .map((e) => e.value)
                                          .reduce((a, b) => a > b ? a : b) *
                                      1.2
                                  : 10,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final label =
                                      value.toInt() < top5BloodTypes.length
                                          ? top5BloodTypes[value.toInt()].key
                                          : '';
                                  return SideTitleWidget(
                                    axisSide: meta.axisSide,
                                    space: 8.0,
                                    child: Text(label),
                                  );
                                },
                              ),
                            ),
                          ),
                          barGroups:
                              top5BloodTypes.asMap().entries.map((entry) {
                                final index = entry.key;
                                final bloodType = entry.value.key;
                                final count = entry.value.value;
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: count.toDouble(),
                                      color: _getBloodTypeColor(bloodType),
                                      width: 20,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  Color _getBloodTypeColor(String bloodType) {
    switch (bloodType) {
      case 'A+':
        return Colors.red;
      case 'A-':
        return Colors.blue;
      case 'B+':
        return Colors.yellow;
      case 'B-':
        return Colors.orange;
      case 'AB+':
        return Colors.purple;
      case 'AB-':
        return Colors.brown;
      case 'O+':
        return Colors.green;
      case 'O-':
        return Colors.greenAccent;
      default:
        return Colors.grey;
    }
  }

  Map<String, String> _getBloodTypeLabels() {
    return {
      'A+': 'Red',
      'A-': 'Blue',
      'B+': 'Yellow',
      'B-': 'Orange',
      'AB+': 'Purple',
      'AB-': 'Brown',
      'O+': 'Green',
      'O-': 'GreenAccent',
    };
  }

  Widget dashboardCard(String title, int value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        trailing: Text(
          value.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: color,
          ),
        ),
      ),
    );
  }
}

class _DashboardData {
  final String label;
  final int value;
  final Color color;

  _DashboardData(this.label, this.value, this.color);
}
