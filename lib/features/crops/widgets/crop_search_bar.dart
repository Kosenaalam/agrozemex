import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrozemex/core/theme/theme.dart';

class CropSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilterTap;

  const CropSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: AgroZemexTokens.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AgroZemexTokens.softShadows,
        border: Border.all(
          color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.1),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: AgroZemexTokens.onSurface,
        ),
        decoration: InputDecoration(
          hintText: 'Search fresh harvests, grains, spices...',
          hintStyle: GoogleFonts.inter(
            fontSize: 14,
            color: AgroZemexTokens.onSurfaceVariant,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
          prefixIcon: const Icon(
            Icons.search,
            color: AgroZemexTokens.onSurfaceVariant,
          ),
          suffixIcon: ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return value.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AgroZemexTokens.onSurfaceVariant,
                      ),
                      onPressed: onClear,
                    )
                  : IconButton(
                      icon: const Icon(
                        Icons.filter_list,
                        color: AgroZemexTokens.primary,
                      ),
                      onPressed: onFilterTap,
                    );
            },
          ),
        ),
      ),
    );
  }
}
