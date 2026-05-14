import 'package:cloud_functions/cloud_functions.dart';

import '../shared/models/public_profile_model.dart';

class FriendFunctionsService {
  FriendFunctionsService({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  Future<PublicProfileModel?> searchUserByEmail(String email) async {
    final result = await _call('searchUserByEmail', {'email': email.trim()});
    if (result == null) return null;
    return PublicProfileModel.fromMap(result);
  }

  Future<PublicProfileModel> getPublicProfile(String uid) async {
    final result = await _call('getPublicProfile', {'uid': uid});
    if (result == null) {
      throw FirebaseFunctionsException(
        code: 'not-found',
        message: 'Profil bulunamadı',
      );
    }
    return PublicProfileModel.fromMap(result);
  }

  Future<void> sendFriendRequest(String toUid) async {
    await _call('sendFriendRequest', {'toUid': toUid});
  }

  Future<void> acceptFriendRequest(String otherUid) async {
    await _call('acceptFriendRequest', {'otherUid': otherUid});
  }

  Future<void> declineFriendRequest(String otherUid) async {
    await _call('declineFriendRequest', {'otherUid': otherUid});
  }

  Future<void> removeFriend(String otherUid) async {
    await _call('removeFriend', {'otherUid': otherUid});
  }

  Future<Map<String, dynamic>?> _call(
    String name,
    Map<String, dynamic> payload,
  ) async {
    final callable = _functions.httpsCallable(name);
    final response = await callable.call<dynamic>(payload);
    final data = response.data;
    if (data == null) return null;
    return Map<String, dynamic>.from(data);
  }
}
