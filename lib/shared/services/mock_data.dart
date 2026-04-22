import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class MockData {
  MockData._();

  static Future<void> saveRole(String role) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('user_role', role);
  }

  static Future<String?> getRole() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('user_role');
  }

  static Future<void> saveToken(String token) async {
    final p = await SharedPreferences.getInstance();
    await p.setString('auth_token', token);
  }

  static Future<String?> getToken() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('auth_token');
  }

  static Future<void> setOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('onboarding_done', true);
  }

  static Future<bool> isOnboardingDone() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool('onboarding_done') ?? false;
  }

  static Future<void> logout() async {
    final p = await SharedPreferences.getInstance();
    await p.remove('auth_token');
    await p.remove('user_role');
  }

  static List<NotificationModel> get notifications => [
    NotificationModel(id:'n1', title:'Booking Confirmed', body:'ProTech Auto confirmed your Oil Change for Dec 22', type:'booking', time: DateTime.now().subtract(const Duration(hours: 1))),
    NotificationModel(id:'n2', title:'Service Reminder', body:'Your brake inspection is due in 500 miles', type:'reminder', time: DateTime.now().subtract(const Duration(hours: 4))),
    NotificationModel(id:'n3', title:'🎉 Special Offer', body:'Get 30% off all AC services this week!', type:'promo', time: DateTime.now().subtract(const Duration(days: 1)), isRead: true),
    NotificationModel(id:'n4', title:'Job Completed', body:'Your vehicle is ready for pickup at ProTech Auto', type:'booking', time: DateTime.now().subtract(const Duration(days: 2)), isRead: true),
  ];
}
