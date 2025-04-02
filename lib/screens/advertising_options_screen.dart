import 'package:flutter/material.dart';
import 'package:neusenews/models/ad.dart';
import 'package:neusenews/screens/ad_creation_screen.dart';

class AdvertisingOptionsScreen extends StatelessWidget {
  const AdvertisingOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Advertise with Us"),
        backgroundColor: const Color(0xFFd2982a),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Grow Your Local Business with Neuse News",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              "Connect with our engaged audience of local readers and boost your business visibility through targeted digital advertising.",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            _buildAdOption(
              context,
              "Title Sponsor",
              "Premium placement at the top of the app with maximum visibility.",
              "• Logo/banner displayed prominently\n• Top visibility to all users\n• Best for brand awareness",
              "\$249/week",
              Colors.amber.shade100,
              AdType.titleSponsor,
              "assets/images/title_sponsor_example.png",
            ),
            _buildAdOption(
              context,
              "In-Feed Dashboard Ad",
              "Integrated ad placement in the main dashboard feed.",
              "• Native content-like appearance\n• High engagement rates\n• Great for promotions",
              "\$149/week",
              Colors.blue.shade100,
              AdType.inFeedDashboard,
              "assets/images/feed_ad_example.png",
            ),
            _buildAdOption(
              context,
              "In-Feed News Ad",
              "Ad placement within category-specific news articles.",
              "• Targeted to specific news categories\n• Contextual relevance\n• Perfect for niche businesses",
              "\$99/week",
              Colors.green.shade100,
              AdType.inFeedNews,
              "assets/images/news_ad_example.png",
            ),
            _buildAdOption(
              context,
              "Weather Sponsor",
              "Exclusive sponsorship of our popular weather section.",
              "• High traffic placement\n• Exclusive category sponsorship\n• Daily user engagement",
              "\$199/week",
              Colors.orange.shade100,
              AdType.weather,
              "assets/images/weather_ad_example.png",
            ),
            const SizedBox(height: 24),
            const Text(
              "Why Advertise with Neuse News?",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildBenefitItem(
              context,
              Icons.people,
              "Local Reach",
              "Connect with engaged local audiences who trust our platform",
            ),
            _buildBenefitItem(
              context,
              Icons.bar_chart,
              "Performance Analytics",
              "Track impressions, clicks, and engagement with detailed reports",
            ),
            _buildBenefitItem(
              context,
              Icons.rocket_launch,
              "Targeted Exposure",
              "Reach users interested in specific categories relevant to your business",
            ),
            _buildBenefitItem(
              context,
              Icons.handshake,
              "Community Support",
              "Support local journalism while growing your business",
            ),
            const SizedBox(height: 32),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Navigate to ad creation screen without preselecting a type
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdCreationScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFd2982a),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: const Text(
                  "Get Started",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildAdOption(
    BuildContext context,
    String title,
    String subtitle,
    String features,
    String price,
    Color backgroundColor,
    AdType adType,
    String imagePath,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12),
      elevation: 4,
      color: backgroundColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AdCreationScreen(initialAdType: adType),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      imagePath,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (context, error, stackTrace) => Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey.shade300,
                            child: const Icon(Icons.image, size: 50),
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                        const SizedBox(height: 8),
                        Text(
                          price,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFd2982a),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(features, style: const TextStyle(height: 1.5)),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                AdCreationScreen(initialAdType: adType),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFd2982a),
                  ),
                  child: const Text(
                    "Create Ad",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBenefitItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 32, color: const Color(0xFFd2982a)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
