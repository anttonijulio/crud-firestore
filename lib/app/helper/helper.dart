import 'package:connectivity_plus/connectivity_plus.dart';

class Helper {
  Helper._private();

  static String generateID(String text) {
    final cleanedInput = text.replaceAll(' ', '').toLowerCase();
    final truncatedInput =
        cleanedInput.length > 5 ? cleanedInput.substring(0, 5) : cleanedInput;
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '$truncatedInput-$timestamp'; // output: 5 digit karakter pertama - {timestamp}
  }

  static Stream<List<ConnectivityResult>> listenConnection() {
    return Connectivity().onConnectivityChanged;
  }

  static Future<bool> availableConnection() async {
    final r = await Connectivity().checkConnectivity();

    return r.contains(ConnectivityResult.mobile) ||
        r.contains(ConnectivityResult.wifi) ||
        r.contains(ConnectivityResult.vpn);
  }
}
