import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/view_models/base_view_model.dart';
import '../repositories/invoice_repository.dart';

class CreateInvoiceViewModel extends BaseViewModel {
  CreateInvoiceViewModel({InvoiceRepository? invoiceRepository})
    : _invoiceRepository = invoiceRepository ?? InvoiceRepository();

  final InvoiceRepository _invoiceRepository;
  bool _isLoadingRoomHistory = false;
  bool _hasDuplicateInvoice = false;
  String? _roomHistoryMessage;

  bool get isLoadingRoomHistory => _isLoadingRoomHistory;
  bool get hasDuplicateInvoice => _hasDuplicateInvoice;
  String? get roomHistoryMessage => _roomHistoryMessage;

  Future<QuerySnapshot<Map<String, dynamic>>> buildingRooms(String buildingId) {
    return _invoiceRepository.buildingRooms(buildingId);
  }

  Future<List<Map<String, dynamic>>> roomInvoices({
    required String buildingId,
    required String roomId,
  }) {
    return _invoiceRepository.roomInvoices(
      buildingId: buildingId,
      roomId: roomId,
    );
  }

  Future<bool> createInvoice({
    required String buildingId,
    required Map<String, dynamic> invoice,
  }) {
    return runBusyAction(
      () => _invoiceRepository.createInvoice(
        buildingId: buildingId,
        invoice: invoice,
      ),
    );
  }

  void setRoomHistoryLoading(bool value) {
    if (_isLoadingRoomHistory == value) return;
    _isLoadingRoomHistory = value;
    notifyListeners();
  }

  void setRoomHistoryMessage(String? message) {
    _roomHistoryMessage = message;
    notifyListeners();
  }

  void setHasDuplicateInvoice(bool value) {
    if (_hasDuplicateInvoice == value) return;
    _hasDuplicateInvoice = value;
    notifyListeners();
  }
}
