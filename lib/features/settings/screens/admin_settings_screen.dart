import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../view_models/admin_settings_view_model.dart';
import 'admin_ad_settings_screen.dart';

const _payosBackendBaseUrl = String.fromEnvironment(
  'PAYOS_BACKEND_URL',
  defaultValue: '',
);

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
  final _bankAccountNumberController = TextEditingController();
  final _bankAccountHolderController = TextEditingController();
  final _transferContentController = TextEditingController();
  final _payosClientIdController = TextEditingController();
  final _payosApiKeyController = TextEditingController();
  final _payosChecksumKeyController = TextEditingController();
  final _rulesController = TextEditingController();
  final _viewModel = AdminSettingsViewModel();

  String? _buildingId;
  String? _loadError;
  String? _payosStatusMessage;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isPayosSaving = false;
  bool _isPayosConfigured = false;

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
    _bankAccountNumberController.dispose();
    _bankAccountHolderController.dispose();
    _transferContentController.dispose();
    _payosClientIdController.dispose();
    _payosApiKeyController.dispose();
    _payosChecksumKeyController.dispose();
    _rulesController.dispose();
    _viewModel.dispose();
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

    final result = await _viewModel.loadBuilding(widget.user.uid);

    if (result == null) {
      _loadError = _settingsErrorMessage(
        permissionMessage: 'Firestore chua cap quyen doc collection buildings.',
        fallbackMessage: 'Khong tai duoc thiet lap toa nha.',
      );
    } else if (result.buildingId != null) {
      _fillBuildingForm(result.buildingId!, result.data);
      await _loadPayosSettings(result.buildingId!);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _fillBuildingForm(String buildingId, Map<String, dynamic> data) {
    final amenities = _readMap(data['amenities']);
    final joinSettings = _readMap(data['joinSettings']);
    final displaySettings = _readMap(data['displaySettings']);
    final paymentSettings = _readMap(data['paymentSettings']);

    _buildingId = buildingId;
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

  Future<void> _loadPayosSettings(String buildingId) async {
    if (_payosBackendBaseUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isPayosConfigured = false;
        _payosStatusMessage =
            'Chua cau hinh PAYOS_BACKEND_URL cho app Flutter.';
      });
      return;
    }

    try {
      final idToken = await widget.user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Khong lay duoc Firebase ID token.');
      }

      final data = await _viewModel.loadPayosSettings(
        backendBaseUrl: _payosBackendBaseUrl,
        idToken: idToken,
        buildingId: buildingId,
      );

      if (!mounted) return;
      final configured = data?['configured'] == true;
      final clientIdTail = data?['clientIdTail']?.toString() ?? '';

      setState(() {
        _isPayosConfigured = configured;
        _payosStatusMessage = configured
            ? 'Da cau hinh PayOS cho toa nha nay. Client ID ket thuc bang $clientIdTail.'
            : 'Chua cau hinh PayOS rieng cho toa nha nay.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPayosConfigured = false;
        _payosStatusMessage = 'Khong tai duoc cau hinh PayOS: $error';
      });
    }
  }

  Future<void> _savePayosSettings() async {
    final buildingId = _buildingId;
    final clientId = _payosClientIdController.text.trim();
    final apiKey = _payosApiKeyController.text.trim();
    final checksumKey = _payosChecksumKeyController.text.trim();

    if (buildingId == null || buildingId.isEmpty) {
      _showSnack('Hay luu thiet lap toa nha truoc khi cau hinh PayOS.');
      return;
    }

    if (_payosBackendBaseUrl.isEmpty) {
      _showSnack('Chua cau hinh PAYOS_BACKEND_URL cho app Flutter.');
      return;
    }

    if (clientId.isEmpty || apiKey.isEmpty || checksumKey.isEmpty) {
      _showSnack('Hay nhap du Client ID, API Key va Checksum Key PayOS.');
      return;
    }

    setState(() => _isPayosSaving = true);

    Map<String, dynamic>? data;
    try {
      final idToken = await widget.user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Khong lay duoc Firebase ID token.');
      }

      data = await _viewModel.savePayosSettings(
        backendBaseUrl: _payosBackendBaseUrl,
        idToken: idToken,
        buildingId: buildingId,
        clientId: clientId,
        apiKey: apiKey,
        checksumKey: checksumKey,
      );
    } catch (error) {
      if (!mounted) return;
      _showSnack('Khong luu duoc cau hinh PayOS: $error');
      setState(() => _isPayosSaving = false);
      return;
    }

    if (!mounted) return;

    if (data == null) {
      _showSnack(
        _viewModel.errorMessage ?? 'Khong luu duoc cau hinh PayOS.',
      );
      setState(() => _isPayosSaving = false);
      return;
    }

    final clientIdTail = data['clientIdTail']?.toString() ?? '';
    _payosClientIdController.clear();
    _payosApiKeyController.clear();
    _payosChecksumKeyController.clear();

    setState(() {
      _isPayosSaving = false;
      _isPayosConfigured = true;
      _payosStatusMessage =
          'Da luu PayOS cho toa nha. Client ID ket thuc bang $clientIdTail.';
    });
    _showSnack('Da luu cau hinh PayOS cho toa nha.');
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

    final result = await _viewModel.saveBuilding(
      buildingId: _buildingId,
      data: _buildingData(
        buildingName: buildingName,
        floorCount: floorCount,
        roomsPerFloor: roomsPerFloor,
        totalRooms: totalRooms,
        defaultRent: defaultRent,
      ),
      userId: widget.user.uid,
      buildingName: buildingName,
      totalRooms: totalRooms,
      floorCount: floorCount,
      roomsPerFloor: roomsPerFloor,
      defaultRent: defaultRent,
      autoJoinGroupChat: _autoJoinGroupChat,
    );

    if (result.buildingId != null) {
      _buildingId = result.buildingId;
      _totalRoomsController.text = totalRooms.toString();
    }

    _showSnack(_saveResultMessage(result.status));

    if (mounted) setState(() => _isSaving = false);
  }

  Map<String, dynamic> _buildingData({
    required String buildingName,
    required int floorCount,
    required int roomsPerFloor,
    required int totalRooms,
    required int defaultRent,
  }) {
    return {
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
        'bankAccountNumber': _bankAccountNumberController.text.trim(),
        'bankAccountHolder': _bankAccountHolderController.text.trim(),
        'transferContentTemplate': _transferContentController.text.trim(),
      },
    };
  }

  String _saveResultMessage(AdminSettingsSaveStatus status) {
    if (status == AdminSettingsSaveStatus.saved) {
      return 'Da luu thiet lap va dong bo danh sach phong.';
    }

    if (status == AdminSettingsSaveStatus.savedWithoutRooms) {
      return _settingsErrorMessage(
        permissionMessage:
            'Da luu toa nha, nhung Firestore chua cap quyen ghi buildings/{id}/rooms.',
        fallbackMessage: 'Da luu toa nha, nhung chua dong bo duoc phong.',
      );
    }

    if (status == AdminSettingsSaveStatus.savedWithoutChat) {
      return _settingsErrorMessage(
        permissionMessage:
            'Da luu toa nha va phong, nhung Firestore chua cap quyen ghi chats.',
        fallbackMessage:
            'Da luu toa nha va phong, nhung chua tao duoc chat.',
      );
    }

    return _settingsErrorMessage(
      permissionMessage: 'Firestore chua cap quyen ghi buildings/rooms/chats.',
      fallbackMessage: 'Khong luu duoc toa nha.',
    );
  }

  String _settingsErrorMessage({
    required String permissionMessage,
    required String fallbackMessage,
  }) {
    if (_viewModel.errorMessage?.contains('permission-denied') == true) {
      return permissionMessage;
    }

    return fallbackMessage;
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
          title: 'PayOS tu dong',
          children: [
            _PayosStatusBox(
              configured: _isPayosConfigured,
              message: _payosStatusMessage ??
                  'PayOS se tu xac nhan hoa don khi ngan hang bao giao dich.',
            ),
            const SizedBox(height: 12),
            _buildTextField(
              _payosClientIdController,
              'Client ID PayOS',
              obscureText: true,
            ),
            _buildTextField(
              _payosApiKeyController,
              'API Key PayOS',
              obscureText: true,
            ),
            _buildTextField(
              _payosChecksumKeyController,
              'Checksum Key PayOS',
              obscureText: true,
              helperText:
                  'App khong hien lai key cu. Nhap du 3 o neu muon cap nhat.',
            ),
            FilledButton.icon(
              onPressed: _isPayosSaving ? null : _savePayosSettings,
              icon: _isPayosSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_user_outlined),
              label: Text(
                _isPayosConfigured ? 'Cap nhat PayOS' : 'Luu cau hinh PayOS',
              ),
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
    bool obscureText = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: onChanged,
        obscureText: obscureText,
        enableSuggestions: !obscureText,
        autocorrect: !obscureText,
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

class _PayosStatusBox extends StatelessWidget {
  const _PayosStatusBox({
    required this.configured,
    required this.message,
  });

  final bool configured;
  final String message;

  @override
  Widget build(BuildContext context) {
    final color = configured ? Colors.green : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            configured ? Icons.check_circle_outline : Icons.info_outline,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
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
