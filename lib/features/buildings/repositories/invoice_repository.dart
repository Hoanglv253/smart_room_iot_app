import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../../../core/services/app_firestore_service.dart';

class InvoiceRepository {
  Stream<QuerySnapshot<Map<String, dynamic>>> buildingInvoices(
    String buildingId,
  ) {
    return AppFirestoreService.buildingInvoices(buildingId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> tenantInvoices({
    required String buildingId,
    required String tenantId,
  }) {
    return AppFirestoreService.buildingInvoices(
      buildingId,
    ).where('tenantId', isEqualTo: tenantId).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> buildingRooms(
    String buildingId,
  ) {
    return AppFirestoreService.buildingRooms(buildingId).get();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> building(String buildingId) {
    return AppFirestoreService.buildings.doc(buildingId).get();
  }

  Future<List<Map<String, dynamic>>> roomInvoices({
    required String buildingId,
    required String roomId,
  }) async {
    final snapshot =
        await AppFirestoreService.buildingInvoices(buildingId).get();
    return snapshot.docs
        .map((doc) => {
              ...doc.data(),
              '_id': doc.id,
            })
        .where((invoice) => invoice['roomId'] == roomId)
        .where((invoice) => invoice['status'] != InvoiceStatus.cancelled)
        .toList();
  }

  Future<void> createInvoice({
    required String buildingId,
    required Map<String, dynamic> invoice,
  }) async {
    await AppFirestoreService.buildingInvoices(buildingId).add({
      ...invoice,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateUnpaidInvoice({
    required String buildingId,
    required String invoiceId,
    required Map<String, dynamic> invoice,
  }) async {
    final invoiceRef =
        AppFirestoreService.buildingInvoices(buildingId).doc(invoiceId);

    await AppFirestoreService.db.runTransaction((transaction) async {
      final snapshot = await transaction.get(invoiceRef);
      final status =
          (snapshot.data()?['status'] ?? InvoiceStatus.unpaid).toString();

      if (status != InvoiceStatus.unpaid) {
        throw StateError('Chi duoc sua hoa don chua thanh toan.');
      }

      transaction.update(invoiceRef, {
        ...invoice,
        'status': InvoiceStatus.unpaid,
        'paymentMethod': '',
        'paymentNote': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> markPaid({
    required String buildingId,
    required String invoiceId,
  }) {
    return AppFirestoreService.buildingInvoices(buildingId).doc(invoiceId).update({
      'status': InvoiceStatus.paid,
      'paymentMethod': 'admin_confirmed',
      'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reportManualPayment({
    required String buildingId,
    required String invoiceId,
    required String note,
  }) {
    return AppFirestoreService.buildingInvoices(buildingId).doc(invoiceId).update({
      'status': InvoiceStatus.pending,
      'paymentMethod': 'manual_transfer',
      'paymentNote': note.trim(),
      'paidReportedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Uri> createPayosPayment({
    required String backendBaseUrl,
    required String idToken,
    required String buildingId,
    required String invoiceId,
  }) async {
    final response = await http
        .post(
          _backendUri(backendBaseUrl, '/create-payos-payment'),
          headers: {
            'Authorization': 'Bearer $idToken',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'buildingId': buildingId,
            'invoiceId': invoiceId,
          }),
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException(
              'Khong ket noi duoc PayOS backend tai $backendBaseUrl. '
              'Hay rebuild app, kiem tra server 8080 va adb reverse.',
            );
          },
        );

    final decoded = jsonDecode(response.body);
    final data = decoded is Map<String, dynamic> ? decoded : {};
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        data['message']?.toString() ?? 'Khong tao duoc thanh toan PayOS.',
      );
    }

    final checkoutUrl = data['checkoutUrl']?.toString() ?? '';
    final uri = Uri.tryParse(checkoutUrl);
    if (uri == null || checkoutUrl.isEmpty) {
      throw Exception('PayOS chua tra ve link thanh toan.');
    }

    return uri;
  }

  Uri _backendUri(String backendBaseUrl, String path) {
    final base = backendBaseUrl.endsWith('/')
        ? backendBaseUrl.substring(0, backendBaseUrl.length - 1)
        : backendBaseUrl;
    return Uri.parse('$base$path');
  }
}
