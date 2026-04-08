import '../services/supabase_bootstrap.dart';
import 'demo_maraude_repository.dart';
import 'maraude_repository.dart';
import 'supabase_maraude_repository.dart';

class AppRepositories {
  const AppRepositories._();

  static MaraudeRepository get maraudes {
    if (SupabaseBootstrap.isInitialized) {
      return SupabaseMaraudeRepository();
    }

    return DemoMaraudeRepository.instance;
  }
}
