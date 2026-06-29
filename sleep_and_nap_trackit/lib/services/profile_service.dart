import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';

abstract class ProfileService {
  Future<void> createProfile(Profile profile);
  Future<Profile?> getProfile();
  Future<void> updateProfile(Profile profile);
}

class SupabaseProfileService implements ProfileService {
  SupabaseClient get _client => Supabase.instance.client;

  @override
  Future<void> createProfile(Profile profile) async {
    await _client.from('profiles').insert(profile.toJson());
  }

  @override
  Future<Profile?> getProfile() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final data = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (data == null) return null;
    return Profile.fromJson(data);
  }

  @override
  Future<void> updateProfile(Profile profile) async {
    await _client.from('profiles').update(profile.toJson()).eq('id', profile.id);
  }
}

class MockProfileService implements ProfileService {
  MockProfileService([this._profile]);

  Profile? _profile;

  @override
  Future<void> createProfile(Profile profile) async {
    _profile = profile;
  }

  @override
  Future<Profile?> getProfile() async => _profile;

  @override
  Future<void> updateProfile(Profile profile) async {
    _profile = profile;
  }
}
