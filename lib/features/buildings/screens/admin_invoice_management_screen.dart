import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../view_models/admin_invoice_detail_view_model.dart';
import '../view_models/create_invoice_view_model.dart';
import '../view_models/invoice_list_view_model.dart';

const _allInvoiceStatus = 'all';

class _InvoiceStatusOption {
  const _InvoiceStatusOption(this.value, this.label);

  final String value;
  final String label;
}

const _invoiceStatusOptions = [
  _InvoiceStatusOption(_allInvoiceStatus, 'Tat ca'),
  _InvoiceStatusOption(InvoiceStatus.unpaid, 'Chua TT'),
  _InvoiceStatusOption(InvoiceStatus.waitingPayment, 'Dang TT'),
  _InvoiceStatusOption(InvoiceStatus.pending, 'Cho xac nhan'),
  _InvoiceStatusOption(InvoiceStatus.paid, 'Da TT'),
  _InvoiceStatusOption(InvoiceStatus.overdue, 'Qua han'),
];

class AdminInvoiceManagementScreen extends StatefulWidget {
  const AdminInvoiceManagementScreen({
    required this.buildingId,
    required this.building,
    this.canCreate = true,
    this.canConfirmPayment = true,
    super.key,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final bool canCreate;
  final bool canConfirmPayment;

  @override
  State<AdminInvoiceManagementScreen> createState() =>
      _AdminInvoiceManagementScreenState();
}

class _AdminInvoiceManagementScreenState
    extends State<AdminInvoiceManagementScreen> {
  final _viewModel = InvoiceListViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buildingName = (widget.building['name'] ?? 'Toa nha').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Hoa don')),
      floatingActionButton: widget.canCreate
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => _CreateInvoiceScreen(
                      buildingId: widget.buildingId,
                      building: widget.building,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Tao hoa don'),
            )
          : null,
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _viewModel.buildingInvoices(widget.buildingId),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const _InvoiceEmptyView(
                  icon: Icons.lock_outline,
                  message: 'Khong tai duoc danh sach hoa don.',
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final invoices = _viewModel.sortInvoices(snapshot.data?.docs ?? []);
              final yearOptions = _viewModel.yearOptions(invoices);
              final periodPicker = _InvoicePeriodPicker(
                month: _viewModel.selectedMonth,
                year: _viewModel.selectedYear,
                years: yearOptions,
                onMonthChanged: (value) {
                  if (value == null) return;
                  _viewModel.setMonth(value);
                },
                onYearChanged: (value) {
                  if (value == null) return;
                  _viewModel.setYear(value);
                },
              );

              if (invoices.isEmpty) {
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    periodPicker,
                    _InvoiceEmptyView(
                      icon: Icons.receipt_long_outlined,
                      message: 'Chua co hoa don nao cho $buildingName.',
                    ),
                  ],
                );
              }

              final monthlyInvoices = _viewModel.monthlyInvoices(invoices);
              final filteredInvoices = _viewModel.filteredInvoices(
                monthlyInvoices,
              );

          return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  periodPicker,
                  const SizedBox(height: 12),
                  _InvoiceRevenueOverview(invoices: monthlyInvoices),
                  const SizedBox(height: 12),
                  _InvoiceStatusFilterBar(
                    invoices: monthlyInvoices,
                    selectedStatus: _viewModel.selectedStatus,
                    onChanged: _viewModel.setStatus,
                  ),
                  const SizedBox(height: 12),
                  if (filteredInvoices.isEmpty)
                    _InvoiceEmptyView(
                      icon: Icons.event_busy_outlined,
                      message:
                          'Khong co hoa don ${_statusFilterText(_viewModel.selectedStatus)}trong thang ${_viewModel.selectedMonth}/${_viewModel.selectedYear}.',
                    )
                  else ...[
                    _InvoiceMonthHeader(
                      data: {
                        'month': _viewModel.selectedMonth,
                        'year': _viewModel.selectedYear,
                      },
                      invoiceCount: filteredInvoices.length,
                      totalAmount: filteredInvoices.fold<int>(
                        0,
                        (total, doc) =>
                            total + _readInt(doc.data()['totalAmount']),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...filteredInvoices.map((doc) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _InvoiceCard(
                          invoiceId: doc.id,
                          data: doc.data(),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => _AdminInvoiceDetailScreen(
                                  buildingId: widget.buildingId,
                                  building: widget.building,
                                  invoiceId: doc.id,
                                  invoice: doc.data(),
                                  canConfirmPayment:
                                      widget.canConfirmPayment,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _InvoiceStatusFilterBar extends StatelessWidget {
  const _InvoiceStatusFilterBar({
    required this.invoices,
    required this.selectedStatus,
    required this.onChanged,
  });

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices;
  final String selectedStatus;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final option in _invoiceStatusOptions) ...[
            ChoiceChip(
              label: Text('${option.label} (${_count(option.value)})'),
              selected: selectedStatus == option.value,
              onSelected: (_) => onChanged(option.value),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  int _count(String status) {
    if (status == _allInvoiceStatus) return invoices.length;

    return invoices.where((doc) {
      final dataStatus = (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return dataStatus == status;
    }).length;
  }
}

class _InvoiceRevenueOverview extends StatelessWidget {
  const _InvoiceRevenueOverview({required this.invoices});

  final List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices;

  @override
  Widget build(BuildContext context) {
    final paidTotal = _sumByStatus(InvoiceStatus.paid);
    final pendingTotal = _sumByStatus(InvoiceStatus.pending);
    final unpaidTotal = _sumUnpaid();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tong quan doanh thu',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _RevenueTile(
                label: 'Da thu',
                value: paidTotal,
                icon: Icons.check_circle_outline,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RevenueTile(
                label: 'Cho xac nhan',
                value: pendingTotal,
                icon: Icons.hourglass_top_outlined,
                color: Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _RevenueTile(
                label: 'Chua thu',
                value: unpaidTotal,
                icon: Icons.pending_actions_outlined,
                color: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _sumByStatus(String status) {
    return invoices.where((doc) {
      final dataStatus = (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return dataStatus == status;
    }).fold<int>(0, (total, doc) => total + _readInt(doc.data()['totalAmount']));
  }

  int _sumUnpaid() {
    return invoices.where((doc) {
      final status = (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return status != InvoiceStatus.paid &&
          status != InvoiceStatus.pending &&
          status != InvoiceStatus.cancelled;
    }).fold<int>(0, (total, doc) => total + _readInt(doc.data()['totalAmount']));
  }
}

class _RevenueTile extends StatelessWidget {
  const _RevenueTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 4),
          Text(
            _money(value),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoicePeriodPicker extends StatelessWidget {
  const _InvoicePeriodPicker({
    required this.month,
    required this.year,
    required this.years,
    required this.onMonthChanged,
    required this.onYearChanged,
  });

  final int month;
  final int year;
  final List<int> years;
  final ValueChanged<int?> onMonthChanged;
  final ValueChanged<int?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Thang',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: month,
                    isDense: true,
                    isExpanded: true,
                    items: [
                      for (var index = 1; index <= 12; index++)
                        DropdownMenuItem(
                          value: index,
                          child: Text('Thang $index'),
                        ),
                    ],
                    onChanged: onMonthChanged,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Nam',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: year,
                    isDense: true,
                    isExpanded: true,
                    items: [
                      for (final item in years)
                        DropdownMenuItem(
                          value: item,
                          child: Text(item.toString()),
                        ),
                    ],
                    onChanged: onYearChanged,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceMonthHeader extends StatelessWidget {
  const _InvoiceMonthHeader({
    required this.data,
    required this.invoiceCount,
    required this.totalAmount,
  });

  final Map<String, dynamic> data;
  final int invoiceCount;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month_outlined, color: Color(0xFF2563EB)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _periodLabel(data),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$invoiceCount hoa don',
                  style: const TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          Text(
            _money(totalAmount),
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CreateInvoiceScreen extends StatefulWidget {
  const _CreateInvoiceScreen({
    required this.buildingId,
    required this.building,
    this.invoiceId,
    this.initialInvoice,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final String? invoiceId;
  final Map<String, dynamic>? initialInvoice;

  bool get isEditing => invoiceId != null && initialInvoice != null;

  @override
  State<_CreateInvoiceScreen> createState() => _CreateInvoiceScreenState();
}

class _CreateInvoiceScreenState extends State<_CreateInvoiceScreen> {
  final _monthController = TextEditingController();
  final _yearController = TextEditingController();
  final _roomRentController = TextEditingController();
  final _electricityOldController = TextEditingController();
  final _electricityNewController = TextEditingController();
  final _waterOldController = TextEditingController();
  final _waterNewController = TextEditingController();
  final _serviceFeeController = TextEditingController();
  final _internetFeeController = TextEditingController();
  final _parkingFeeController = TextEditingController();
  final _otherFeeController = TextEditingController();
  final _discountController = TextEditingController();
  final _viewModel = CreateInvoiceViewModel();

  late final Future<QuerySnapshot<Map<String, dynamic>>> _roomsFuture;
  String? _selectedRoomId;
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedRoom;

  @override
  void initState() {
    super.initState();
    _roomsFuture = _viewModel.buildingRooms(widget.buildingId);

    final now = DateTime.now();
    final invoice = widget.initialInvoice;
    _selectedRoomId = invoice?['roomId']?.toString();
    _monthController.text =
        _readInt(invoice?['month'], fallback: now.month).toString();
    _yearController.text =
        _readInt(invoice?['year'], fallback: now.year).toString();
    _monthController.addListener(_handlePeriodChanged);
    _yearController.addListener(_handlePeriodChanged);
    _roomRentController.text = _readInt(invoice?['roomRent']).toString();
    _electricityOldController.text =
        _readInt(invoice?['electricityOld']).toString();
    _electricityNewController.text =
        _readInt(invoice?['electricityNew']).toString();
    _waterOldController.text = _readInt(invoice?['waterOld']).toString();
    _waterNewController.text = _readInt(invoice?['waterNew']).toString();
    _serviceFeeController.text =
        _readInt(invoice?['serviceFee'], fallback: _readInt(widget.building['serviceFee']))
            .toString();
    _internetFeeController.text =
        _readInt(invoice?['internetFee'], fallback: _readInt(widget.building['internetFee']))
            .toString();
    _parkingFeeController.text =
        _readInt(invoice?['parkingFee'], fallback: _readInt(widget.building['parkingFee']))
            .toString();
    _otherFeeController.text = _readInt(invoice?['otherFee']).toString();
    _discountController.text = _readInt(invoice?['discount']).toString();

    for (final controller in [
      _roomRentController,
      _electricityOldController,
      _electricityNewController,
      _waterOldController,
      _waterNewController,
      _serviceFeeController,
      _internetFeeController,
      _parkingFeeController,
      _otherFeeController,
      _discountController,
    ]) {
      controller.addListener(_refreshTotal);
    }

    if (widget.isEditing) {
      _viewModel.setRoomHistoryMessage(
        'Dang sua hoa don chua thanh toan. Neu doi phong hoac ky, app se kiem tra trung hoa don khi luu.',
      );
    }
  }

  @override
  void dispose() {
    _monthController.dispose();
    _yearController.dispose();
    _roomRentController.dispose();
    _electricityOldController.dispose();
    _electricityNewController.dispose();
    _waterOldController.dispose();
    _waterNewController.dispose();
    _serviceFeeController.dispose();
    _internetFeeController.dispose();
    _parkingFeeController.dispose();
    _otherFeeController.dispose();
    _discountController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  void _handlePeriodChanged() {
    if (_selectedRoom == null && _selectedRoomId == null) return;

    _viewModel.setHasDuplicateInvoice(false);
    _viewModel.setRoomHistoryMessage(
      'Ky hoa don da thay doi. Khi luu app se kiem tra trung ky voi ky moi.',
    );
  }

  void _selectRoom(QueryDocumentSnapshot<Map<String, dynamic>> roomDoc) {
    final room = roomDoc.data();
    final roomRent = _readInt(room['rent']);
    final defaultRent = _readInt(widget.building['defaultRent']);

    setState(() {
      _selectedRoomId = roomDoc.id;
      _selectedRoom = roomDoc;
      _roomRentController.text =
          (roomRent > 0 ? roomRent : defaultRent).toString();
      _electricityOldController.text = '0';
      _waterOldController.text = '0';
    });
    _viewModel.setRoomHistoryMessage(null);
    _viewModel.setHasDuplicateInvoice(false);

    _loadRoomInvoiceContext(roomDoc.id);
  }

  Future<void> _loadRoomInvoiceContext(String roomId) async {
    _viewModel.setRoomHistoryLoading(true);

    try {
      final invoices = await _viewModel.roomInvoices(
        buildingId: widget.buildingId,
        roomId: roomId,
      );
      if (!mounted || _selectedRoomId != roomId) return;

      final currentPeriod = _periodKeyFromControllers();
      final duplicateInvoice = invoices.where((invoice) {
        return _periodKey(invoice) == currentPeriod &&
            invoice['_id']?.toString() != widget.invoiceId;
      }).toList();

      final previousInvoices = invoices.where((invoice) {
        return _periodKey(invoice) < currentPeriod;
      }).toList()
        ..sort((left, right) => _periodKey(right).compareTo(_periodKey(left)));

      _viewModel.setHasDuplicateInvoice(duplicateInvoice.isNotEmpty);

      if (previousInvoices.isNotEmpty) {
        final previous = previousInvoices.first;
        final electricityNew = _readInt(previous['electricityNew']);
        final waterNew = _readInt(previous['waterNew']);
        _electricityOldController.text = electricityNew.toString();
        _waterOldController.text = waterNew.toString();
        _viewModel.setRoomHistoryMessage(
          'Da lay chi so cu tu hoa don ${_periodLabel(previous)}.',
        );
      } else {
        _viewModel.setRoomHistoryMessage(
          'Chua co hoa don truoc do, chi so cu dang mac dinh la 0.',
        );
      }

      if (_viewModel.hasDuplicateInvoice) {
        _viewModel.setRoomHistoryMessage(
          'Phong nay da co hoa don ${_monthController.text}/${_yearController.text}. Hay kiem tra lai truoc khi tao moi.',
        );
      }
    } catch (e) {
      if (!mounted || _selectedRoomId != roomId) return;
      final message = e.toString();
      _viewModel.setRoomHistoryMessage(
        message.contains('permission-denied')
            ? 'Firestore chua cap quyen doc hoa don cu.'
            : 'Khong tai duoc hoa don cu.',
      );
    } finally {
      if (mounted && _selectedRoomId == roomId) {
        _viewModel.setRoomHistoryLoading(false);
      }
    }
  }

  Future<void> _saveInvoice(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
  ) async {
    if (widget.isEditing) {
      final status =
          (widget.initialInvoice?['status'] ?? InvoiceStatus.unpaid).toString();
      if (status != InvoiceStatus.unpaid) {
        _showSnack('Chi duoc sua hoa don chua thanh toan.');
        return;
      }
    }

    final roomDoc = _selectedRoom ?? _findRoomById(rooms, _selectedRoomId);
    if (roomDoc == null) {
      _showSnack('Hay chon phong can lap hoa don.');
      return;
    }

    final room = roomDoc.data();
    final tenantId = (room['tenantId'] ?? '').toString();
    if (tenantId.isEmpty) {
      _showSnack('Phong nay chua co nguoi thue.');
      return;
    }

    final month = _readInt(_monthController.text);
    final year = _readInt(_yearController.text);
    if (month < 1 || month > 12 || year < 2000) {
      _showSnack('Thang hoac nam khong hop le.');
      return;
    }

    final List<Map<String, dynamic>> existingInvoices;
    try {
      existingInvoices = await _viewModel.roomInvoices(
        buildingId: widget.buildingId,
        roomId: roomDoc.id,
      );
    } catch (e) {
      final message = e.toString();
      _showSnack(
        message.contains('permission-denied')
            ? 'Firestore chua cap quyen kiem tra hoa don cu.'
            : 'Khong kiem tra duoc hoa don cu.',
      );
      return;
    }

    final currentPeriod = _periodKey(null, year: year, month: month);
    final hasDuplicate = existingInvoices.any((invoice) {
      return _periodKey(invoice) == currentPeriod &&
          invoice['_id']?.toString() != widget.invoiceId;
    });
    if (hasDuplicate) {
      _viewModel.setHasDuplicateInvoice(true);
      _showSnack('Phong nay da co hoa don thang $month/$year.');
      return;
    }

    try {
      final electricityOld = _readInt(_electricityOldController.text);
      final electricityNew = _readInt(_electricityNewController.text);
      final waterOld = _readInt(_waterOldController.text);
      final waterNew = _readInt(_waterNewController.text);
      final electricityUsage =
          (electricityNew - electricityOld).clamp(0, 999999).toInt();
      final waterUsage = (waterNew - waterOld).clamp(0, 999999).toInt();
      final electricityPrice = _readInt(widget.building['electricityPrice']);
      final waterPrice = _readInt(widget.building['waterPrice']);
      final roomName = _text(room['name'], roomDoc.id);
      final roomNumber = _readInt(room['roomNumber']);
      final tenantName = _text(room['tenantName'], 'Nguoi thue');
      final tenantEmail = _text(room['tenantEmail'], '');
      final dueDate = _dueDate(year, month, _readInt(widget.building['billDueDay']));

      final invoiceData = {
        'buildingId': widget.buildingId,
        'roomId': roomDoc.id,
        'roomName': roomName,
        'roomNumber': roomNumber,
        'tenantId': tenantId,
        'tenantName': tenantName,
        'tenantEmail': tenantEmail,
        'month': month,
        'year': year,
        'periodKey': '$year-${month.toString().padLeft(2, '0')}',
        'roomRent': _readInt(_roomRentController.text),
        'electricityOld': electricityOld,
        'electricityNew': electricityNew,
        'electricityUsage': electricityUsage,
        'electricityPrice': electricityPrice,
        'electricityAmount': electricityUsage * electricityPrice,
        'waterOld': waterOld,
        'waterNew': waterNew,
        'waterUsage': waterUsage,
        'waterPrice': waterPrice,
        'waterAmount': waterUsage * waterPrice,
        'serviceFee': _readInt(_serviceFeeController.text),
        'internetFee': _readInt(_internetFeeController.text),
        'parkingFee': _readInt(_parkingFeeController.text),
        'otherFee': _readInt(_otherFeeController.text),
        'discount': _readInt(_discountController.text),
        'totalAmount': _totalAmount,
        'status': InvoiceStatus.unpaid,
        'paymentMethod': '',
        'paymentNote': '',
        'dueDate': Timestamp.fromDate(dueDate),
      };
      final saved = widget.isEditing
          ? await _viewModel.updateUnpaidInvoice(
              buildingId: widget.buildingId,
              invoiceId: widget.invoiceId!,
              invoice: invoiceData,
            )
          : await _viewModel.createInvoice(
              buildingId: widget.buildingId,
              invoice: invoiceData,
            );
      if (!saved) {
        _showSnack(_createInvoiceError());
        return;
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      _showSnack(
        widget.isEditing ? 'Khong sua duoc hoa don.' : 'Khong tao duoc hoa don.',
      );
    }
  }

  QueryDocumentSnapshot<Map<String, dynamic>>? _findRoomById(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms,
    String? roomId,
  ) {
    if (roomId == null) return null;
    for (final room in rooms) {
      if (room.id == roomId) return room;
    }
    return null;
  }

  int get _electricityAmount {
    final usage = (_readInt(_electricityNewController.text) -
            _readInt(_electricityOldController.text))
        .clamp(0, 999999)
        .toInt();
    return usage * _readInt(widget.building['electricityPrice']);
  }

  int get _waterAmount {
    final usage = (_readInt(_waterNewController.text) -
            _readInt(_waterOldController.text))
        .clamp(0, 999999)
        .toInt();
    return usage * _readInt(widget.building['waterPrice']);
  }

  int get _totalAmount {
    final subtotal = _readInt(_roomRentController.text) +
        _electricityAmount +
        _waterAmount +
        _readInt(_serviceFeeController.text) +
        _readInt(_internetFeeController.text) +
        _readInt(_parkingFeeController.text) +
        _readInt(_otherFeeController.text);
    final total = subtotal - _readInt(_discountController.text);
    return total < 0 ? 0 : total;
  }

  int _periodKeyFromControllers() {
    return _periodKey(
      null,
      year: _readInt(_yearController.text),
      month: _readInt(_monthController.text),
    );
  }

  static int _periodKey(
    Map<String, dynamic>? invoice, {
    int? year,
    int? month,
  }) {
    final resolvedYear = year ?? _readInt(invoice?['year']);
    final resolvedMonth = month ?? _readInt(invoice?['month']);
    return resolvedYear * 100 + resolvedMonth;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Sua hoa don' : 'Tao hoa don'),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
            future: _roomsFuture,
            builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = (snapshot.data?.docs ?? []).where((doc) {
            final tenantId = (doc.data()['tenantId'] ?? '').toString();
            return tenantId.isNotEmpty;
          }).toList()
            ..sort((left, right) {
              final leftNumber = _readInt(left.data()['roomNumber']);
              final rightNumber = _readInt(right.data()['roomNumber']);
              return leftNumber.compareTo(rightNumber);
            });

          if (rooms.isEmpty) {
            return const _InvoiceEmptyView(
              icon: Icons.meeting_room_outlined,
              message: 'Chua co phong nao dang co nguoi thue.',
            );
          }

              final selectedRoomId =
                  _findRoomById(rooms, _selectedRoomId) == null
                      ? null
                      : _selectedRoomId;

              return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: selectedRoomId,
                decoration: const InputDecoration(
                  labelText: 'Phong',
                  border: OutlineInputBorder(),
                ),
                items: rooms.map((doc) {
                  final room = doc.data();
                  final name = _text(room['name'], doc.id);
                  final tenantName = _text(room['tenantName'], 'Nguoi thue');
                  return DropdownMenuItem(
                    value: doc.id,
                    child: Text('$name - $tenantName'),
                  );
                }).toList(),
                onChanged: (roomId) {
                  if (roomId == null) return;
                  final roomDoc = rooms.firstWhere((doc) => doc.id == roomId);
                  _selectRoom(roomDoc);
                },
              ),
              if (_viewModel.isLoadingRoomHistory) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(minHeight: 2),
              ] else if (_viewModel.roomHistoryMessage != null) ...[
                const SizedBox(height: 10),
                _InvoiceNotice(
                  message: _viewModel.roomHistoryMessage!,
                  isWarning: _viewModel.hasDuplicateInvoice,
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numberField(_monthController, 'Thang')),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(_yearController, 'Nam')),
                ],
              ),
              _numberField(_roomRentController, 'Tien phong'),
              Row(
                children: [
                  Expanded(
                    child: _numberField(_electricityOldController, 'Dien cu'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _numberField(_electricityNewController, 'Dien moi'),
                  ),
                ],
              ),
              _AmountPreview(
                label: 'Tien dien',
                value: _electricityAmount,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _numberField(_waterOldController, 'Nuoc cu')),
                  const SizedBox(width: 12),
                  Expanded(child: _numberField(_waterNewController, 'Nuoc moi')),
                ],
              ),
              _AmountPreview(label: 'Tien nuoc', value: _waterAmount),
              const SizedBox(height: 12),
              _numberField(_serviceFeeController, 'Phi dich vu'),
              _numberField(_internetFeeController, 'Internet'),
              _numberField(_parkingFeeController, 'Gui xe'),
              _numberField(_otherFeeController, 'Phu thu'),
              _numberField(_discountController, 'Giam tru'),
              const SizedBox(height: 12),
              _TotalPreview(total: _totalAmount),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _viewModel.isLoading ||
                        _viewModel.hasDuplicateInvoice
                    ? null
                    : () => _saveInvoice(rooms),
                icon: _viewModel.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(widget.isEditing ? 'Cap nhat hoa don' : 'Luu hoa don'),
              ),
            ],
          );
            },
          );
        },
      ),
    );
  }

  Widget _numberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _createInvoiceError() {
    final error = _viewModel.errorMessage;
    if (error?.contains('permission-denied') == true) {
      return widget.isEditing
          ? 'Firestore chua cap quyen sua hoa don.'
          : 'Firestore chua cap quyen tao hoa don.';
    }
    if (error?.contains('Chi duoc sua hoa don chua thanh toan') == true) {
      return 'Chi duoc sua hoa don chua thanh toan.';
    }

    return widget.isEditing ? 'Khong sua duoc hoa don.' : 'Khong tao duoc hoa don.';
  }

  static int _readInt(Object? value, {int fallback = 0}) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static DateTime _dueDate(int year, int month, int rawDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = rawDay <= 0 ? lastDay : rawDay.clamp(1, lastDay).toInt();
    return DateTime(year, month, day, 23, 59, 59);
  }
}

class _AdminInvoiceDetailScreen extends StatefulWidget {
  const _AdminInvoiceDetailScreen({
    required this.buildingId,
    required this.building,
    required this.invoiceId,
    required this.invoice,
    required this.canConfirmPayment,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final String invoiceId;
  final Map<String, dynamic> invoice;
  final bool canConfirmPayment;

  @override
  State<_AdminInvoiceDetailScreen> createState() =>
      _AdminInvoiceDetailScreenState();
}

class _AdminInvoiceDetailScreenState extends State<_AdminInvoiceDetailScreen> {
  final _viewModel = AdminInvoiceDetailViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _markPaid() async {
    final saved = await _viewModel.markPaid(
      buildingId: widget.buildingId,
      invoiceId: widget.invoiceId,
    );

    if (!mounted) return;
    if (saved) {
      Navigator.of(context).pop();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_adminPaymentError())),
    );
  }

  Future<void> _openEditInvoice() async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => _CreateInvoiceScreen(
          buildingId: widget.buildingId,
          building: widget.building,
          invoiceId: widget.invoiceId,
          initialInvoice: widget.invoice,
        ),
      ),
    );

    if (!mounted || updated != true) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final status = (invoice['status'] ?? InvoiceStatus.unpaid).toString();
    final paymentNote = (invoice['paymentNote'] ?? '').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiet hoa don')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InvoiceHeader(data: invoice),
          const SizedBox(height: 12),
          _InvoiceSection(
            title: 'Thong tin',
            children: [
              _InfoRow(label: 'Phong', value: _text(invoice['roomName'], '')),
              _InfoRow(label: 'Nguoi thue', value: _text(invoice['tenantName'], '')),
              _InfoRow(label: 'Ky hoa don', value: _periodLabel(invoice)),
              _InfoRow(label: 'Han thanh toan', value: _dateText(invoice['dueDate'])),
              _InfoRow(label: 'Trang thai', value: _statusLabel(status)),
            ],
          ),
          const SizedBox(height: 12),
          _InvoiceSection(
            title: 'Khoan thu',
            children: [
              _InfoRow(label: 'Tien phong', value: _money(invoice['roomRent'])),
              _InfoRow(
                label: 'Tien dien',
                value:
                    '${_readInt(invoice['electricityUsage'])} so - ${_money(invoice['electricityAmount'])}',
              ),
              _InfoRow(
                label: 'Tien nuoc',
                value:
                    '${_readInt(invoice['waterUsage'])} so - ${_money(invoice['waterAmount'])}',
              ),
              _InfoRow(label: 'Phi dich vu', value: _money(invoice['serviceFee'])),
              _InfoRow(label: 'Internet', value: _money(invoice['internetFee'])),
              _InfoRow(label: 'Gui xe', value: _money(invoice['parkingFee'])),
              _InfoRow(label: 'Phu thu', value: _money(invoice['otherFee'])),
              _InfoRow(label: 'Giam tru', value: _money(invoice['discount'])),
            ],
          ),
          const SizedBox(height: 12),
          _TotalPreview(total: _readInt(invoice['totalAmount'])),
          if (paymentNote.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InvoiceSection(
              title: 'Ghi chu thanh toan',
              children: [_InfoRow(label: 'Noi dung', value: paymentNote)],
            ),
          ],
          if (status == InvoiceStatus.unpaid) ...[
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _openEditInvoice,
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Sua hoa don'),
            ),
          ],
          const SizedBox(height: 16),
          if (widget.canConfirmPayment && status != InvoiceStatus.paid) ...[
            AnimatedBuilder(
              animation: _viewModel,
              builder: (context, _) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: _viewModel.isLoading ? null : _markPaid,
                      icon: const Icon(Icons.verified_outlined),
                      label: Text(
                        status == InvoiceStatus.pending
                            ? 'Xac nhan da nhan tien'
                            : 'Danh dau da thanh toan',
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  String _adminPaymentError() {
    final error = _viewModel.errorMessage;
    if (error?.contains('permission-denied') == true) {
      return 'Firestore chua cap quyen xac nhan thanh toan.';
    }

    return 'Khong xac nhan duoc thanh toan.';
  }
}

class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.invoiceId,
    required this.data,
    required this.onTap,
  });

  final String invoiceId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? InvoiceStatus.unpaid).toString();

    return Card(
      elevation: 1,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _statusColor(status).withValues(alpha: 0.14),
          child: Icon(Icons.receipt_long_outlined, color: _statusColor(status)),
        ),
        title: Text(_text(data['roomName'], invoiceId)),
        subtitle: Text('${_periodLabel(data)} - ${_statusLabel(status)}'),
        trailing: Text(
          _money(data['totalAmount']),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? InvoiceStatus.unpaid).toString();

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _money(data['totalAmount']),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(_statusLabel(status)),
              backgroundColor: _statusColor(status).withValues(alpha: 0.12),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  const _InvoiceSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountPreview extends StatelessWidget {
  const _AmountPreview({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '$label: ${_money(value)}',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _InvoiceNotice extends StatelessWidget {
  const _InvoiceNotice({
    required this.message,
    required this.isWarning,
  });

  final String message;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? Colors.orange : Colors.blueAccent;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.warning_amber_outlined : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

class _TotalPreview extends StatelessWidget {
  const _TotalPreview({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Tong thanh toan',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Text(
            _money(total),
            style: const TextStyle(
              color: Color(0xFF2563EB),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceEmptyView extends StatelessWidget {
  const _InvoiceEmptyView({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.blueAccent, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

String _periodLabel(Map<String, dynamic> data) {
  final month = _readInt(data['month']);
  final year = _readInt(data['year']);
  return month > 0 && year > 0 ? 'Thang $month/$year' : 'Chua co ky';
}

String _dateText(Object? value) {
  if (value is! Timestamp) return 'Chua co';
  final date = value.toDate();
  return '${date.day}/${date.month}/${date.year}';
}

String _statusLabel(String status) {
  return switch (status) {
    InvoiceStatus.waitingPayment => 'Dang thanh toan PayOS',
    InvoiceStatus.pending => 'Cho xac nhan',
    InvoiceStatus.paid => 'Da thanh toan',
    InvoiceStatus.overdue => 'Qua han',
    InvoiceStatus.cancelled => 'Da huy',
    _ => 'Chua thanh toan',
  };
}

String _statusFilterText(String status) {
  return switch (status) {
    InvoiceStatus.unpaid => 'chua thanh toan ',
    InvoiceStatus.waitingPayment => 'dang thanh toan ',
    InvoiceStatus.pending => 'cho xac nhan ',
    InvoiceStatus.paid => 'da thanh toan ',
    InvoiceStatus.overdue => 'qua han ',
    InvoiceStatus.cancelled => 'da huy ',
    _ => '',
  };
}

Color _statusColor(String status) {
  return switch (status) {
    InvoiceStatus.waitingPayment => Colors.purple,
    InvoiceStatus.pending => Colors.orange,
    InvoiceStatus.paid => Colors.green,
    InvoiceStatus.overdue => Colors.redAccent,
    InvoiceStatus.cancelled => Colors.grey,
    _ => Colors.blueAccent,
  };
}

String _money(Object? value) {
  final amount = _readInt(value);
  return '$amount VND';
}

String _text(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
