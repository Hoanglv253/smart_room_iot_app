import '../../../core/view_models/base_view_model.dart';
import '../repositories/invoice_repository.dart';

class AdminInvoiceDetailViewModel extends BaseViewModel {
  AdminInvoiceDetailViewModel({InvoiceRepository? invoiceRepository})
    : _invoiceRepository = invoiceRepository ?? InvoiceRepository();

  final InvoiceRepository _invoiceRepository;

  Future<bool> markPaid({
    required String buildingId,
    required String invoiceId,
  }) {
    return runBusyAction(
      () => _invoiceRepository.markPaid(
        buildingId: buildingId,
        invoiceId: invoiceId,
      ),
    );
  }

  Future<bool> rejectPayment({
    required String buildingId,
    required String invoiceId,
  }) {
    return runBusyAction(
      () => _invoiceRepository.rejectPayment(
        buildingId: buildingId,
        invoiceId: invoiceId,
      ),
    );
  }
}
