import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdaptiveFab extends StatelessWidget {
  final VoidCallback onPressed;

  const AdaptiveFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return Positioned(
        top: 60, // Adjust for status bar
        right: 16,
        child: CupertinoButton(
          color: CupertinoColors.white.withOpacity(0.8),
          padding: const EdgeInsets.all(8.0),
          borderRadius: BorderRadius.circular(50),
          onPressed: onPressed,
          child: const Icon(
            CupertinoIcons.location_fill,
            color: CupertinoColors.activeBlue,
          ),
        ),
      );
    } else {
      return FloatingActionButton(
        onPressed: onPressed,
        child: const Icon(Icons.my_location),
      );
    }
  }
}
