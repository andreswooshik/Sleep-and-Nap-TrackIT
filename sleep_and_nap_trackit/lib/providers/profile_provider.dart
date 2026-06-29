import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/profile.dart';
import '../services/profile_service.dart';
import 'service_providers.dart';

/// Loads the signed-in user's profile from Supabase.
final profileProvider = FutureProvider<Profile?>((ref) async {
  return ref.watch(profileServiceProvider).getProfile();
});

/// Handles preference edits (sleep goal, nap habit, notifications) and
/// persists them through [ProfileService]. Keeps mutation logic out of views.
class ProfileController {
  ProfileController(this._ref);

  final Ref _ref;

  Future<void> update(Profile updated) async {
    await _ref.read(profileServiceProvider).updateProfile(updated);
    _ref.invalidate(profileProvider);
  }
}

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});
