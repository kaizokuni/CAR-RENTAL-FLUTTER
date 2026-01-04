// API Configuration
class ApiConfig {
  // Change this to your backend URL
  static const String baseUrl = 'http://localhost:8080';
  static const String apiVersion = '/api/v1';
  
  // Auth endpoints
  static const String login = '$apiVersion/auth/login';
  static const String me = '$apiVersion/me';
  
  // Protected endpoints
  static const String cars = '$apiVersion/cars';
  static const String bookings = '$apiVersion/bookings';
  static const String customers = '$apiVersion/customers';
  static const String staff = '$apiVersion/staff';
  static const String roles = '$apiVersion/roles';
  static const String branding = '$apiVersion/branding';
  static const String landingPage = '$apiVersion/landing-page';
  static const String notifications = '$apiVersion/notifications';
  static const String financials = '$apiVersion/financials';
  static const String bookingRequests = '$apiVersion/booking-requests';
  
  // Admin endpoints
  static const String adminTenants = '$apiVersion/admin/tenants';
  static const String adminStats = '$apiVersion/admin/stats';
  
  // Public endpoints
  static const String publicLanding = '$apiVersion/public/landing';
  static const String publicCars = '$apiVersion/public/cars';
  
  static String fullUrl(String endpoint) => '$baseUrl$endpoint';
}
