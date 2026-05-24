import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/services/app_firestore_service.dart';

class ChatRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> userChats(String userId) {
    return AppFirestoreService.chats
        .where('memberIds', arrayContains: userId)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> chatMessages(String chatId) {
    return AppFirestoreService.chatMessages(
      chatId,
    ).orderBy('createdAt', descending: true).snapshots();
  }

  Future<void> deletePrivateChat({
    required String chatId,
    required String userId,
  }) {
    return AppFirestoreService.chats.doc(chatId).update({
      'memberIds': [],
      'deletedFor': [],
      'isDeleted': true,
      'deletedBy': userId,
      'deletedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendMessage({
    required String chatId,
    required User user,
    required String text,
  }) async {
    final senderName = user.displayName ?? user.email ?? 'Người dùng';

    await AppFirestoreService.chatMessages(chatId).add({
      'senderId': user.uid,
      'senderName': senderName,
      'senderEmail': user.email ?? '',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await AppFirestoreService.chats.doc(chatId).update({
      'lastMessage': text,
      'lastSenderId': user.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
