import 'package:flutter/material.dart';
import 'package:agrozemex/core/theme/theme.dart';

class MapActionButtons extends StatelessWidget {
  final VoidCallback onUndo;
  final VoidCallback onClear;
  final VoidCallback onSave;

  const MapActionButtons({
    super.key,
    required this.onUndo,
    required this.onClear,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onUndo,
          icon: const Icon(Icons.undo),
          tooltip: 'Undo',
        ),
        IconButton(
          onPressed: onClear,
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          tooltip: 'Clear',
        ),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: AgroZemexTokens.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: AgroZemexTokens.radiusEight,
              ),
            ),
            child: Text(
              'Save & View Details',
              style: AgroZemexTokens.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
