import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrozemex/core/theme/theme.dart';

class SubmitProgressDialog extends StatefulWidget {
  final String title;

  const SubmitProgressDialog({
    super.key,
    required this.title,
  });

  @override
  State<SubmitProgressDialog> createState() => _SubmitProgressDialogState();
}

class _SubmitProgressDialogState extends State<SubmitProgressDialog> {
  int _secondsElapsed = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine active phase based on seconds elapsed
    String message = "Preparing listing details...";
    double progressFraction = 0.15;
    int activeStepIndex = 0;

    if (_secondsElapsed >= 4 && _secondsElapsed < 18) {
      message = "Uploading photos to secure storage...";
      progressFraction = 0.45;
      activeStepIndex = 1;
    } else if (_secondsElapsed >= 18 && _secondsElapsed < 32) {
      message = "Creating listing on server...";
      progressFraction = 0.75;
      activeStepIndex = 2;
    } else if (_secondsElapsed >= 32) {
      message = "Finalizing and indexing for search...";
      progressFraction = 0.90;
      activeStepIndex = 3;
    }

    final steps = [
      "Optimizing details & location",
      "Uploading photos to secure storage",
      "Creating listing on server",
      "Finalizing and indexing",
    ];

    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: AgroZemexTokens.radiusLargeCard,
            boxShadow: AgroZemexTokens.shadowLarge,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AgroZemexTokens.primary,
                ),
              ),
              const SizedBox(height: 20),
              
              // Animated progress ring/indicator
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progressFraction,
                      strokeWidth: 6,
                      backgroundColor: AgroZemexTokens.surfaceContainerLow,
                      valueColor: const AlwaysStoppedAnimation<Color>(AgroZemexTokens.primary),
                    ),
                    Text(
                      "${(progressFraction * 100).toInt()}%",
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AgroZemexTokens.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Dynamic status message
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AgroZemexTokens.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "This might take up to a minute depending on your internet connection.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: AgroZemexTokens.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(height: 1),
              const SizedBox(height: 16),
              
              // Steps Checklist
              ...List.generate(steps.length, (index) {
                final isCompleted = index < activeStepIndex;
                final isCurrent = index == activeStepIndex;
                
                Color itemColor = AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.5);
                Widget statusWidget = Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.3), width: 1.5),
                  ),
                );
                
                if (isCompleted) {
                  itemColor = AgroZemexTokens.success;
                  statusWidget = const Icon(
                    Icons.check_circle_rounded,
                    color: AgroZemexTokens.success,
                    size: 18,
                  );
                } else if (isCurrent) {
                  itemColor = AgroZemexTokens.primary;
                  statusWidget = const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(AgroZemexTokens.primary),
                    ),
                  );
                }
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      statusWidget,
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          steps[index],
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                            color: itemColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
