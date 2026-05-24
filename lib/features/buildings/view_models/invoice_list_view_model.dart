import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/view_models/base_view_model.dart';
import '../repositories/invoice_repository.dart';

const allInvoiceStatus = 'all';

class InvoiceListViewModel extends BaseViewModel {
  InvoiceListViewModel({InvoiceRepository? invoiceRepository})
    : _invoiceRepository = invoiceRepository ?? InvoiceRepository() {
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
  }

  final InvoiceRepository _invoiceRepository;
  late int _selectedMonth;
  late int _selectedYear;
  String _selectedStatus = allInvoiceStatus;

  int get selectedMonth => _selectedMonth;
  int get selectedYear => _selectedYear;
  String get selectedStatus => _selectedStatus;

  Stream<QuerySnapshot<Map<String, dynamic>>> buildingInvoices(
    String buildingId,
  ) {
    return _invoiceRepository.buildingInvoices(buildingId);
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> tenantInvoices({
    required String buildingId,
    required String tenantId,
  }) {
    return _invoiceRepository.tenantInvoices(
      buildingId: buildingId,
      tenantId: tenantId,
    );
  }

  void setMonth(int month) {
    if (_selectedMonth == month) return;
    _selectedMonth = month;
    notifyListeners();
  }

  void setYear(int year) {
    if (_selectedYear == year) return;
    _selectedYear = year;
    notifyListeners();
  }

  void setStatus(String status) {
    if (_selectedStatus == status) return;
    _selectedStatus = status;
    notifyListeners();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> sortInvoices(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> invoices,
  ) {
    return invoices.toList()
      ..sort((left, right) {
        final leftKey = periodSortKey(left.data());
        final rightKey = periodSortKey(right.data());
        if (leftKey != rightKey) return rightKey.compareTo(leftKey);
        return timestampMillis(
          right.data()['createdAt'],
        ).compareTo(timestampMillis(left.data()['createdAt']));
      });
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> monthlyInvoices(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices,
  ) {
    return invoices.where((doc) {
      final data = doc.data();
      return readInt(data['month']) == _selectedMonth &&
          readInt(data['year']) == _selectedYear;
    }).toList();
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> filteredInvoices(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices,
  ) {
    if (_selectedStatus == allInvoiceStatus) return invoices;

    return invoices.where((doc) {
      final status = (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return status == _selectedStatus;
    }).toList();
  }

  List<int> yearOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices,
  ) {
    final years = <int>{DateTime.now().year, _selectedYear};
    for (final invoice in invoices) {
      final year = readInt(invoice.data()['year']);
      if (year > 0) years.add(year);
    }
    return years.toList()..sort((left, right) => right.compareTo(left));
  }

  int periodSortKey(Map<String, dynamic> data) {
    final year = readInt(data['year']);
    final month = readInt(data['month']);
    return year * 100 + month;
  }

  int timestampMillis(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }

  int readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
