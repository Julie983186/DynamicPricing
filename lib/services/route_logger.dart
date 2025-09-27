import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveCurrentRoute(String routeName) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('last_route', routeName);
}
