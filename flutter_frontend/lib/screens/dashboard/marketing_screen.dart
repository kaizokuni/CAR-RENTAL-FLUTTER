import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/marketing_provider.dart';
import '../../models/marketing.dart';

class MarketingScreen extends ConsumerStatefulWidget {
  const MarketingScreen({super.key});

  @override
  ConsumerState<MarketingScreen> createState() => _MarketingScreenState();
}

class _MarketingScreenState extends ConsumerState<MarketingScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _heroTitleController = TextEditingController();
  final _heroSubtitleController = TextEditingController();
  final _aboutTextController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => ref.read(marketingProvider.notifier).fetchMarketingData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroTitleController.dispose();
    _heroSubtitleController.dispose();
    _aboutTextController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _syncControllers(LandingPage? lp) {
    if (lp != null) {
      _heroTitleController.text = lp.heroTitle;
      _heroSubtitleController.text = lp.heroSubtitle;
      _aboutTextController.text = lp.aboutText;
      _phoneController.text = lp.contactPhone;
      _emailController.text = lp.contactEmail;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketingProvider);
    
    // Sync controllers once data is loaded
    if (state.landingPage != null && _heroTitleController.text.isEmpty) {
      _syncControllers(state.landingPage);
    }

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Marketing Hub',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your public presence and branding',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withAlpha(153),
                          ),
                    ),
                  ],
                ),
                if (state.landingPage != null)
                  Row(
                    children: [
                      Text(
                        state.landingPage!.isLive ? 'SITE LIVE' : 'SITE OFFLINE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: state.landingPage!.isLive ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: state.landingPage!.isLive,
                        onChanged: (value) {
                          ref.read(marketingProvider.notifier).toggleLive(value);
                        },
                      ),
                    ],
                  ),
              ],
            ),
          ),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: 'Branding'),
                Tab(text: 'Landing Page'),
              ],
            ),
          ),

          Expanded(
            child: state.isLoading && state.branding == null
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBrandingTab(state),
                      _buildLandingPageTab(state),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandingTab(MarketingState state) {
    final branding = state.branding;
    if (branding == null) return const Center(child: Text('No branding data found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Visual Identity', 'Customize your logo and colors'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Logo Placeholder
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
                        backgroundImage: branding.logoUrl.isNotEmpty ? NetworkImage(branding.logoUrl) : null,
                        child: branding.logoUrl.isEmpty ? const Icon(Icons.business, size: 40) : null,
                      ),
                      const SizedBox(width: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              // Logo upload logic would go here
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Logo upload feature coming soon')),
                              );
                            },
                            icon: const Icon(Icons.upload),
                            label: const Text('Change Logo'),
                          ),
                          const SizedBox(height: 8),
                          const Text('SVG, PNG or JPG (max 2MB)'),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 48),
                  // Color Pickers (Simplified as text fields for hex codes)
                  _buildColorSetting(
                    'Primary Color',
                    branding.primaryColor,
                    (val) => _updateBrandingField('primary_color', val),
                  ),
                  const SizedBox(height: 16),
                  _buildColorSetting(
                    'Secondary Color',
                    branding.secondaryColor,
                    (val) => _updateBrandingField('secondary_color', val),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandingPageTab(MarketingState state) {
    final lp = state.landingPage;
    if (lp == null) return const Center(child: Text('No landing page data found'));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader('Hero Section', 'The first thing visitors see'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _heroTitleController,
                    decoration: const InputDecoration(labelText: 'Hero Title'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _heroSubtitleController,
                    decoration: const InputDecoration(labelText: 'Hero Subtitle'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _saveLandingPage(lp),
                      child: const Text('Save Hero Settings'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Contact & Links', 'How customers can reach you'),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Contact Phone'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Contact Email'),
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _saveLandingPage(lp),
                      child: const Text('Save Contact Info'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        Text(
          subtitle,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withAlpha(153)),
        ),
      ],
    );
  }

  Widget _buildColorSetting(String label, String value, Function(String) onSave) {
    final controller = TextEditingController(text: value);
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _parseColor(value),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              suffixIcon: IconButton(
                icon: const Icon(Icons.check),
                onPressed: () => onSave(controller.text),
              ),
            ),
          ),
        ),
      ],
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

  void _updateBrandingField(String field, String value) {
    final branding = ref.read(marketingProvider).branding;
    if (branding == null) return;

    final data = branding.toJson();
    data[field] = value;
    ref.read(marketingProvider.notifier).updateBranding(data);
  }

  void _saveLandingPage(LandingPage lp) {
    final data = lp.toJson();
    data['hero_title'] = _heroTitleController.text;
    data['hero_subtitle'] = _heroSubtitleController.text;
    data['contact_phone'] = _phoneController.text;
    data['contact_email'] = _emailController.text;

    ref.read(marketingProvider.notifier).updateLandingPage(data);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Landing page settings saved')),
    );
  }
}
