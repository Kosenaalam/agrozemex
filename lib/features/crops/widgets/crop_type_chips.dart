import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrozemex/core/theme/theme.dart';

class CropTypeChips extends StatelessWidget {
  final List<String> cropTypes;
  final String? selectedCropType;
  final ValueChanged<String?> onSelected;

  const CropTypeChips({
    super.key,
    required this.cropTypes,
    required this.selectedCropType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: cropTypes.length,
        itemBuilder: (context, index) {
          final type = cropTypes[index];
          final bool isSelected =
              (selectedCropType == type) ||
              (selectedCropType == null && type == 'All');

          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(type),
              selected: isSelected,
              onSelected: (selected) {
                onSelected(type == 'All' ? null : type);
              },
              selectedColor: AgroZemexTokens.primary,
              backgroundColor: AgroZemexTokens.surfaceContainerLow,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : AgroZemexTokens.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          );
        },
      ),
    );
  }
}
