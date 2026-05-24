import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/chat_repository.dart';

class ChatDetailViewModel extends BaseViewModel {
  ChatDetailViewModel({ChatRepository? chatRepository})
    : _chatRepository = chatRepository ?? ChatRepository();

  final ChatRepository _chatRepository;

  Stream<QuerySnapshot<Map<String, dynamic>>> messages(String chatId) {
    return _chatRepository.chatMessages(chatId);
  }

  Future<bool> sendMessage({
    required String chatId,
    required User user,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty || isLoading) return Future.value(false);

    return runBusyAction(
      () => _chatRepository.sendMessage(
        chatId: chatId,
        user: user,
        text: trimmed,
      ),
    );
  }
}
