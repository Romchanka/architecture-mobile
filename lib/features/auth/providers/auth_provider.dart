import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/auth_models.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserInfo? user;
  final String? error;

  AuthState({this.isAuthenticated = false, this.isLoading = false, this.user, this.error});

  AuthState copyWith({bool? isAuthenticated, bool? isLoading, UserInfo? user, String? error}) =>
      AuthState(
        isAuthenticated: isAuthenticated ?? this.isAuthenticated,
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
        error: error,
      );
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(AuthState()) {
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final hasToken = await SecureStorage.hasTokens();
    if (hasToken) {
      try {
        final res = await api.get('/auth/me');
        state = AuthState(
          isAuthenticated: true,
          user: UserInfo.fromJson(res.data),
        );
      } catch (_) {
        await SecureStorage.clearTokens();
        state = AuthState();
      }
    }
  }

  Future<bool> login(String phone, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await api.post('/auth/login', data: LoginRequest(phone: phone, password: password).toJson());
      final loginRes = LoginResponse.fromJson(res.data);
      await SecureStorage.saveTokens(accessToken: loginRes.token, refreshToken: loginRes.refreshToken);

      // Fetch user info
      final userRes = await api.get('/auth/me');
      state = AuthState(isAuthenticated: true, user: UserInfo.fromJson(userRes.data));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Неверный телефон или пароль');
      return false;
    }
  }

  Future<bool> register(RegisterRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await api.post('/auth/register', data: request.toJson());
      final loginRes = LoginResponse.fromJson(res.data);
      await SecureStorage.saveTokens(accessToken: loginRes.token, refreshToken: loginRes.refreshToken);

      final userRes = await api.get('/auth/me');
      state = AuthState(isAuthenticated: true, user: UserInfo.fromJson(userRes.data));
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Ошибка регистрации. Возможно, номер уже занят.');
      return false;
    }
  }

  Future<void> logout() async {
    await SecureStorage.clearTokens();
    state = AuthState();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) => AuthNotifier());
