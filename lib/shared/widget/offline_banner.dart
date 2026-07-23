import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/core/services/connectivity_service.dart';

class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner> {
  bool _wasOffline = false;
  bool _showRestoredBanner = false;
  Timer? _restoredTimer;

  @override
  void dispose() {
    _restoredTimer?.cancel();
    super.dispose();
  }

  void _triggerRestoredBanner() {
    setState(() {
      _showRestoredBanner = true;
    });
    _restoredTimer?.cancel();
    _restoredTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showRestoredBanner = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final connectivity = context.watch<ConnectivityService>();
    final isOnline = connectivity.isConnected;

    if (!isOnline) {
      _wasOffline = true;
    } else if (_wasOffline && isOnline) {
      _wasOffline = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _triggerRestoredBanner();
      });
    }

    final bool showOfflineBar = !isOnline;
    final bool showBanner = showOfflineBar || _showRestoredBanner;

    return Stack(
      children: [
        widget.child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 350),
          curve: Curves.fastOutSlowIn,
          top: showBanner ? 0 : -50,
          left: 0,
          right: 0,
          height: 42,
          child: Material(
            elevation: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              color: showOfflineBar
                  ? const Color(0xFFC62828) // Amber/Dark Red for offline
                  : AgroZemexTokens.success, // Green for restored
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SafeArea(
                bottom: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      showOfflineBar
                          ? Icons.wifi_off_rounded
                          : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      showOfflineBar
                          ? 'No Internet Connection • Offline Mode'
                          : 'Internet Connection Restored',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
