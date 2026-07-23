import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/agrozemex_tokens.dart';

/// Help & Support Screen displaying detailed FAQs, support contact info, and platform guidelines.
class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@agrozeme.com',
      queryParameters: {
        'subject': 'AgroZemex Support Request',
      },
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Contact support at support@agrozeme.com')),
          );
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contact support at support@agrozeme.com')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AgroZemexTokens.surface,
      appBar: AppBar(
        backgroundColor: AgroZemexTokens.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AgroZemexTokens.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.inter(
            color: AgroZemexTokens.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(AgroZemexTokens.marginMobile),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AgroZemexTokens.primary,
                borderRadius: AgroZemexTokens.radiusLargeCard,
                boxShadow: AgroZemexTokens.softShadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: AgroZemexTokens.radiusTwelve,
                        ),
                        child: const Icon(
                          Icons.headset_mic_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome to AgroZemex Support',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'We are here to help you 24/7',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We\'re committed to providing a secure, reliable, and seamless experience for every buyer, seller, and farmer using AgroZemex. If you have questions, experience technical issues, or need assistance with your account or listings, our support team is here to help.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Contact Support Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AgroZemexTokens.surfaceContainerLowest,
                borderRadius: AgroZemexTokens.radiusLargeCard,
                border: Border.all(
                  color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.1),
                ),
                boxShadow: AgroZemexTokens.softShadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.email_outlined, color: AgroZemexTokens.primary, size: 22),
                      const SizedBox(width: 10),
                      Text(
                        'Contact Support',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AgroZemexTokens.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _launchEmail(context),
                    borderRadius: AgroZemexTokens.radiusEight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: AgroZemexTokens.primary.withValues(alpha: 0.08),
                        borderRadius: AgroZemexTokens.radiusEight,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Email: support@agrozeme.com',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AgroZemexTokens.primary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.open_in_new, size: 16, color: AgroZemexTokens.primary),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Our support team aims to respond to all inquiries within 24–48 business hours. Response times may vary during weekends, public holidays, or periods of high support volume.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                      color: AgroZemexTokens.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Please include when contacting us:\n• Your registered email & phone number\n• Listing ID or Booking ID (if applicable)\n• Device model & OS version\n• Detailed description & screenshots',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.6,
                      color: AgroZemexTokens.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AgroZemexTokens.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            // FAQ Sections
            _buildFaqSection(
              title: 'Account & Login',
              icon: Icons.person_outline_rounded,
              items: [
                _FaqItem(
                  question: 'I cannot log in to my account.',
                  answer: 'Please verify that:\n• You are using the correct email address or phone number.\n• Your password is entered correctly.\n• Your internet connection is stable.\n• Your app is updated to the latest version.\n\nIf the problem persists, contact us at support@agrozeme.com.',
                ),
                _FaqItem(
                  question: 'I forgot my password.',
                  answer: 'Use the Forgot Password option on the login screen and follow the instructions sent to your registered email address.',
                ),
                _FaqItem(
                  question: 'How do I change my profile information?',
                  answer: 'Open Profile → Edit Profile. From there, you can update your display name, profile photo, and contact details where permitted.',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildFaqSection(
              title: 'Land Listings',
              icon: Icons.landscape_outlined,
              items: [
                _FaqItem(
                  question: 'How do I create a land listing?',
                  answer: '1. Sign in to your AgroZemex account.\n2. Open the Sell Land section.\n3. Draw your land boundary using the interactive map.\n4. Enter the required property details.\n5. Upload clear property images.\n6. Review the information and Publish your listing.',
                ),
                _FaqItem(
                  question: 'Why is my listing not visible?',
                  answer: 'Your listing may not appear immediately due to incomplete listing information, missing images, temporary synchronization delays, network connectivity issues, or review processes. If it continues for more than 24 hours, contact support.',
                ),
                _FaqItem(
                  question: 'Can I edit my listing?',
                  answer: 'Yes. Navigate to Profile → My Listings, select the listing you wish to edit, and update the required information.',
                ),
                _FaqItem(
                  question: 'Can I delete my listing?',
                  answer: 'Yes. You can remove your listing at any time from your dashboard. Deleted listings will no longer be visible to other users.',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildFaqSection(
              title: 'Crop Marketplace',
              icon: Icons.eco_outlined,
              items: [
                _FaqItem(
                  question: 'How do I sell crops?',
                  answer: 'Open the Sell Crop section and add crop details, enter available quantity, set the price, upload crop images, and submit your listing.',
                ),
                _FaqItem(
                  question: 'Can I edit my crop listing?',
                  answer: 'Yes. Go to My Crop Listings, select the listing, and update the information.',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildFaqSection(
              title: 'Map & Land Boundary',
              icon: Icons.map_outlined,
              items: [
                _FaqItem(
                  question: 'Is the land area calculated by AgroZemex legally certified?',
                  answer: 'No. AgroZemex provides estimated land measurements based on user-drawn boundaries and mapping technologies for informational purposes only. For legal or property registration purposes, always consult a licensed surveyor or government authority.',
                ),
                _FaqItem(
                  question: 'Why does my GPS location appear inaccurate?',
                  answer: 'GPS accuracy depends on device hardware, weather conditions, satellite visibility, buildings, trees, and internet connectivity. Small variations in location accuracy are normal.',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildFaqSection(
              title: 'Site Visit Booking',
              icon: Icons.calendar_today_outlined,
              items: [
                _FaqItem(
                  question: 'How do I request a site visit?',
                  answer: 'Open a property listing and select Book Visit. Choose your preferred date and time, then submit your request. The seller will receive your request and may confirm or decline it.',
                ),
                _FaqItem(
                  question: 'Can I cancel a booking request?',
                  answer: 'If cancellation is available within the app, you may cancel before the scheduled visit. Otherwise, contact the seller directly if their contact information has been shared.',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildFaqSection(
              title: 'Wishlist & Images',
              icon: Icons.favorite_border_rounded,
              items: [
                _FaqItem(
                  question: 'How do I save properties?',
                  answer: 'Tap the Heart icon on any land or crop listing. Your saved listings will appear in the Wishlist section.',
                ),
                _FaqItem(
                  question: 'Why won\'t my images upload?',
                  answer: 'Possible reasons include poor internet connection, unsupported file format, file size exceeding limits, or temporary server issues. Try again after verifying your connection or using smaller image files.',
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildFaqSection(
              title: 'Technical & Notifications',
              icon: Icons.build_outlined,
              items: [
                _FaqItem(
                  question: 'I\'m not receiving notifications.',
                  answer: 'Please ensure notifications are enabled in your device settings, notification permission has been granted to AgroZemex, your internet connection is active, and battery optimization is not restricting the app.',
                ),
                _FaqItem(
                  question: 'The app is slow or crashes.',
                  answer: 'Try restarting the app, restarting your device, updating AgroZemex to the latest version, ensuring sufficient storage space, and verifying your internet connection. If issues continue, contact support.',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reporting, Safety & Business Hours Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AgroZemexTokens.surfaceContainerLowest,
                borderRadius: AgroZemexTokens.radiusLargeCard,
                border: Border.all(
                  color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.1),
                ),
                boxShadow: AgroZemexTokens.softShadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextSectionHeader(Icons.security_outlined, 'Reporting & Safety'),
                  const SizedBox(height: 8),
                  Text(
                    'Please contact support immediately if you encounter fake listings, fraudulent crops, inappropriate content, harassment, spam, copyright violations, or security concerns. Users are responsible for independently verifying property ownership and crop quality before transacting.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                  ),
                  const Divider(height: 24),

                  _buildTextSectionHeader(Icons.access_time_rounded, 'Business Hours'),
                  const SizedBox(height: 8),
                  Text(
                    'Support requests are monitored Monday through Friday during standard business hours. Requests submitted outside these hours will be addressed as soon as possible on the next business day.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                  ),
                  const Divider(height: 24),

                  _buildTextSectionHeader(Icons.verified_outlined, 'Our Commitment'),
                  const SizedBox(height: 8),
                  Text(
                    'At AgroZemex, we are dedicated to building a trusted digital marketplace for agricultural land and crop trading. Thank you for choosing AgroZemex.',
                    style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: Text(
                'AgroZemex Support • support@agrozeme.com',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqSection({
    required String title,
    required IconData icon,
    required List<_FaqItem> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AgroZemexTokens.surfaceContainerLowest,
        borderRadius: AgroZemexTokens.radiusTwelve,
        border: Border.all(
          color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.1),
        ),
        boxShadow: AgroZemexTokens.softShadows,
      ),
      child: ExpansionTile(
        leading: Icon(icon, color: AgroZemexTokens.primary),
        title: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AgroZemexTokens.onSurface,
          ),
        ),
        childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: items.map((item) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.question,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AgroZemexTokens.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.answer,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.5,
                    color: AgroZemexTokens.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTextSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AgroZemexTokens.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AgroZemexTokens.onSurface,
          ),
        ),
      ],
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;

  _FaqItem({required this.question, required this.answer});
}
