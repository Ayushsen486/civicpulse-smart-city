import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../data/auth_repository.dart';
import '../data/google_sign_in_service.dart';
import '../domain/user_model.dart';

final authControllerProvider =
    AsyncNotifierProvider<AuthController, UserModel?>(AuthController.new);

class AuthController extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() {
    return ref.watch(authRepositoryProvider).getCurrentUser();
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).login(email: email, password: password);
      await ref.read(themeModeProvider.notifier).applyUserThemePreference();
      return user;
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<bool> signInWithGoogle() async {
    final previousState = state;
    state = const AsyncValue.loading();
    try {
      final googleService = ref.read(googleSignInServiceProvider);
      final idToken = await googleService.getGoogleIdToken();
      if (idToken == null) {
        // User aborted/dismissed the account picker
        state = previousState;
        return false;
      }
      final user = await ref.read(authRepositoryProvider).loginWithGoogle(idToken: idToken);
      await ref.read(themeModeProvider.notifier).applyUserThemePreference();
      state = AsyncValue.data(user);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final user = await ref.read(authRepositoryProvider).register(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      await ref.read(themeModeProvider.notifier).applyUserThemePreference();
      return user;
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> logout() async {
    try {
      await ref.read(googleSignInServiceProvider).signOut();
    } catch (_) {}
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncValue.data(null);
  }
}

