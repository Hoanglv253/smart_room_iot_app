import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/invoice_repository.dart';

class TenantInvoiceDetailViewModel extends BaseViewModel {
  TenantInvoiceDetailViewModel({InvoiceRepository? invoiceRepository})
    : _invoiceRepository = invoiceRepository ?? InvoiceRepository();

  final InvoiceRepository _invoiceRepository;
  bool _isCreatingPayosPayment = false;

  bool get isCreatingPayosPayment => _isCreatingPayosPayment;

  Future<bool> reportManualPayment({
    required String buildingId,
    required String invoiceId,
    required String note,
  }) {
    return runBusyAction(
      () => _invoiceRepository.reportManualPayment(
        buildingId: buildingId,
        invoiceId: invoiceId,
        note: note,
      ),
    );
  }

  Future<Map<String, dynamic>?> building(String buildingId) async {
    final snapshot = await _invoiceRepository.building(buildingId);
    return snapshot.data();
  }

  Future<Uri?> createPayosPayment({
    required String backendBaseUrl,
    required User? user,
    required String buildingId,
    required String invoiceId,
  }) async {
    if (backendBaseUrl.isEmpty) {
      setError('Chua cau hinh PAYOS_BACKEND_URL cho app.');
      return null;
    }

    _setPayosLoading(true);
    clearError();

    try {
      final idToken = await user?.getIdToken();
      if (idToken == null) {
        setError('Hay dang nhap lai de thanh toan PayOS.');
        return null;
      }

      return await _invoiceRepository.createPayosPayment(
        backendBaseUrl: backendBaseUrl,
        idToken: idToken,
        buildingId: buildingId,
        invoiceId: invoiceId,
      );
    } catch (error) {
      setError(error.toString());
      return null;
    } finally {
      _setPayosLoading(false);
    }
  }

  void _setPayosLoading(bool value) {
    if (_isCreatingPayosPayment == value) return;
    _isCreatingPayosPayment = value;
    notifyListeners();
  }
}
