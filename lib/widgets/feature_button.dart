// File: lib/widgets/feature_button.dart
import 'package:flutter/material.dart';

class FeatureButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget destination;

  const FeatureButton({
    super.key,
    required this.title,
    required this.icon,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => destination));
        },
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
      ),
    );
  }
}
