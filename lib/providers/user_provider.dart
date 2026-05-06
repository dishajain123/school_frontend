import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/user/user_model.dart';
import '../data/repositories/user_repository.dart';

class UserNotifier extends AsyncNotifier<UserModel?> {
  @override
  Future<UserModel?> build() async {
    return null;
  }

  Future<void> load() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userRepositoryProvider).getMe(),
    );
  }

  Future<void> updatePhone(String phone) async {
    final previous = state;
    try {
      final updated =
          await ref.read(userRepositoryProvider).updateMe(phone: phone);
      state = AsyncData(updated);
    } catch (e) {
      state = previous;
      rethrow;
    }
  }

  Future<String?> uploadPhoto(File file) async {
    final current = state.valueOrNull;
    if (current == null) return null;
    final result = await ref
        .read(userRepositoryProvider)
        .uploadProfilePhoto(current.id, file);
    final photoUrl = result['profile_photo_url'] as String?;
    state = AsyncData(current.copyWith(
      profilePhotoKey: result['profile_photo_key'] as String?,
      profilePhotoUrl: photoUrl,
    ));
    return photoUrl;
  }
}

final userNotifierProvider =
    AsyncNotifierProvider<UserNotifier, UserModel?>(() => UserNotifier());