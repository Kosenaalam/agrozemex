import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrozemex/core/theme/theme.dart';

class SellerContactDisclaimerDialog extends StatefulWidget {
  const SellerContactDisclaimerDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SellerContactDisclaimerDialog(),
    );
    return result ?? false;
  }

  @override
  State<SellerContactDisclaimerDialog> createState() =>
      _SellerContactDisclaimerDialogState();
}

class _SellerContactDisclaimerDialogState
    extends State<SellerContactDisclaimerDialog> {
  bool _agreedToTerms = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.all(16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AgroZemexTokens.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shield_outlined,
              color: AgroZemexTokens.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Seller Contact Privacy Terms',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AgroZemexTokens.primary,
              ),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.amber.shade700.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade900,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Anti-Misuse Warning: Strictly monitored for genuine buyer inquiries.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'By revealing the land seller\'s contact number, you confirm and agree to the following terms:',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AgroZemexTokens.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            _buildBulletPoint(
              'Use this contact solely for land purchase or site visit inquiries.',
            ),
            _buildBulletPoint(
              'No spamming, promotional marketing, or unsolicited calls.',
            ),
            _buildBulletPoint(
              'Harassment or misusing seller numbers will result in permanent account suspension.',
            ),
            const SizedBox(height: 14),
            Theme(
              data: ThemeData(
                checkboxTheme: CheckboxThemeData(
                  fillColor: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return AgroZemexTokens.primary;
                    }
                    return null;
                  }),
                ),
              ),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _agreedToTerms,
                dense: true,
                onChanged: (val) {
                  setState(() {
                    _agreedToTerms = val ?? false;
                  });
                },
                title: Text(
                  'I agree to the terms and will not misuse the seller\'s contact details.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AgroZemexTokens.onSurface,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: GoogleFonts.inter(
              color: AgroZemexTokens.onSurfaceVariant,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _agreedToTerms
              ? () => Navigator.pop(context, true)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AgroZemexTokens.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'I Agree, Reveal Contact',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AgroZemexTokens.primary,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AgroZemexTokens.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
