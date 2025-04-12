import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class AudienceBreakdownWidget extends StatelessWidget {
  const AudienceBreakdownWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Audience Breakdown',
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            AspectRatio(
              aspectRatio: 1.5,
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      value: 35,
                      title: '35%',
                      color: Colors.blue,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 25,
                      title: '25%',
                      color: Colors.green,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: '20%',
                      color: Colors.orange,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: 20,
                      title: '20%',
                      color: Colors.purple,
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildLegendItem('18-24', Colors.blue),
                _buildLegendItem('25-34', Colors.green),
                _buildLegendItem('35-44', Colors.orange),
                _buildLegendItem('45+', Colors.purple),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}