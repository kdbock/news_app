import 'package:flutter/material.dart';

class RoiCalculatorWidget extends StatefulWidget {
  const RoiCalculatorWidget({super.key});

  @override
  State<RoiCalculatorWidget> createState() => _RoiCalculatorWidgetState();
}

class _RoiCalculatorWidgetState extends State<RoiCalculatorWidget> {
  final _adSpendController = TextEditingController(text: '500');
  final _conversionRateController = TextEditingController(text: '5');
  final _averageOrderValueController = TextEditingController(text: '75');
  
  double _roi = 0.0;
  double _totalRevenue = 0.0;
  
  @override
  void initState() {
    super.initState();
    _calculateRoi();
  }
  
  @override
  void dispose() {
    _adSpendController.dispose();
    _conversionRateController.dispose();
    _averageOrderValueController.dispose();
    super.dispose();
  }
  
  void _calculateRoi() {
    final adSpend = double.tryParse(_adSpendController.text) ?? 0;
    final conversionRate = double.tryParse(_conversionRateController.text) ?? 0;
    final averageOrderValue = double.tryParse(_averageOrderValueController.text) ?? 0;
    
    // Calculate metrics
    final expectedConversions = (835 * conversionRate / 100); // Based on 835 clicks
    final totalRevenue = expectedConversions * averageOrderValue;
    final roi = adSpend > 0 ? ((totalRevenue - adSpend) / adSpend) * 100 : 0;
    
    setState(() {
      _totalRevenue = totalRevenue;
      _roi = roi.toDouble();
    });
  }

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
              'ROI Calculator',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _adSpendController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Ad Spend (\$)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => _calculateRoi(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _conversionRateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Conv. Rate (%)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => _calculateRoi(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _averageOrderValueController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Avg Order (\$)',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (_) => _calculateRoi(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFd2982a).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFd2982a)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Revenue:'),
                      Text(
                        '\$${_totalRevenue.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Return on Investment:'),
                      Text(
                        '${_roi.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFd2982a),
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}