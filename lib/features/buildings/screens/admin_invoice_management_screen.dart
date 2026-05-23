import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';

const _allInvoiceStatus = 'all';

class _InvoiceStatusOption {
  const _InvoiceStatusOption(this.value, this.label);

  final String value;
  final String label;
}

const _invoiceStatusOptions = [
  _InvoiceStatusOption(_allInvoiceStatus, 'Tat ca'),
  _InvoiceStatusOption(InvoiceStatus.unpaid, 'Chua TT'),
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
  late int _selectedMonth;
  late int _selectedYear;
  String _selectedStatus = _allInvoiceStatus;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = now.month;
    _selectedYear = now.year;
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            AppFirestoreService.buildingInvoices(widget.buildingId).snapshots(),
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

          final invoices = (snapshot.data?.docs ?? []).toList();
          invoices.sort((left, right) {
            final leftKey = _periodSortKey(left.data());
            final rightKey = _periodSortKey(right.data());
            if (leftKey != rightKey) return rightKey.compareTo(leftKey);
            return _timestampMillis(
              right.data()['createdAt'],
            ).compareTo(_timestampMillis(left.data()['createdAt']));
          });

          final yearOptions = _yearOptions(invoices);
          final periodPicker = _InvoicePeriodPicker(
            month: _selectedMonth,
            year: _selectedYear,
            years: yearOptions,
            onMonthChanged: (value) {
              if (value == null) return;
              setState(() => _selectedMonth = value);
            },
            onYearChanged: (value) {
              if (value == null) return;
              setState(() => _selectedYear = value);
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

          final monthlyInvoices = invoices.where((doc) {
            final data = doc.data();
            return _readInt(data['month']) == _selectedMonth &&
                _readInt(data['year']) == _selectedYear;
          }).toList();
          final filteredInvoices = _filterInvoicesByStatus(monthlyInvoices);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              periodPicker,
              const SizedBox(height: 12),
              _InvoiceStatusFilterBar(
                invoices: monthlyInvoices,
                selectedStatus: _selectedStatus,
                onChanged: (status) {
                  setState(() => _selectedStatus = status);
                },
              ),
              const SizedBox(height: 12),
              if (filteredInvoices.isEmpty)
                _InvoiceEmptyView(
                  icon: Icons.event_busy_outlined,
                  message:
                      'Khong co hoa don ${_statusFilterText(_selectedStatus)}trong thang $_selectedMonth/$_selectedYear.',
                )
              else ...[
                _InvoiceMonthHeader(
                  data: {'month': _selectedMonth, 'year': _selectedYear},
                  invoiceCount: filteredInvoices.length,
                  totalAmount: filteredInvoices.fold<int>(
                    0,
                    (total, doc) => total + _readInt(doc.data()['totalAmount']),
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
                              invoiceId: doc.id,
                              invoice: doc.data(),
                              canConfirmPayment: widget.canConfirmPayment,
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
      ),
    );
  }

  List<int> _yearOptions(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices,
  ) {
    final years = <int>{DateTime.now().year, _selectedYear};
    for (final invoice in invoices) {
      final year = _readInt(invoice.data()['year']);
      if (year > 0) years.add(year);
    }
    return years.toList()..sort((left, right) => right.compareTo(left));
  }

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _filterInvoicesByStatus(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> invoices,
  ) {
    if (_selectedStatus == _allInvoiceStatus) return invoices;

    return invoices.where((doc) {
      final status = (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return status == _selectedStatus;
    }).toList();
  }

  int _periodSortKey(Map<String, dynamic> data) {
    final year = _readInt(data['year']);
    final month = _readInt(data['month']);
    return year * 100 + month;
  }

  int _timestampMillis(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
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
  });

  final String buildingId;
  final Map<String, dynamic> building;

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

  late final Future<QuerySnapshot<Map<String, dynamic>>> _roomsFuture;
  String? _selectedRoomId;
  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedRoom;
  String? _roomHistoryMessage;
  bool _hasDuplicateInvoice = false;
  bool _isLoadingRoomHistory = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _roomsFuture = AppFirestoreService.buildingRooms(widget.buildingId).get();

    final now = DateTime.now();
    _monthController.text = now.month.toString();
    _yearController.text = now.year.toString();
    _monthController.addListener(_handlePeriodChanged);
    _yearController.addListener(_handlePeriodChanged);
    _serviceFeeController.text = _readInt(widget.building['serviceFee']).toString();
    _internetFeeController.text =
        _readInt(widget.building['internetFee']).toString();
    _parkingFeeController.text = _readInt(widget.building['parkingFee']).toString();
    _otherFeeController.text = '0';
    _discountController.text = '0';

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
    super.dispose();
  }

  void _refreshTotal() {
    if (mounted) setState(() {});
  }

  void _handlePeriodChanged() {
    if (_selectedRoom == null) return;

    setState(() {
      _hasDuplicateInvoice = false;
      _roomHistoryMessage =
          'Ky hoa don da thay doi. Khi luu app se kiem tra trung ky voi ky moi.';
    });
  }

  void _selectRoom(QueryDocumentSnapshot<Map<String, dynamic>> roomDoc) {
    final room = roomDoc.data();
    final roomRent = _readInt(room['rent']);
    final defaultRent = _readInt(widget.building['defaultRent']);

    setState(() {
      _selectedRoomId = roomDoc.id;
      _selectedRoom = roomDoc;
      _roomHistoryMessage = null;
      _hasDuplicateInvoice = false;
      _roomRentController.text =
          (roomRent > 0 ? roomRent : defaultRent).toString();
      _electricityOldController.text = '0';
      _waterOldController.text = '0';
    });

    _loadRoomInvoiceContext(roomDoc.id);
  }

  Future<void> _loadRoomInvoiceContext(String roomId) async {
    setState(() => _isLoadingRoomHistory = true);

    try {
      final invoices = await _fetchRoomInvoices(roomId);
      if (!mounted || _selectedRoomId != roomId) return;

      final currentPeriod = _periodKeyFromControllers();
      final duplicateInvoice = invoices.where((invoice) {
        return _periodKey(invoice) == currentPeriod;
      }).toList();

      final previousInvoices = invoices.where((invoice) {
        return _periodKey(invoice) < currentPeriod;
      }).toList()
        ..sort((left, right) => _periodKey(right).compareTo(_periodKey(left)));

      setState(() {
        _hasDuplicateInvoice = duplicateInvoice.isNotEmpty;

        if (previousInvoices.isNotEmpty) {
          final previous = previousInvoices.first;
          final electricityNew = _readInt(previous['electricityNew']);
          final waterNew = _readInt(previous['waterNew']);
          _electricityOldController.text = electricityNew.toString();
          _waterOldController.text = waterNew.toString();
          _roomHistoryMessage =
              'Da lay chi so cu tu hoa don ${_periodLabel(previous)}.';
        } else {
          _roomHistoryMessage =
              'Chua co hoa don truoc do, chi so cu dang mac dinh la 0.';
        }

        if (_hasDuplicateInvoice) {
          _roomHistoryMessage =
              'Phong nay da co hoa don ${_monthController.text}/${_yearController.text}. Hay kiem tra lai truoc khi tao moi.';
        }
      });
    } on FirebaseException catch (e) {
      if (!mounted || _selectedRoomId != roomId) return;
      setState(() {
        _roomHistoryMessage = e.code == 'permission-denied'
            ? 'Firestore chua cap quyen doc hoa don cu.'
            : e.message ?? 'Khong tai duoc hoa don cu.';
      });
    } finally {
      if (mounted && _selectedRoomId == roomId) {
        setState(() => _isLoadingRoomHistory = false);
      }
    }
  }

  Future<void> _saveInvoice() async {
    final roomDoc = _selectedRoom;
    if (roomDoc == null) {
      _showSnack('Hay chon phong can tao hoa don.');
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
      existingInvoices = await _fetchRoomInvoices(roomDoc.id);
    } on FirebaseException catch (e) {
      _showSnack(
        e.code == 'permission-denied'
            ? 'Firestore chua cap quyen kiem tra hoa don cu.'
            : e.message ?? 'Khong kiem tra duoc hoa don cu.',
      );
      return;
    }

    final currentPeriod = _periodKey(null, year: year, month: month);
    final hasDuplicate = existingInvoices.any((invoice) {
      return _periodKey(invoice) == currentPeriod;
    });
    if (hasDuplicate) {
      if (mounted) setState(() => _hasDuplicateInvoice = true);
      _showSnack('Phong nay da co hoa don thang $month/$year.');
      return;
    }

    setState(() => _isSaving = true);

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

      await AppFirestoreService.buildingInvoices(widget.buildingId).add({
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
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      _showSnack(
        e.code == 'permission-denied'
            ? 'Firestore chua cap quyen tao hoa don.'
            : e.message ?? 'Khong tao duoc hoa don.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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

  Future<List<Map<String, dynamic>>> _fetchRoomInvoices(String roomId) async {
    final snapshot =
        await AppFirestoreService.buildingInvoices(widget.buildingId).get();
    return snapshot.docs
        .map((doc) => doc.data())
        .where((invoice) => invoice['roomId'] == roomId)
        .where((invoice) => invoice['status'] != InvoiceStatus.cancelled)
        .toList();
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
      appBar: AppBar(title: const Text('Tao hoa don')),
      body: FutureBuilder<QuerySnapshot<Map<String, dynamic>>>(
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedRoomId,
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
              if (_isLoadingRoomHistory) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(minHeight: 2),
              ] else if (_roomHistoryMessage != null) ...[
                const SizedBox(height: 10),
                _InvoiceNotice(
                  message: _roomHistoryMessage!,
                  isWarning: _hasDuplicateInvoice,
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
                onPressed: _isSaving || _hasDuplicateInvoice
                    ? null
                    : _saveInvoice,
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Luu hoa don'),
              ),
            ],
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

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
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
    required this.invoiceId,
    required this.invoice,
    required this.canConfirmPayment,
  });

  final String buildingId;
  final String invoiceId;
  final Map<String, dynamic> invoice;
  final bool canConfirmPayment;

  @override
  State<_AdminInvoiceDetailScreen> createState() =>
      _AdminInvoiceDetailScreenState();
}

class _AdminInvoiceDetailScreenState extends State<_AdminInvoiceDetailScreen> {
  bool _isSaving = false;

  Future<void> _markPaid() async {
    setState(() => _isSaving = true);

    try {
      await AppFirestoreService.buildingInvoices(widget.buildingId)
          .doc(widget.invoiceId)
          .update({
        'status': InvoiceStatus.paid,
        'paymentMethod': 'admin_confirmed',
        'paidAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firestore chua cap quyen xac nhan thanh toan.'
                : e.message ?? 'Khong xac nhan duoc thanh toan.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _rejectPayment() async {
    setState(() => _isSaving = true);

    try {
      await AppFirestoreService.buildingInvoices(widget.buildingId)
          .doc(widget.invoiceId)
          .update({
        'status': InvoiceStatus.unpaid,
        'paymentMethod': FieldValue.delete(),
        'paymentNote': FieldValue.delete(),
        'paidReportedAt': FieldValue.delete(),
        'paymentRejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firestore chua cap quyen tu choi thanh toan.'
                : e.message ?? 'Khong tu choi duoc thanh toan.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
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
          const SizedBox(height: 16),
          if (widget.canConfirmPayment && status != InvoiceStatus.paid) ...[
            FilledButton.icon(
              onPressed: _isSaving ? null : _markPaid,
              icon: const Icon(Icons.verified_outlined),
              label: Text(
                status == InvoiceStatus.pending
                    ? 'Xac nhan da nhan tien'
                    : 'Danh dau da thanh toan',
              ),
            ),
            if (status == InvoiceStatus.pending) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _isSaving ? null : _rejectPayment,
                icon: const Icon(Icons.close_outlined),
                label: const Text('Tu choi thanh toan'),
              ),
            ],
          ],
        ],
      ),
    );
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
    InvoiceStatus.pending => 'cho xac nhan ',
    InvoiceStatus.paid => 'da thanh toan ',
    InvoiceStatus.overdue => 'qua han ',
    InvoiceStatus.cancelled => 'da huy ',
    _ => '',
  };
}

Color _statusColor(String status) {
  return switch (status) {
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
