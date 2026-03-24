import 'package:envied/envied.dart';

part 'env.g.dart';

/// Environment variables loaded from .env file.
/// Run `dart run build_runner build` to regenerate env.g.dart after changes.
@Envied(path: '.env')
abstract class Env {
  @EnviedField(varName: 'SUPABASE_URL')
  static const String supabaseUrl = _Env.supabaseUrl;

  @EnviedField(varName: 'SUPABASE_ANON_KEY')
  static const String supabaseAnonKey = _Env.supabaseAnonKey;

  @EnviedField(varName: 'GOOGLE_WEB_CLIENT_ID')
  static const String googleWebClientId = _Env.googleWebClientId;

  @EnviedField(varName: 'GROQ_API_KEY')
  static const String groqApiKey = _Env.groqApiKey;
}
