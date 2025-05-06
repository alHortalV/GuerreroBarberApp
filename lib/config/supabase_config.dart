import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  final String bucketName;
  final String projectId;
  final String baseUrl;
  final String url;
  final String anonKey;

  const SupabaseConfig({
    required this.bucketName,
    required this.projectId,
    required this.baseUrl,
    required this.url,
    required this.anonKey,
  });

  static SupabaseConfig fromEnv() {
    return SupabaseConfig(
      bucketName: dotenv.env['BUCKET_NAME'] ?? '',
      projectId: dotenv.env['PROJECT_ID'] ?? '',
      baseUrl: dotenv.env['BASE_URL'] ?? '',
      url: dotenv.env['SUPABASE_URL'] ?? '',
      anonKey: dotenv.env['SUPABASE_KEY'] ?? '',
    );
  }
}
