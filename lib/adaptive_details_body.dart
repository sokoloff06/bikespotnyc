import 'dart:io';

import 'package:bikespotnyc/parking_spot.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveDetailsBody extends StatelessWidget {
  final ParkingSpot parkingSpot;
  final VoidCallback onNavigatePressed;

  const AdaptiveDetailsBody({
    super.key,
    required this.parkingSpot,
    required this.onNavigatePressed,
  });

  @override
  Widget build(BuildContext context) {
    final isIOS = Platform.isIOS;

    // Use Material theme for styles on both platforms to ensure color consistency.
    // The Cupertino text styles are preserved but with colors from the Material theme.
    final titleStyle = isIOS
        ? CupertinoTheme.of(context).textTheme.navLargeTitleTextStyle.copyWith(
            color: Theme.of(context).textTheme.headlineSmall?.color,
          )
        : Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);

    final bodyStyle = Theme.of(context).textTheme.bodyLarge;

    final imageWidget = Image.asset(
      parkingSpot.rackType.imagePath,
      height: 200,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // Fallback in case the image fails to load
        print(error);
        return Container(
          height: 200,
          width: double.infinity,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: const Icon(Icons.image_not_supported, size: 100),
        );
      },
    );

    final navigateButton = isIOS
        ? CupertinoButton.filled(
            onPressed: onNavigatePressed,
            child: const Text('Navigate'),
          )
        : ElevatedButton(
            onPressed: onNavigatePressed,
            child: const Text('Navigate'),
          );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(parkingSpot.siteId, style: titleStyle),
            const SizedBox(height: 16),
            imageWidget,
            const SizedBox(height: 16),
            Text('Borough: ${parkingSpot.borough}', style: bodyStyle),
            const SizedBox(height: 8),
            Text(
              'Rack Type: ${parkingSpot.rackType.displayName}',
              style: bodyStyle,
            ),
            const SizedBox(height: 32),
            Center(child: navigateButton),
          ],
        ),
      ),
    );
  }
}
