import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/view_models/base_view_model.dart';
import '../repositories/chat_repository.dart';

class MessagesViewModel extends BaseViewModel {
  MessagesViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  final ChatRepository _chatRepository;

  Stream<QuerySnapshot<Map<String, dynamic>>> userChats(String userId) {
    return _chatRepository.userChats(userId);
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> visibleChats({
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    required String userId,
  }) {
    return docs.where((doc) {
      final data = doc.data();
      final isGroup = data['type'] == ChatType.group;
      final deletedFor = List<String>.from(data['deletedFor'] ?? []);
      return data['isDeleted'] != true &&
          (isGroup || !deletedFor.contains(userId));
    }).toList()
      ..sort((left, right) {
        final leftGroup = left.data()['type'] == ChatType.group;
        final rightGroup = right.data()['type'] == ChatType.group;
        if (leftGroup != rightGroup) return leftGroup ? -1 : 1;

        final leftUpdatedAt = timestampMillis(left.data()['updatedAt']);
        final rightUpdatedAt = timestampMillis(right.data()['updatedAt']);
        return rightUpdatedAt.compareTo(leftUpdatedAt);
      });
  }

  Future<bool> deletePrivateChat({
    required String chatId,
    required String userId,
  }) {
    return runBusyAction(
      () => _chatRepository.deletePrivateChat(
        chatId: chatId,
        userId: userId,
      ),
    );
  }

  int timestampMillis(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }
}
