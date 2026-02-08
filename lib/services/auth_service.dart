import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client.auth.onAuthStateChange.map((event) => event.session?.user);
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return null;

  final client = ref.watch(supabaseClientProvider);
  final response = await client
      .from('profiles')
      .select()
      .eq('id', authUser.id)
      .single();

  return UserModel.fromJson(response);
});

/// Provider to get all users for task assignment
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final response = await client.from('profiles').select().order('name');

  return (response as List).map((e) => UserModel.fromJson(e)).toList();
});

class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  /// Sign in with email and password
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    // Profile is automatically created by trigger on auth.users
    // We pass name in user metadata for the trigger to use
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name}, // This is passed to raw_user_meta_data
    );

    return response;
  }

  /// Sign out
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Get current user profile
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _client.auth.currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return UserModel.fromJson(response);
  }

  /// Update user role (admin only)
  Future<void> updateUserRole(String userId, UserRole role) async {
    await _client
        .from('profiles')
        .update({'role': role == UserRole.admin ? 'admin' : 'member'})
        .eq('id', userId);
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return AuthService(client);
});
