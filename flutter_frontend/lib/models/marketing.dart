class Branding {
  final String tenantId;
  final String logoUrl;
  final String primaryColor;
  final String secondaryColor;
  final String? accentColor;
  final DateTime? updatedAt;

  Branding({
    required this.tenantId,
    required this.logoUrl,
    required this.primaryColor,
    required this.secondaryColor,
    this.accentColor,
    this.updatedAt,
  });

  factory Branding.fromJson(Map<String, dynamic> json) {
    return Branding(
      tenantId: json['tenant_id'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      primaryColor: json['primary_color'] ?? '#3b82f6',
      secondaryColor: json['secondary_color'] ?? '#10b981',
      accentColor: json['accent_color'],
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'accent_color': accentColor,
    };
  }
}

class LandingPage {
  final String tenantId;
  final String heroTitle;
  final String heroSubtitle;
  final String heroCtaText;
  final String? heroBackgroundUrl;
  final bool showFeatures;
  final bool showFleet;
  final bool showAbout;
  final String aboutText;
  final String contactPhone;
  final String contactEmail;
  final String contactAddress;
  final String? whatsappNumber;
  final String? socialFacebook;
  final String? socialInstagram;
  final String? socialTiktok;
  final bool isLive;
  final List<String> selectedCars;

  LandingPage({
    required this.tenantId,
    required this.heroTitle,
    required this.heroSubtitle,
    required this.heroCtaText,
    this.heroBackgroundUrl,
    required this.showFeatures,
    required this.showFleet,
    required this.showAbout,
    required this.aboutText,
    required this.contactPhone,
    required this.contactEmail,
    required this.contactAddress,
    this.whatsappNumber,
    this.socialFacebook,
    this.socialInstagram,
    this.socialTiktok,
    required this.isLive,
    required this.selectedCars,
  });

  factory LandingPage.fromJson(Map<String, dynamic> json) {
    return LandingPage(
      tenantId: json['tenant_id'] ?? '',
      heroTitle: json['hero_title'] ?? 'Welcome to Our Car Rental',
      heroSubtitle: json['hero_subtitle'] ?? 'Find the perfect car for your journey',
      heroCtaText: json['hero_cta_text'] ?? 'Browse Cars',
      heroBackgroundUrl: json['hero_background_url'],
      showFeatures: json['show_features'] ?? true,
      showFleet: json['show_fleet'] ?? true,
      showAbout: json['show_about'] ?? true,
      aboutText: json['about_text'] ?? '',
      contactPhone: json['contact_phone'] ?? '',
      contactEmail: json['contact_email'] ?? '',
      contactAddress: json['contact_address'] ?? '',
      whatsappNumber: json['whatsapp_number'],
      socialFacebook: json['social_facebook'],
      socialInstagram: json['social_instagram'],
      socialTiktok: json['social_tiktok'],
      isLive: json['is_live'] ?? false,
      selectedCars: List<String>.from(json['selected_cars'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hero_title': heroTitle,
      'hero_subtitle': heroSubtitle,
      'hero_cta_text': heroCtaText,
      'hero_background_url': heroBackgroundUrl,
      'show_features': showFeatures,
      'show_fleet': showFleet,
      'show_about': showAbout,
      'about_text': aboutText,
      'contact_phone': contactPhone,
      'contact_email': contactEmail,
      'contact_address': contactAddress,
      'whatsapp_number': whatsappNumber,
      'social_facebook': socialFacebook,
      'social_instagram': socialInstagram,
      'social_tiktok': socialTiktok,
      'is_live': isLive,
      'selected_cars': selectedCars,
    };
  }
}
