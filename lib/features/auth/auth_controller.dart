import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:youpage/features/grades/data/demo_data.dart';
import 'package:youpage/features/grades/data/edupage_client.dart';
import 'package:youpage/features/grades/domain/grade.dart';

enum AuthStatus { loading, loggedOut, loggedIn }

class AuthState {
  const AuthState({
    required this.status,
    this.demo = false,
    this.busy = false,
    this.error,
  });

  final AuthStatus status;
  final bool demo;
  final bool busy;
  final String? error;
}

final edupageClientProvider = Provider<EduPageClient>((ref) => EduPageClient());

class AuthNotifier extends Notifier<AuthState> {
  static const _storage = FlutterSecureStorage();

  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthState(status: AuthStatus.loading);
  }

  EduPageClient get _client => ref.read(edupageClientProvider);

  Future<void> _restore() async {
    try {
      final school = await _storage.read(key: 'school');
      final user = await _storage.read(key: 'user');
      final pass = await _storage.read(key: 'pass');
      if (school == null || user == null || pass == null) {
        state = const AuthState(status: AuthStatus.loggedOut);
        return;
      }
      await _client.login(school, user, pass);
      state = const AuthState(status: AuthStatus.loggedIn);
    } catch (e) {
      state = AuthState(status: AuthStatus.loggedOut, error: e.toString());
    }
  }

  Future<void> login(String school, String user, String pass) async {
    state = const AuthState(status: AuthStatus.loggedOut, busy: true);
    try {
      await _client.login(school, user, pass);
      await _storage.write(key: 'school', value: EduPageClient.normalizeSchool(school));
      await _storage.write(key: 'user', value: user);
      await _storage.write(key: 'pass', value: pass);
      state = const AuthState(status: AuthStatus.loggedIn);
    } catch (e) {
      state = AuthState(status: AuthStatus.loggedOut, error: e.toString());
    }
  }

  void startDemo() {
    state = const AuthState(status: AuthStatus.loggedIn, demo: true);
  }

  Future<void> logout() async {
    await _storage.deleteAll();
    _client.clear();
    state = const AuthState(status: AuthStatus.loggedOut);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

final gradesProvider = FutureProvider.autoDispose<List<Grade>>((ref) async {
  final demo = ref.watch(authProvider.select((s) => s.demo));
  if (demo) return demoGrades();
  return ref.read(edupageClientProvider).fetchGrades();
});
