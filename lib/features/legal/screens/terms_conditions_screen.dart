import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/agrozemex_tokens.dart';

/// Terms & Conditions Screen displaying complete legal terms of service and user agreement.
class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@agrozeme.com',
      queryParameters: {
        'subject': 'Terms & Conditions Inquiry',
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
          'Terms & Conditions',
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
            // Header Card
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
                          Icons.description_outlined,
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
                              'Terms & Conditions',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'AgroZemex User Agreement & Platform Terms',
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
                  const SizedBox(height: 14),
                  Text(
                    'Welcome to AgroZemex. By accessing or using our application or website, you agree to comply with these Terms & Conditions. If you do not agree, please discontinue use of the Platform.',
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

            // Section 1 & 2: Platform Purpose & Eligibility
            _buildCard(
              children: [
                _buildSectionHeader(Icons.apps_rounded, '1. Platform Purpose'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex is a technology platform that connects buyers and sellers of agricultural land and crop produce. AgroZemex does not own, buy, sell, broker, verify, or guarantee any land, crop, or transaction listed on the Platform.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.verified_user_outlined, '2. Eligibility'),
                const SizedBox(height: 8),
                Text(
                  'You must be legally eligible to enter into contracts under applicable law. By creating an account, you confirm that the information you provide is accurate and up to date.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 3 & 4: User Responsibilities & Listings
            _buildCard(
              children: [
                _buildSectionHeader(Icons.assignment_ind_outlined, '3. User Responsibilities'),
                const SizedBox(height: 8),
                _buildBulletList([
                  'Providing truthful and accurate information.',
                  'Maintaining the confidentiality of your account credentials.',
                  'Ensuring you have the legal right to list land, crops, images, and other content.',
                  'Complying with all applicable laws and regulations.',
                ]),
                const Divider(height: 28),

                _buildSectionHeader(Icons.list_alt_rounded, '4. Listings'),
                const SizedBox(height: 8),
                Text(
                  'Sellers are solely responsible for the accuracy of listings, prices, descriptions, images, ownership information, and legal documents. Buyers should independently verify all information before making any decision.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 5, 6, 7: Verification, Maps & Bookings
            _buildCard(
              children: [
                _buildSectionHeader(Icons.fact_check_outlined, '5. Property & Crop Verification'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex does not verify property ownership, land records, crop quality, legal documents, pricing, measurements, or government approvals. Users must perform their own due diligence before completing any transaction.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.map_outlined, '6. Maps & Area Calculations'),
                const SizedBox(height: 8),
                Text(
                  'Map locations, GPS coordinates, boundary drawings, and land area calculations are provided for informational purposes only and may not represent official survey records. They must not be relied upon as legal measurements.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.calendar_today_outlined, '7. Site Visit Bookings'),
                const SizedBox(height: 8),
                Text(
                  'Booking a site visit through AgroZemex does not create a legal agreement or guarantee the availability, ownership, or sale of any property.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 8: Prohibited Activities
            _buildCard(
              children: [
                _buildSectionHeader(Icons.block_outlined, '8. Prohibited Activities'),
                const SizedBox(height: 8),
                Text(
                  'Users must not:',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                _buildBulletList([
                  'Publish false or misleading listings.',
                  'Upload unlawful, offensive, or copyrighted content without permission.',
                  'Harass, threaten, spam, or impersonate other users.',
                  'Misuse seller contact information.',
                  'Attempt fraud, hacking, or unauthorized access to the Platform.',
                ]),
                const SizedBox(height: 8),
                Text(
                  'Violations may result in account suspension or permanent termination.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AgroZemexTokens.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 9, 10, 11, 12: Privacy, 3rd-Party, Liability, Suspension
            _buildCard(
              children: [
                _buildSectionHeader(Icons.privacy_tip_outlined, '9. Privacy & 10. Third-Party Services'),
                const SizedBox(height: 8),
                Text(
                  'Your use of AgroZemex is governed by our Privacy Policy. AgroZemex integrates third-party services including Firebase, Google services, Apple Sign-In, and Mapbox, operating under their respective terms.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.gavel_outlined, '11. Limitation of Liability'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex is not responsible for disputes, losses, damages, fraud, property ownership issues, crop quality, financial transactions, or agreements between users. The Platform acts solely as a technology service facilitating connections between buyers and sellers.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.no_accounts_outlined, '12. Account Suspension & 13. Changes to Terms'),
                const SizedBox(height: 8),
                Text(
                  'We reserve the right to suspend or permanently terminate accounts that violate these Terms or applicable laws. We may update these Terms & Conditions at any time.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 14 & 15: Governing Law & Contact Us
            _buildCard(
              children: [
                _buildSectionHeader(Icons.balance_outlined, '14. Governing Law'),
                const SizedBox(height: 8),
                Text(
                  'These Terms shall be governed by and interpreted in accordance with the laws of the Republic of India. Any disputes shall be subject to the exclusive jurisdiction of the competent courts in India.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.mail_outline_rounded, '15. Contact Us'),
                const SizedBox(height: 8),
                Text(
                  'For questions regarding these Terms & Conditions, please contact us:',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
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
                              'AgroZemex Support: support@agrozeme.com',
                              style: GoogleFonts.inter(
                                fontSize: 13,
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
              ],
            ),
            const SizedBox(height: 24),

            // Agreement Consent Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AgroZemexTokens.primary.withValues(alpha: 0.06),
                borderRadius: AgroZemexTokens.radiusTwelve,
                border: Border.all(
                  color: AgroZemexTokens.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                'By creating an account or using AgroZemex, you acknowledge that you have read, understood, and agreed to these Terms & Conditions.',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                  color: AgroZemexTokens.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),

            Center(
              child: Text(
                'AgroZemex Terms & Conditions • support@agrozeme.com',
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

  Widget _buildCard({required List<Widget> children}) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AgroZemexTokens.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AgroZemexTokens.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBulletList(List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AgroZemexTokens.primary,
                ),
              ),
              Expanded(
                child: Text(
                  item,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    height: 1.4,
                    color: AgroZemexTokens.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
