import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/public_provider.dart';
import '../models/car.dart';
import '../models/marketing.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class PublicLandingScreen extends ConsumerStatefulWidget {
  const PublicLandingScreen({super.key});

  @override
  ConsumerState<PublicLandingScreen> createState() => _PublicLandingScreenState();
}

class _PublicLandingScreenState extends ConsumerState<PublicLandingScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      // Determine subdomain from URL in real scenario
      // For now using 'demo'
      ref.read(publicProvider.notifier).fetchLandingData('demo');
    });
  }

  @override
  Widget build(BuildContext context) {
    final publicState = ref.watch(publicProvider);
    final branding = publicState.branding;
    final lp = publicState.landingPage;
    final primaryColor = _parseColor(branding?.primaryColor ?? '#3b82f6');

    if (publicState.isLoading && publicState.landingPage == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Navbar
          SliverAppBar(
            floating: true,
            title: Row(
              children: [
                if (branding?.logoUrl != null && branding!.logoUrl.isNotEmpty)
                  Image.network(branding.logoUrl, height: 32)
                else
                  Icon(Icons.directions_car, color: primaryColor),
                const SizedBox(width: 12),
                Text(
                  'CarRental',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () {}, child: const Text('Fleet')),
              TextButton(onPressed: () {}, child: const Text('About')),
              TextButton(onPressed: () {}, child: const Text('Contact')),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {}, // Login is handled via URL or separate button
                  child: const Text('Booking'),
                ),
              ),
            ],
            backgroundColor: Colors.white,
            elevation: 0,
          ),

          // Hero Section
          SliverToBoxAdapter(
            child: _buildHero(lp, primaryColor),
          ),

          // Features Section
          if (lp?.showFeatures ?? true)
            SliverToBoxAdapter(
              child: _buildFeatures(primaryColor),
            ),

          // Fleet Section
          if (lp?.showFleet ?? true)
            SliverPadding(
              padding: const EdgeInsets.all(40),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Our Fleet',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Choose from our wide range of premium vehicles'),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

          if (lp?.showFleet ?? true)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 400,
                  mainAxisSpacing: 24,
                  crossAxisSpacing: 24,
                  childAspectRatio: 0.8,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final car = publicState.cars[index];
                    return _buildCarCard(context, car, primaryColor);
                  },
                  childCount: publicState.cars.length,
                ),
              ),
            ),

          // Footer
          SliverPadding(
            padding: const EdgeInsets.all(80),
            sliver: SliverToBoxAdapter(
              child: _buildFooter(lp, branding, primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHero(LandingPage? lp, Color primaryColor) {
    return Container(
      height: 600,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        image: lp?.heroBackgroundUrl != null
            ? DecorationImage(
                image: NetworkImage(lp!.heroBackgroundUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              )
            : null,
      ),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lp?.heroTitle ?? 'Welcome to Our Car Rental',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 56,
                  fontWeight: FontWeight.w800,
                  color: lp?.heroBackgroundUrl != null ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                lp?.heroSubtitle ?? 'Find the perfect car for your journey',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  color: lp?.heroBackgroundUrl != null ? Colors.white.withOpacity(0.9) : Colors.black54,
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
                  textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {},
                child: Text(lp?.heroCtaText ?? 'Browse Fleet'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatures(Color primaryColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildFeatureItem(Icons.verified_user, 'Secure Booking', 'Easy and secure reservation process', primaryColor),
          _buildFeatureItem(Icons.support_agent, '24/7 Support', 'Dedicated team at your service', primaryColor),
          _buildFeatureItem(Icons.price_check, 'Best Prices', 'Competitive rates with no hidden fees', primaryColor),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String desc, Color color) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(desc, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _buildCarCard(BuildContext context, Car car, Color primaryColor) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: car.imageUrl != null
                ? Image.network(car.imageUrl!, fit: BoxFit.cover, width: double.infinity)
                : Container(color: Colors.grey.shade200, child: const Icon(Icons.directions_car, size: 48)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${car.brand} ${car.model}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text('${car.year} | ${car.fuelType ?? 'Gasoline'}', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${car.pricePerDay.toStringAsFixed(0)} MAD',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => _showBookingDialog(context, car, primaryColor),
                      child: const Text('Book Now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(LandingPage? lp, Branding? branding, Color primaryColor) {
    return Column(
      children: [
        const Divider(),
        const SizedBox(height: 48),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CarRental',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    lp?.aboutText ?? 'Premium car rental services for your personal and business needs.',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Text(lp?.contactPhone ?? '', style: TextStyle(color: Colors.grey.shade600)),
                  Text(lp?.contactEmail ?? '', style: TextStyle(color: Colors.grey.shade600)),
                  Text(lp?.contactAddress ?? '', style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const SizedBox(width: 40),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Follow Us', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildSocialIcon(Icons.facebook, lp?.socialFacebook),
                      _buildSocialIcon(Icons.camera_alt, lp?.socialInstagram),
                      _buildSocialIcon(Icons.chat_bubble, lp?.socialTiktok),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 48),
        Text(
          '© ${DateTime.now().year} CarRental System. All rights reserved.',
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildSocialIcon(IconData icon, String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: IconButton(
        icon: Icon(icon),
        onPressed: () {},
      ),
    );
  }

  void _showBookingDialog(BuildContext context, Car car, Color primaryColor) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final messageController = TextEditingController();
    DateTime pickupDate = DateTime.now().add(const Duration(days: 1));
    DateTime returnDate = DateTime.now().add(const Duration(days: 3));

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Book ${car.brand} ${car.model}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                ),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email Address'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pickup Date', style: TextStyle(fontSize: 12)),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: pickupDate,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) setState(() => pickupDate = date);
                            },
                            child: Text(DateFormat('yyyy-MM-dd').format(pickupDate)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Return Date', style: TextStyle(fontSize: 12)),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: returnDate,
                                firstDate: pickupDate.add(const Duration(days: 1)),
                                lastDate: DateTime.now().add(const Duration(days: 365)),
                              );
                              if (date != null) setState(() => returnDate = date);
                            },
                            child: Text(DateFormat('yyyy-MM-dd').format(returnDate)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(labelText: 'Message (Optional)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                if (nameController.text.isEmpty || phoneController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill in your name and phone')),
                  );
                  return;
                }

                final data = {
                  'car_id': car.id,
                  'customer_name': nameController.text,
                  'customer_phone': phoneController.text,
                  'customer_email': emailController.text,
                  'pickup_date': pickupDate.toIso8601String(),
                  'return_date': returnDate.toIso8601String(),
                  'message': messageController.text,
                  'tenant_id': car.tenantId, // Car should have a tenantId field
                };

                try {
                  await ref.read(publicProvider.notifier).submitBookingRequest(data);
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking request sent successfully! We will contact you soon.')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Send Request'),
            ),
          ],
        ),
      ),
    );
  }

  Color _parseColor(String hex) {
    try {
      if (hex.startsWith('#')) hex = hex.substring(1);
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return Colors.blue;
    }
  }
}
