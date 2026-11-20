import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static Future<void> init() async {
    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      // In development or when .env is not present, use defaults or fallback
    }
  }

  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? 'https://your-project-id.supabase.co';

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? 'your-supabase-anon-key';

  static String get appEnv => dotenv.env['APP_ENV'] ?? 'development';

  static String get firebaseProjectId =>
      dotenv.env['FIREBASE_PROJECT_ID'] ?? '';

  static bool get isConfigured =>
      supabaseUrl != 'https://your-project-id.supabase.co' &&
      supabaseAnonKey != 'your-supabase-anon-key';
}
