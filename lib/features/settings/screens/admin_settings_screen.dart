import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import 'admin_ad_settings_screen.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({required this.user, super.key});

  final User user;

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _floorCountController = TextEditingController();
  final _roomsPerFloorController = TextEditingController();
  final _totalRoomsController = TextEditingController();
  final _defaultRentController = TextEditingController();
  final _electricityPriceController = TextEditingController();
  final _waterPriceController = TextEditingController();
  final _serviceFeeController = TextEditingController();
  final _internetFeeController = TextEditingController();
  final _parkingFeeController = TextEditingController();
  final _billCloseDayController = TextEditingController();
  final _billDueDayController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _bankIdController = TextEditingController();
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderController = TextEditingController();
  final _transferContentController = TextEditingController();
  final _rulesController = TextEditingController();

  String? _buildingId;
  String? _loadError;
  bool _isLoading = true;
  bool _isSaving = false;

  bool _wifi = true;
  bool _elevator = false;
  bool _camera = true;
  bool _parking = true;
  bool _laundry = false;
  bool _security = false;

  bool _isPublic = true;
  bool _allowPreJoinMessage = true;
  bool _allowTenantJoinRequest = true;
  bool _allowManagerApplication = true;
  bool _requireApproval = true;
  bool _autoJoinGroupChat = true;
  bool _showAddress = true;
  bool _showRoomPrice = true;
  bool _showAvailableRooms = true;

  @override
  void initState() {
    super.initState();
    _loadBuilding();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _floorCountController.dispose();
    _roomsPerFloorController.dispose();
    _totalRoomsController.dispose();
    _defaultRentController.dispose();
    _electricityPriceController.dispose();
    _waterPriceController.dispose();
    _serviceFeeController.dispose();
    _internetFeeController.dispose();
    _parkingFeeController.dispose();
    _billCloseDayController.dispose();
    _billDueDayController.dispose();
    _bankNameController.dispose();
    _bankIdController.dispose();
    _bankAccountNumberController.dispose();
    _bankAccountHolderController.dispose();
    _transferContentController.dispose();
    _rulesController.dispose();
    super.dispose();
  }

  int get _effectiveTotalRooms {
    final floorCount = _readInt(_floorCountController);
    final roomsPerFloor = _readInt(_roomsPerFloorController);
    if (floorCount > 0 && roomsPerFloor > 0) {
      return floorCount * roomsPerFloor;
    }
    return _readInt(_totalRoomsController);
  }

  Future<void> _loadBuilding() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final query = await AppFirestoreService.buildings
          .where('adminId', isEqualTo: widget.user.uid)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        final amenities = _readMap(data['amenities']);
        final joinSettings = _readMap(data['joinSettings']);
        final displaySettings = _readMap(data['displaySettings']);
        final paymentSettings = _readMap(data['paymentSettings']);

        _buildingId = doc.id;
        _setText(_nameController, data['name']);
        _setText(_addressController, data['address']);
        _setText(_descriptionController, data['description']);
        _setText(_phoneController, data['phone']);
        _setText(_emailController, data['email']);
        _setText(_floorCountController, data['floorCount']);
        _setText(_roomsPerFloorController, data['roomsPerFloor']);
        _setText(_totalRoomsController, data['totalRooms']);
        _setText(_defaultRentController, data['defaultRent']);
        _setText(_electricityPriceController, data['electricityPrice']);
        _setText(_waterPriceController, data['waterPrice']);
        _setText(_serviceFeeController, data['serviceFee']);
        _setText(_internetFeeController, data['internetFee']);
        _setText(_parkingFeeController, data['parkingFee']);
        _setText(_billCloseDayController, data['billCloseDay']);
        _setText(_billDueDayController, data['billDueDay']);
        _setText(_bankNameController, paymentSettings['bankName']);
        _setText(_bankIdController, paymentSettings['bankId']);
        _setText(
          _bankAccountNumberController,
          paymentSettings['bankAccountNumber'],
        );
        _setText(
          _bankAccountHolderController,
          paymentSettings['bankAccountHolder'],
        );
        _setText(
          _transferContentController,
          paymentSettings['transferContentTemplate'],
        );
        _setText(_rulesController, data['rulesText']);

        _wifi = _readBool(amenities['wifi'], fallback: _wifi);
        _elevator = _readBool(amenities['elevator'], fallback: _elevator);
        _camera = _readBool(amenities['camera'], fallback: _camera);
        _parking = _readBool(amenities['parking'], fallback: _parking);
        _laundry = _readBool(amenities['laundry'], fallback: _laundry);
        _security = _readBool(amenities['security'], fallback: _security);

        _isPublic = _readBool(data['isPublic'], fallback: _isPublic);
        _allowPreJoinMessage = _readBool(
          joinSettings['allowPreJoinMessage'],
          fallback: _allowPreJoinMessage,
        );
        _allowTenantJoinRequest = _readBool(
          joinSettings['allowTenantJoinRequest'],
          fallback: _allowTenantJoinRequest,
        );
        _allowManagerApplication = _readBool(
          joinSettings['allowManagerApplication'],
          fallback: _allowManagerApplication,
        );
        _requireApproval = _readBool(
          joinSettings['requireApproval'],
          fallback: _requireApproval,
        );
        _autoJoinGroupChat = _readBool(
          joinSettings['autoJoinGroupChat'],
          fallback: _autoJoinGroupChat,
        );
        _showAddress = _readBool(
          displaySettings['showAddress'],
          fallback: _showAddress,
        );
        _showRoomPrice = _readBool(
          displaySettings['showRoomPrice'],
          fallback: _showRoomPrice,
        );
        _showAvailableRooms = _readBool(
          displaySettings['showAvailableRooms'],
          fallback: _showAvailableRooms,
        );
      }
    } on FirebaseException catch (e) {
      _loadError = e.code == 'permission-denied'
          ? 'Firestore chua cap quyen doc collection buildings.'
          : e.message ?? 'Khong tai duoc thiet lap toa nha.';
    } catch (_) {
      _loadError = 'Khong tai duoc thiet lap toa nha.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveBuilding() async {
    final buildingName = _nameController.text.trim();
    final floorCount = _readInt(_floorCountController);
    final roomsPerFloor = _readInt(_roomsPerFloorController);
    final totalRooms = _effectiveTotalRooms;
    final defaultRent = _readInt(_defaultRentController);

    if (buildingName.isEmpty) {
      _showSnack('Hay nhap ten toa nha.');
      return;
    }

    if (floorCount <= 0 || totalRooms <= 0) {
      _showSnack('Hay nhap so tang va tong so phong hop le.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final isNewBuilding = _buildingId == null;
      final doc = isNewBuilding
          ? AppFirestoreService.buildings.doc()
          : AppFirestoreService.buildings.doc(_buildingId);

      await doc.set({
        'id': doc.id,
        'adminId': widget.user.uid,
        'adminName': widget.user.displayName ?? widget.user.email ?? 'Admin',
        'name': buildingName,
        'address': _addressController.text.trim(),
        'description': _descriptionController.text.trim(),
        'phone': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'floorCount': floorCount,
        'roomsPerFloor': roomsPerFloor,
        'totalRooms': totalRooms,
        'defaultRent': defaultRent,
        'electricityPrice': _readInt(_electricityPriceController),
        'waterPrice': _readInt(_waterPriceController),
        'serviceFee': _readInt(_serviceFeeController),
        'internetFee': _readInt(_internetFeeController),
        'parkingFee': _readInt(_parkingFeeController),
        'billCloseDay': _readInt(_billCloseDayController),
        'billDueDay': _readInt(_billDueDayController),
        'rulesText': _rulesController.text.trim(),
        'amenities': {
          'wifi': _wifi,
          'elevator': _elevator,
          'camera': _camera,
          'parking': _parking,
          'laundry': _laundry,
          'security': _security,
        },
        'isPublic': _isPublic,
        'joinSettings': {
          'allowPreJoinMessage': _allowPreJoinMessage,
          'allowTenantJoinRequest': _allowTenantJoinRequest,
          'allowManagerApplication': _allowManagerApplication,
          'requireApproval': _requireApproval,
          'autoJoinGroupChat': _autoJoinGroupChat,
        },
        'displaySettings': {
          'showAddress': _showAddress,
          'showRoomPrice': _showRoomPrice,
          'showAvailableRooms': _showAvailableRooms,
        },
        'paymentSettings': {
          'bankName': _bankNameController.text.trim(),
          'bankId': _bankIdController.text.trim(),
          'bankAccountNumber': _bankAccountNumberController.text.trim(),
          'bankAccountHolder': _bankAccountHolderController.text.trim(),
          'transferContentTemplate': _transferContentController.text.trim(),
        },
        if (isNewBuilding) 'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _buildingId = doc.id;
      _totalRoomsController.text = totalRooms.toString();

      try {
        await _syncRooms(
          buildingId: doc.id,
          totalRooms: totalRooms,
          floorCount: floorCount,
          roomsPerFloor: roomsPerFloor,
          defaultRent: defaultRent,
        );
      } on FirebaseException catch (e) {
        _showSnack(
          e.code == 'permission-denied'
              ? 'Da luu toa nha, nhung Firestore chua cap quyen ghi buildings/{id}/rooms.'
              : e.message ?? 'Da luu toa nha, nhung chua dong bo duoc phong.',
        );
        return;
      }

      if (_autoJoinGroupChat) {
        try {
          await _ensureBuildingGroupChat(doc.id);
        } on FirebaseException catch (e) {
          _showSnack(
            e.code == 'permission-denied'
                ? 'Da luu toa nha va phong, nhung Firestore chua cap quyen ghi chats.'
                : e.message ?? 'Da luu toa nha va phong, nhung chua tao duoc chat.',
          );
          return;
        }
      }

      _showSnack('Da luu thiet lap va dong bo danh sach phong.');
    } on FirebaseException catch (e) {
      _showSnack(
        e.code == 'permission-denied'
            ? 'Firestore chua cap quyen ghi buildings/rooms/chats.'
            : e.message ?? 'Khong luu duoc toa nha.',
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _syncRooms({
    required String buildingId,
    required int totalRooms,
    required int floorCount,
    required int roomsPerFloor,
    required int defaultRent,
  }) async {
    if (totalRooms <= 0) return;

    final rooms = AppFirestoreService.buildingRooms(buildingId);
    final effectiveRoomsPerFloor = roomsPerFloor > 0
        ? roomsPerFloor
        : (floorCount > 0 ? (totalRooms / floorCount).ceil() : totalRooms);

    var batch = FirebaseFirestore.instance.batch();
    var operationCount = 0;

    Future<void> commitBatch() async {
      if (operationCount == 0) return;
      await batch.commit();
      batch = FirebaseFirestore.instance.batch();
      operationCount = 0;
    }

    for (var index = 1; index <= totalRooms; index++) {
      final floor = effectiveRoomsPerFloor > 0
          ? ((index - 1) ~/ effectiveRoomsPerFloor) + 1
          : 1;
      final roomInFloor = effectiveRoomsPerFloor > 0
          ? ((index - 1) % effectiveRoomsPerFloor) + 1
          : index;
      final paddedIndex = index.toString().padLeft(3, '0');
      final roomRef = rooms.doc('room_$paddedIndex');

      batch.set(roomRef, {
        'id': roomRef.id,
        'buildingId': buildingId,
        'roomNumber': index,
        'floor': floor,
        'name': 'Phong $floor${roomInFloor.toString().padLeft(2, '0')}',
        'rent': defaultRent,
        'type': 'standard',
        'maxPeople': 0,
        'area': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      operationCount++;
      if (operationCount >= 450) {
        await commitBatch();
      }
    }

    await commitBatch();
  }

  Future<void> _ensureBuildingGroupChat(String buildingId) async {
    final query = await AppFirestoreService.chats
        .where('memberIds', arrayContains: widget.user.uid)
        .get();

    final matchedChats = query.docs.where((doc) {
      final chat = doc.data();
      return chat['type'] == ChatType.group && chat['buildingId'] == buildingId;
    }).toList();

    if (matchedChats.isNotEmpty) {
      await matchedChats.first.reference.update({
        'memberIds': FieldValue.arrayUnion([widget.user.uid]),
        'deletedFor': FieldValue.arrayRemove([widget.user.uid]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await AppFirestoreService.chats.add({
      'type': ChatType.group,
      'buildingId': buildingId,
      'ownerId': widget.user.uid,
      'title': _nameController.text.trim().isEmpty
          ? 'Nhom chat toa nha'
          : _nameController.text.trim(),
      'memberIds': [widget.user.uid],
      'deletedFor': [],
      'isDeleted': false,
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _openAdSettings() {
    final buildingId = _buildingId;
    if (buildingId == null || buildingId.isEmpty) {
      _showSnack('Hay luu thiet lap toa nha truoc khi tao quang cao.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminAdSettingsScreen(
          user: widget.user,
          buildingId: buildingId,
        ),
      ),
    );
  }

  void _setText(TextEditingController controller, Object? value) {
    controller.text = value?.toString() ?? '';
  }

  int _readInt(TextEditingController controller) {
    final raw = controller.text.trim().replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(raw) ?? 0;
  }

  bool _readBool(Object? value, {required bool fallback}) {
    if (value is bool) return value;
    return fallback;
  }

  Map<String, dynamic> _readMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_loadError != null) {
      return _PermissionErrorView(message: _loadError!, onRetry: _loadBuilding);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Thiet lap toa nha',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Du lieu o day se duoc dung cho phong, hoa don, tim kiem va phe duyet sau nay.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.black54,
              ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _openAdSettings,
          icon: const Icon(Icons.campaign_outlined),
          label: const Text('Thiet lap quang cao'),
        ),
        const SizedBox(height: 16),
        _SettingsSection(
          title: 'Thong tin chung',
          children: [
            _buildTextField(_nameController, 'Ten toa nha'),
            _buildTextField(_addressController, 'Dia chi toa nha'),
            _buildTextField(
              _descriptionController,
              'Mo ta ngan',
              maxLines: 3,
            ),
            _buildTextField(
              _phoneController,
              'So dien thoai lien he',
              keyboardType: TextInputType.phone,
            ),
            _buildTextField(
              _emailController,
              'Email lien he',
              keyboardType: TextInputType.emailAddress,
            ),
          ],
        ),
        _SettingsSection(
          title: 'So do phong',
          children: [
            _buildTextField(
              _floorCountController,
              'So tang',
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            _buildTextField(
              _roomsPerFloorController,
              'So phong moi tang',
              keyboardType: TextInputType.number,
              helperText: 'Nhap muc nay de app tu tinh tong so phong.',
              onChanged: (_) => setState(() {}),
            ),
            _buildTextField(
              _totalRoomsController,
              'Tong so phong',
              keyboardType: TextInputType.number,
              helperText:
                  'Hien tai se dong bo $_effectiveTotalRooms phong khi bam luu.',
              onChanged: (_) => setState(() {}),
            ),
            _buildTextField(
              _defaultRentController,
              'Tien thue mac dinh cho phong',
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        _SettingsSection(
          title: 'Gia dich vu va hoa don',
          children: [
            _buildTextField(
              _electricityPriceController,
              'Gia dien',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              _waterPriceController,
              'Gia nuoc',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              _serviceFeeController,
              'Phi dich vu',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              _internetFeeController,
              'Phi internet',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(
              _parkingFeeController,
              'Phi gui xe',
              keyboardType: TextInputType.number,
            ),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _billCloseDayController,
                    'Ngay chot so',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    _billDueDayController,
                    'Han dong tien',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
        _SettingsSection(
          title: 'Thong tin chuyen khoan',
          children: [
            _buildTextField(_bankNameController, 'Ten ngan hang'),
            _buildTextField(
              _bankIdController,
              'Ma ngan hang VietQR',
              helperText: 'Nhap BIN hoac code ngan hang, vi du VCB, MB, 970436.',
            ),
            _buildTextField(
              _bankAccountNumberController,
              'So tai khoan',
              keyboardType: TextInputType.number,
            ),
            _buildTextField(_bankAccountHolderController, 'Chu tai khoan'),
            _buildTextField(
              _transferContentController,
              'Noi dung chuyen khoan mau',
              helperText:
                  'Co the dung {room}, {month}, {year}, {name} de app tu thay.',
              maxLines: 2,
            ),
          ],
        ),
        _SettingsSection(
          title: 'Tien ich',
          children: [
            _buildSwitch('Wifi', _wifi, (value) => setState(() => _wifi = value)),
            _buildSwitch(
              'Thang may',
              _elevator,
              (value) => setState(() => _elevator = value),
            ),
            _buildSwitch(
              'Camera',
              _camera,
              (value) => setState(() => _camera = value),
            ),
            _buildSwitch(
              'Cho de xe',
              _parking,
              (value) => setState(() => _parking = value),
            ),
            _buildSwitch(
              'May giat',
              _laundry,
              (value) => setState(() => _laundry = value),
            ),
            _buildSwitch(
              'Bao ve',
              _security,
              (value) => setState(() => _security = value),
            ),
          ],
        ),
        _SettingsSection(
          title: 'Tham gia va hien thi',
          children: [
            _buildSwitch(
              'Cong khai toa nha',
              _isPublic,
              (value) => setState(() => _isPublic = value),
            ),
            _buildSwitch(
              'Cho nhan tin truoc khi tham gia',
              _allowPreJoinMessage,
              (value) => setState(() => _allowPreJoinMessage = value),
            ),
            _buildSwitch(
              'Cho nguoi thue xin vao toa nha',
              _allowTenantJoinRequest,
              (value) => setState(() => _allowTenantJoinRequest = value),
            ),
            _buildSwitch(
              'Cho quan ly ung tuyen',
              _allowManagerApplication,
              (value) => setState(() => _allowManagerApplication = value),
            ),
            _buildSwitch(
              'Can admin phe duyet',
              _requireApproval,
              (value) => setState(() => _requireApproval = value),
            ),
            _buildSwitch(
              'Tu dong vao nhom chat toa nha',
              _autoJoinGroupChat,
              (value) => setState(() => _autoJoinGroupChat = value),
            ),
            _buildSwitch(
              'Hien dia chi',
              _showAddress,
              (value) => setState(() => _showAddress = value),
            ),
            _buildSwitch(
              'Hien gia phong',
              _showRoomPrice,
              (value) => setState(() => _showRoomPrice = value),
            ),
            _buildSwitch(
              'Hien so phong trong',
              _showAvailableRooms,
              (value) => setState(() => _showAvailableRooms = value),
            ),
          ],
        ),
        _SettingsSection(
          title: 'Noi quy',
          children: [
            _buildTextField(
              _rulesController,
              'Noi quy toa nha',
              maxLines: 5,
            ),
          ],
        ),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveBuilding,
          icon: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_outlined),
          label: const Text('Luu thiet lap'),
        ),
      ],
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? helperText,
    ValueChanged<String>? onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _PermissionErrorView extends StatelessWidget {
  const _PermissionErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, color: Colors.redAccent, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Thu lai'),
            ),
          ],
        ),
      ),
    );
  }
}
