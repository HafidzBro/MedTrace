import 'package:medtrace/data/models/profile_model.dart';
import 'package:medtrace/services/supabase/supabase_service_context.dart';

class ProfileService {
  final SupabaseServiceContext context;

  const ProfileService(this.context);

  Future<UserModel> getByAuthUserId(String userId) async {
    final response = await context.client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .single();

    return UserModel.fromJson(response);
  }

  Future<UserModel> getByProfileId(String profileId) async {
    final response = await context.client
        .from('profiles')
        .select()
        .eq('profile_id', profileId)
        .single();

    return UserModel.fromJson(response);
  }

  Future<UserModel> updateProfile({
    required String userId,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? country,
    String? city,
    String? gender,
  }) async {
    final updateData = <String, dynamic>{};
    if (fullName != null) updateData['full_name'] = fullName;
    if (phoneNumber != null) updateData['phone'] = phoneNumber;
    if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

    if (updateData.isNotEmpty) {
      await context.client.from('profiles').update(updateData).eq(
            'user_id',
            userId,
          );
    }

    if (gender != null) {
      final profile = await getByAuthUserId(userId);
      await context.client
          .from('patients')
          .update({'gender': gender}).eq('profile_id', profile.profileId);
    }

    return getByAuthUserId(userId);
  }
}
