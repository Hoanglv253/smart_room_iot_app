import 'package:cloud_firestore/cloud_firestore.dart';

class AppFirestoreService {
  AppFirestoreService._();

  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static CollectionReference<Map<String, dynamic>> get users =>
      db.collection('users');

  static CollectionReference<Map<String, dynamic>> get posts =>
      db.collection('posts');

  static CollectionReference<Map<String, dynamic>> get buildings =>
      db.collection('buildings');

  static CollectionReference<Map<String, dynamic>> get joinRequests =>
      db.collection('joinRequests');

  static CollectionReference<Map<String, dynamic>> get chats =>
      db.collection('chats');

  static CollectionReference<Map<String, dynamic>> buildingRooms(
    String buildingId,
  ) {
    return buildings.doc(buildingId).collection('rooms');
  }

  static CollectionReference<Map<String, dynamic>> buildingComments(
    String buildingId,
  ) {
    return buildings.doc(buildingId).collection('comments');
  }

  static CollectionReference<Map<String, dynamic>> buildingInvoices(
    String buildingId,
  ) {
    return buildings.doc(buildingId).collection('invoices');
  }

  static CollectionReference<Map<String, dynamic>> chatMessages(String chatId) {
    return chats.doc(chatId).collection('messages');
  }

  static Future<void> saveUserProfile({
    required String uid,
    required String email,
    required String name,
    required String role,
  }) {
    return users.doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': role,
      'buildingId': null,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<String> getUserRole(String uid) async {
    final doc = await users.doc(uid).get();
    if (!doc.exists) return UserRole.user;

    final role = doc.data()?['role']?.toString();
    return UserRole.values.contains(role) ? role! : UserRole.user;
  }

  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    final doc = await users.doc(uid).get();
    return doc.data();
  }
}

class UserRole {
  UserRole._();

  static const admin = 'admin';
  static const manager = 'manager';
  static const user = 'user';
  static const values = [admin, manager, user];

  static String label(String role) {
    return switch (role) {
      admin => 'Quản trị viên',
      manager => 'Quản lý',
      _ => 'Người dùng',
    };
  }
}

class JoinRequestStatus {
  JoinRequestStatus._();

  static const pending = 'pending';
  static const approved = 'approved';
  static const rejected = 'rejected';
}

class ChatType {
  ChatType._();

  static const private = 'private';
  static const group = 'group';
}

class InvoiceStatus {
  InvoiceStatus._();

  static const unpaid = 'unpaid';
  static const waitingPayment = 'waiting_payment';
  static const pending = 'pending';
  static const paid = 'paid';
  static const overdue = 'overdue';
  static const cancelled = 'cancelled';
}
