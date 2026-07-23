import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/agrozemex_tokens.dart';

/// Policies Screen displaying comprehensive Privacy Policy and platform guidelines.
class PoliciesScreen extends StatelessWidget {
  const PoliciesScreen({super.key});

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@agrozeme.com',
      queryParameters: {
        'subject': 'Privacy Policy Inquiry',
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
          'Policies',
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
                          Icons.policy_outlined,
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
                              'Privacy Policy',
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'AgroZemex Privacy & Protection Guidelines',
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
                    'Welcome to AgroZemex ("AgroZemex," "we," "our," or "us"). Your privacy is important to us. This Privacy Policy explains how we collect, use, store, share, and protect your personal information when you use our mobile application, website, and related services.',
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

            // Section 1: Information We Collect
            _buildCard(
              children: [
                _buildSectionHeader(Icons.dataset_outlined, '1. Information We Collect'),
                const SizedBox(height: 8),
                Text(
                  'Depending on how you use the Platform, we may collect:',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                _buildSubTitle('Personal Information'),
                _buildBulletList(['Full name, display name & profile photograph', 'Email address & mobile phone number', 'User role (Buyer, Seller, Admin)']),
                const SizedBox(height: 10),
                _buildSubTitle('Account Information'),
                _buildBulletList(['Firebase Authentication User ID', 'Login provider (Email, Google, Apple, Phone)', 'Account creation date & login timestamps']),
                const SizedBox(height: 10),
                _buildSubTitle('Listing Information'),
                _buildBulletList(['Property title, description, price, quantity, area info', 'Uploaded photographs & property specifications', 'Property location, boundary coordinates & search keywords']),
                const SizedBox(height: 10),
                _buildSubTitle('Location Information'),
                _buildBulletList(['Current GPS location & approximate location', 'Property coordinates & map interaction data']),
                const SizedBox(height: 10),
                _buildSubTitle('Device & Booking Information'),
                _buildBulletList(['Device model, operating system, app version, crash logs', 'Buyer/Seller details, visit dates & booking history']),
              ],
            ),
            const SizedBox(height: 16),

            // Section 2 & 3: Usage & Location
            _buildCard(
              children: [
                _buildSectionHeader(Icons.settings_suggest_outlined, '2. How We Use Your Information'),
                const SizedBox(height: 8),
                _buildBulletList([
                  'Create and manage user accounts and authenticate users securely.',
                  'Display your listings and process property & crop marketplace data.',
                  'Enable communication between buyers and sellers & schedule site visits.',
                  'Provide customer support, improve performance, and detect fraud or abuse.',
                  'Protect user accounts, maintain platform security & comply with legal obligations.',
                ]),
                const Divider(height: 28),

                _buildSectionHeader(Icons.location_on_outlined, '3. Location Permissions'),
                const SizedBox(height: 8),
                Text(
                  'Location access is requested only to support features such as viewing nearby listings, drawing land boundaries, showing property locations, and calculating approximate land area. You may disable location access at any time through device settings.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 4 & 5: Content & Firebase
            _buildCard(
              children: [
                _buildSectionHeader(Icons.cloud_upload_outlined, '4. Images and Uploaded Content'),
                const SizedBox(height: 8),
                Text(
                  'Images uploaded by users are stored securely using cloud storage services. Users are solely responsible for ensuring they have the legal right to upload photographs. AgroZemex reserves the right to remove content that violates policies or law.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.local_fire_department_outlined, '5. Firebase Services'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex uses Firebase services (Auth, Firestore, Storage, FCM, Crashlytics, Analytics). These services process data in accordance with Google\'s privacy practices.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 6 & 7 & 8: Security, Sharing & Seller Contact
            _buildCard(
              children: [
                _buildSectionHeader(Icons.lock_outline_rounded, '6. Data Storage and Security'),
                const SizedBox(height: 8),
                Text(
                  'We implement reasonable technical and organizational safeguards including secure authentication, encrypted data transmission (HTTPS/TLS), access controls, and secure cloud infrastructure.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.share_outlined, '7. Sharing of Information'),
                const SizedBox(height: 8),
                Text(
                  'We do not sell or rent your personal information. We share information only with necessary service providers, when required by law, to investigate security incidents, or to protect rights and safety.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.contact_phone_outlined, '8. Seller Contact Information'),
                const SizedBox(height: 8),
                Text(
                  'Seller contact information is displayed only after platform verification or authentication requirements are met. Misuse of contact info for spam or harassment is strictly prohibited.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 9 to 13: Responsibilities, Rights & Third-Parties
            _buildCard(
              children: [
                _buildSectionHeader(Icons.assignment_ind_outlined, '9. User Responsibilities'),
                const SizedBox(height: 8),
                _buildBulletList([
                  'Providing accurate information & protecting account credentials.',
                  'Maintaining account security & updating inaccurate info promptly.',
                  'Using the Platform lawfully and respectfully.',
                ]),
                const Divider(height: 28),

                _buildSectionHeader(Icons.child_care_outlined, '10. Children\'s Privacy'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex is not intended for children under applicable legal age. We do not knowingly collect personal information from children.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.history_outlined, '11. Data Retention & 12. Your Rights'),
                const SizedBox(height: 8),
                Text(
                  'We retain personal info only as long as necessary to provide services and meet legal obligations. You have the right to access, update, or request deletion of your account and personal information.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.extension_outlined, '13. Third-Party Services'),
                const SizedBox(height: 8),
                Text(
                  'AgroZemex integrates with third parties including Firebase, Google Sign-In, Apple Sign-In, Mapbox, and device communication services (Phone, SMS, WhatsApp). Third-party services are governed by their own privacy policies.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Section 14, 15, 16: Changes, Contact & Consent
            _buildCard(
              children: [
                _buildSectionHeader(Icons.update_outlined, '14. Changes to Policy & 16. Consent'),
                const SizedBox(height: 8),
                Text(
                  'We may update this Privacy Policy periodically. By creating an account or using AgroZemex, you acknowledge that you have read, understood, and agreed to this Privacy Policy.',
                  style: GoogleFonts.inter(fontSize: 13, height: 1.5, color: AgroZemexTokens.onSurfaceVariant),
                ),
                const Divider(height: 28),

                _buildSectionHeader(Icons.mail_outline_rounded, '15. Contact Us'),
                const SizedBox(height: 8),
                Text(
                  'If you have questions or requests regarding this Privacy Policy or your personal information, please contact us:',
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
            const SizedBox(height: 32),

            Center(
              child: Text(
                'AgroZemex Privacy Policy • support@agrozeme.com',
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

  Widget _buildSubTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: AgroZemexTokens.primary,
      ),
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
