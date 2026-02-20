class AppConstants {
  static const String host = "waterparty.onrender.com";
  static const String apiBase = "https://$host";
  static const String wsBase = "wss://$host/ws";
  
  static String assetUrl(String hash) => "$apiBase/assets/$hash";
}
