import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/agrozemex_tokens.dart';

/// About Us Screen detailing AgroZemex vision, mission, tech stack, and commitment.
class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@agrozeme.com',
      queryParameters: {
        'subject': 'AgroZemex Inquiry',
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
          'About Us',
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
            // Hero Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AgroZemexTokens.primary,
                borderRadius: AgroZemexTokens.radiusLargeCard,
                boxShadow: AgroZemexTokens.softShadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: AgroZemexTokens.radiusTwelve,
                    ),
                    child: const Icon(
                      Icons.agriculture_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'About AgroZemex',
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CONNECTING AGRICULTURE THROUGH TECHNOLOGY',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'AgroZemex is a modern digital marketplace designed to simplify the discovery, listing, and exchange of agricultural land and crop produce. Our mission is to bridge the gap between landowners, farmers, buyers, agricultural businesses, and investors by providing a secure, transparent, and technology-driven platform that makes agricultural transactions more accessible and efficient.',
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

            // Vision & Mission Card
            _buildCard(
              children: [
                _buildSectionHeader(Icons.visibility_outlined, 'Our Vision'),
                const SizedBox(height: 8),
                Text(
                  'Our vision is to become one of the most trusted digital ecosystems for agricultural real estate and crop trading by empowering rural communities, supporting sustainable agricultural growth, and making agricultural opportunities accessible to everyone through innovation.\n\nWe believe technology should simplify agricultural commerce, improve transparency, and help connect the right people at the right time.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.flag_outlined, 'Our Mission'),
                const SizedBox(height: 8),
                Text(
                  'Our mission is to build a reliable, secure, and user-friendly platform where users can:',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                _buildBulletList([
                  'Discover agricultural land across different regions.',
                  'List farmland with detailed property information.',
                  'Buy and sell crop harvests efficiently.',
                  'Connect directly with verified buyers and sellers.',
                  'Explore land using interactive mapping technology.',
                  'Schedule property visits conveniently.',
                  'Make informed decisions through rich property information and imagery.',
                ]),
              ],
            ),
            const SizedBox(height: 16),

            // What We Do & Tech Stack Card
            _buildCard(
              children: [
                _buildSectionHeader(Icons.apps_rounded, 'What We Do'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex serves as a technology platform that enables users to publish, discover, and manage agricultural listings. Our platform supports:',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                _buildBulletList([
                  'Agricultural land listings & Crop marketplace listings',
                  'Interactive GIS-based property visualization',
                  'Secure user authentication & Intelligent property search',
                  'Location-aware discovery & Property bookmarking',
                  'Site visit requests & Seller profile management',
                  'Image galleries & Real-time listing updates',
                ]),
                const Divider(height: 28),

                _buildSectionHeader(Icons.code_rounded, 'Built With Modern Technology'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex is developed using industry-standard technologies to deliver performance, security, and reliability:',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    'Flutter',
                    'Firebase Auth',
                    'Cloud Firestore',
                    'Firebase Storage',
                    'Firebase FCM',
                    'Mapbox Maps',
                    'Hive Caching',
                    'Provider State',
                    'Clean Architecture',
                    'Cloud Functions',
                  ].map((tech) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AgroZemexTokens.primary.withValues(alpha: 0.08),
                      borderRadius: AgroZemexTokens.radiusPill,
                    ),
                    child: Text(
                      tech,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AgroZemexTokens.primary,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Key Features: Mapping & Crops Card
            _buildCard(
              children: [
                _buildSectionHeader(Icons.map_outlined, 'Interactive Mapping Technology'),
                const SizedBox(height: 8),
                Text(
                  'One of AgroZemex\'s key features is its interactive mapping experience. Users can visualize land on satellite imagery, draw property boundaries, estimate land area, and better understand geographical characteristics before contacting the seller.\n\nNote: These tools are designed to assist during property exploration and should not be considered official government surveys or legal property records.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.eco_outlined, 'Crop Marketplace'),
                const SizedBox(height: 8),
                Text(
                  'In addition to agricultural land, AgroZemex provides a marketplace where farmers and sellers can showcase crop harvests. Users can publish crop listings, upload harvest photographs, specify available quantity, set pricing, and connect directly with interested buyers.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Trust, Privacy & Values Card
            _buildCard(
              children: [
                _buildSectionHeader(Icons.shield_outlined, 'Safety and Trust'),
                const SizedBox(height: 8),
                _buildBulletList([
                  'Secure account authentication & verified contact info',
                  'Protected seller contact visibility & role-based controls',
                  'Data encryption during transmission & intelligent access controls',
                  'Abuse reporting mechanisms & privacy-focused user controls',
                ]),
                const Divider(height: 28),

                _buildSectionHeader(Icons.privacy_tip_outlined, 'User Privacy'),
                const SizedBox(height: 8),
                Text(
                  'We respect your privacy. Personal information is collected only for legitimate platform operations, including account creation, authentication, listing management, customer support, and service improvement.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.favorite_border_rounded, 'Community Values'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex is built on the principles of Transparency, Integrity, Innovation, Respect, Fairness, Responsibility, Accessibility, and Continuous Improvement.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Responsibility Disclaimer Card
            _buildCard(
              children: [
                _buildSectionHeader(Icons.gavel_outlined, 'Our Responsibility'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex operates as a technology platform that facilitates communication and discovery between users. We do not act as a real estate broker, property dealer, legal advisor, financial advisor, government authority, land survey agency, or agricultural consultant.\n\nUsers remain solely responsible for independently verifying property ownership, land records, legal documentation, crop quality, pricing, measurements, and all transaction details before entering into any agreement.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Contact & Commitment Card
            _buildCard(
              children: [
                _buildSectionHeader(Icons.handshake_outlined, 'Our Commitment'),
                const SizedBox(height: 8),
                Text(
                  'We are committed to building a reliable, secure, and easy-to-use platform that supports farmers, landowners, buyers, agricultural businesses, and rural communities. Every update, feature, and improvement is guided by our commitment to delivering a better digital experience while promoting responsible and transparent agricultural transactions.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.mail_outline_rounded, 'Contact Us'),
                const SizedBox(height: 8),
                Text(
                  'If you have any questions, suggestions, feedback, or require assistance, we encourage you to get in touch with us.',
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
                              'Support Email: support@agrozeme.com',
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
            const SizedBox(height: 32),

            // Thank You Footer
            Center(
              child: Column(
                children: [
                  Text(
                    'Thank You for Choosing AgroZemex',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AgroZemexTokens.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Together toward a smarter, more transparent future for agriculture.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '• ',
                style: GoogleFonts.inter(
                  fontSize: 14,
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
