import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/data/vietnam_admin_units.dart';
import '../../../core/theme/app_theme.dart';
import '../view_models/admin_settings_view_model.dart';
import 'admin_access_display_settings_screen.dart';
import 'admin_ad_settings_screen.dart';
import 'admin_building_info_settings_screen.dart';
import 'admin_payment_settings_screen.dart';
import 'admin_room_billing_settings_screen.dart';
import 'admin_rules_settings_screen.dart';
import 'admin_settings_widgets.dart';
import 'building_location_picker_screen.dart';

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
  final _provinceController = TextEditingController();
  final _wardController = TextEditingController();
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
  Map<String, dynamic> _selectedLocation = {};

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
    _provinceController.dispose();
    _wardController.dispose();
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
        permissionMessage: 'Firestore chưa cấp quyền doc collection buildings.',
        fallbackMessage: 'Không tải được thiết lập tòa nhà.',
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
    _selectedLocation = _readMap(data['location']);
    _setText(_nameController, data['name']);
    _setText(_addressController, data['address']);
    _setText(
      _provinceController,
      data['province'] ?? _selectedLocation['province'],
    );
    _setText(_wardController, data['ward'] ?? _selectedLocation['ward']);
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

  Future<void> _loadPayosSettings(String buildingId) async {
    if (_payosBackendBaseUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isPayosConfigured = false;
        _payosStatusMessage =
            'Chưa cấu hình PAYOS_BACKEND_URL cho app Flutter.';
      });
      return;
    }

    try {
      final idToken = await widget.user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Không lấy được Firebase ID token.');
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
            ? 'Đã cấu hình PayOS cho tòa nhà này. Client ID kết thúc bằng $clientIdTail.'
            : 'Chưa cấu hình PayOS riêng cho tòa nhà này.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isPayosConfigured = false;
        _payosStatusMessage = 'Không tải được cấu hình PayOS: $error';
      });
    }
  }

  Future<void> _savePayosSettings() async {
    final buildingId = _buildingId;
    final clientId = _payosClientIdController.text.trim();
    final apiKey = _payosApiKeyController.text.trim();
    final checksumKey = _payosChecksumKeyController.text.trim();

    if (buildingId == null || buildingId.isEmpty) {
      _showSnack('Hãy lưu thiết lập tòa nhà trước khi cấu hình PayOS.');
      return;
    }

    if (_payosBackendBaseUrl.isEmpty) {
      _showSnack('Chưa cấu hình PAYOS_BACKEND_URL cho app Flutter.');
      return;
    }

    if (clientId.isEmpty || apiKey.isEmpty || checksumKey.isEmpty) {
      _showSnack('Hãy nhập du Client ID, API Key và Checksum Key PayOS.');
      return;
    }

    setState(() => _isPayosSaving = true);

    Map<String, dynamic>? data;
    try {
      final idToken = await widget.user.getIdToken();
      if (idToken == null || idToken.isEmpty) {
        throw StateError('Không lấy được Firebase ID token.');
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
      _showSnack('Không lưu được cấu hình PayOS: $error');
      setState(() => _isPayosSaving = false);
      return;
    }

    if (!mounted) return;

    if (data == null) {
      _showSnack(_viewModel.errorMessage ?? 'Không lưu được cấu hình PayOS.');
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
          'Đã lưu PayOS cho tòa nhà. Client ID kết thúc bằng $clientIdTail.';
    });
    _showSnack('Đã lưu cấu hình PayOS cho tòa nhà.');
  }

  Future<void> _saveBuilding() async {
    final buildingName = _nameController.text.trim();
    final floorCount = _readInt(_floorCountController);
    final roomsPerFloor = _readInt(_roomsPerFloorController);
    final totalRooms = _effectiveTotalRooms;
    final defaultRent = _readInt(_defaultRentController);
    final province = _provinceController.text.trim();
    final ward = _wardController.text.trim();

    if (buildingName.isEmpty) {
      _showSnack('Hãy nhập tên tòa nhà.');
      return;
    }

    if (province.isEmpty) {
      _showSnack('Hãy chọn tỉnh/thành pho cua tòa nhà.');
      return;
    }

    if (ward.isEmpty) {
      _showSnack('Hãy nhập xã/phường cua tòa nhà.');
      return;
    }

    if (floorCount <= 0 || totalRooms <= 0) {
      _showSnack('Hãy nhập số tầng và tổng số phòng hợp lệ.');
      return;
    }

    setState(() => _isSaving = true);
    final location = await _locationForSave();
    if (!mounted) return;

    final result = await _viewModel.saveBuilding(
      buildingId: _buildingId,
      data: _buildingData(
        buildingName: buildingName,
        floorCount: floorCount,
        roomsPerFloor: roomsPerFloor,
        totalRooms: totalRooms,
        defaultRent: defaultRent,
        location: location,
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

  String _fullBuildingAddress() {
    return [
      _addressController.text.trim(),
      _wardController.text.trim(),
      _provinceController.text.trim(),
    ].where((part) => part.isNotEmpty).join(', ');
  }

  Future<Map<String, dynamic>> _locationForSave() async {
    final selectedLat = _readDouble(_selectedLocation['lat']);
    final selectedLng = _readDouble(_selectedLocation['lng']);
    final address = _addressController.text.trim();
    final province = _provinceController.text.trim();
    final ward = _wardController.text.trim();
    final fullAddress = _fullBuildingAddress();

    if (selectedLat != null && selectedLng != null) {
      final formattedAddress =
          _selectedLocation['formattedAddress']?.toString().trim() ?? '';

      return {
        ..._selectedLocation,
        'address': address,
        'province': province,
        'ward': ward,
        'fullAddress': fullAddress,
        'formattedAddress': formattedAddress.isEmpty
            ? (fullAddress.isEmpty ? address : fullAddress)
            : formattedAddress,
        'lat': selectedLat,
        'lng': selectedLng,
        'source': _selectedLocation['source'] ?? 'manual_map_picker',
      };
    }

    final resolved = await _viewModel.resolveBuildingLocation(
      fullAddress.isEmpty ? address : fullAddress,
    );
    final resolvedFormatted =
        resolved['formattedAddress']?.toString().trim() ?? '';

    return {
      ...resolved,
      'address': address,
      'province': province,
      'ward': ward,
      'fullAddress': fullAddress,
      'formattedAddress': resolvedFormatted.isEmpty
          ? (fullAddress.isEmpty ? address : fullAddress)
          : resolvedFormatted,
    };
  }

  Map<String, dynamic> _buildingData({
    required String buildingName,
    required int floorCount,
    required int roomsPerFloor,
    required int totalRooms,
    required int defaultRent,
    required Map<String, dynamic> location,
  }) {
    return {
      'adminId': widget.user.uid,
      'adminName': widget.user.displayName ?? widget.user.email ?? 'Admin',
      'name': buildingName,
      'address': _addressController.text.trim(),
      'province': _provinceController.text.trim(),
      'ward': _wardController.text.trim(),
      'provinceNormalized': normalizeVietnamAdminText(_provinceController.text),
      'wardNormalized': normalizeVietnamAdminText(_wardController.text),
      'fullAddress': _fullBuildingAddress(),
      'description': _descriptionController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'location': location,
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
    };
  }

  String _saveResultMessage(AdminSettingsSaveStatus status) {
    if (status == AdminSettingsSaveStatus.saved) {
      return 'Đã lưu thiết lập và đồng bộ danh sách phòng.';
    }

    if (status == AdminSettingsSaveStatus.savedWithoutRooms) {
      return _settingsErrorMessage(
        permissionMessage:
            'Đã lưu tòa nhà, nhưng Firestore chưa cấp quyền ghi buildings/{id}/rooms.',
        fallbackMessage: 'Đã lưu tòa nhà, nhưng chưa đồng bộ được phòng.',
      );
    }

    if (status == AdminSettingsSaveStatus.savedWithoutChat) {
      return _settingsErrorMessage(
        permissionMessage:
            'Đã lưu tòa nhà và phòng, nhưng Firestore chưa cấp quyền ghi chats.',
        fallbackMessage: 'Đã lưu tòa nhà và phòng, nhưng chưa tạo được chat.',
      );
    }

    return _settingsErrorMessage(
      permissionMessage: 'Firestore chưa cấp quyền ghi buildings/rooms/chats.',
      fallbackMessage: 'Không lưu được tòa nhà.',
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _openAdSettings() {
    final buildingId = _buildingId;
    if (buildingId == null || buildingId.isEmpty) {
      _showSnack('Hãy lưu thiết lập tòa nhà trước khi tạo quảng cáo.');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            AdminAdSettingsScreen(user: widget.user, buildingId: buildingId),
      ),
    );
  }

  Future<Map<String, dynamic>?> _openLocationPicker() async {
    final fullAddress = _fullBuildingAddress();
    final initialLocation = {
      ..._selectedLocation,
      'province': _provinceController.text.trim(),
      'ward': _wardController.text.trim(),
      'fullAddress': fullAddress,
    };

    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (_) => BuildingLocationPickerScreen(
          initialAddress: fullAddress.isEmpty
              ? _addressController.text
              : fullAddress,
          initialLocation: initialLocation,
        ),
      ),
    );

    if (!mounted || result == null) return null;

    final address = result['address']?.toString().trim() ?? '';
    final nextLocation = {
      ...result,
      'province': _provinceController.text.trim(),
      'ward': _wardController.text.trim(),
      'fullAddress': _fullBuildingAddress(),
    };

    setState(() {
      _selectedLocation = nextLocation;
      if (address.isNotEmpty) {
        _addressController.text = address;
      }
    });

    return nextLocation;
  }

  void _setText(TextEditingController controller, Object? value) {
    controller.text = value?.toString() ?? '';
  }

  int _readInt(TextEditingController controller) {
    final raw = controller.text.trim().replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(raw) ?? 0;
  }

  double? _readDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
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

  void _syncLocationFields() {
    if (!mounted) return;
    setState(() {
      _selectedLocation = {
        ..._selectedLocation,
        'province': _provinceController.text.trim(),
        'ward': _wardController.text.trim(),
        'fullAddress': _fullBuildingAddress(),
      };
    });
  }

  void _openSettingsPage(Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)).then((
      _,
    ) {
      if (mounted) setState(() {});
    });
  }

  void _openBuildingInfoSettings() {
    _openSettingsPage(
      AdminBuildingInfoSettingsScreen(
        nameController: _nameController,
        provinceController: _provinceController,
        wardController: _wardController,
        addressController: _addressController,
        descriptionController: _descriptionController,
        phoneController: _phoneController,
        emailController: _emailController,
        selectedLocation: _selectedLocation,
        onLocationFieldsChanged: _syncLocationFields,
        onPickLocation: _openLocationPicker,
        onSave: _saveBuilding,
      ),
    );
  }

  void _openRoomBillingSettings() {
    _openSettingsPage(
      AdminRoomBillingSettingsScreen(
        floorCountController: _floorCountController,
        roomsPerFloorController: _roomsPerFloorController,
        totalRoomsController: _totalRoomsController,
        defaultRentController: _defaultRentController,
        electricityPriceController: _electricityPriceController,
        waterPriceController: _waterPriceController,
        serviceFeeController: _serviceFeeController,
        internetFeeController: _internetFeeController,
        parkingFeeController: _parkingFeeController,
        billCloseDayController: _billCloseDayController,
        billDueDayController: _billDueDayController,
        effectiveTotalRooms: () => _effectiveTotalRooms,
        onSave: _saveBuilding,
      ),
    );
  }

  void _openPaymentSettings() {
    _openSettingsPage(
      AdminPaymentSettingsScreen(
        bankNameController: _bankNameController,
        bankIdController: _bankIdController,
        bankAccountNumberController: _bankAccountNumberController,
        bankAccountHolderController: _bankAccountHolderController,
        transferContentController: _transferContentController,
        payosClientIdController: _payosClientIdController,
        payosApiKeyController: _payosApiKeyController,
        payosChecksumKeyController: _payosChecksumKeyController,
        payosConfigured: _isPayosConfigured,
        payosStatusMessage: _payosStatusMessage,
        onSaveBuilding: _saveBuilding,
        onSavePayosSettings: _savePayosSettings,
        getPayosConfigured: () => _isPayosConfigured,
        getPayosStatusMessage: () => _payosStatusMessage,
      ),
    );
  }

  void _openAccessDisplaySettings() {
    _openSettingsPage(
      AdminAccessDisplaySettingsScreen(
        wifi: _wifi,
        elevator: _elevator,
        camera: _camera,
        parking: _parking,
        laundry: _laundry,
        security: _security,
        isPublic: _isPublic,
        allowPreJoinMessage: _allowPreJoinMessage,
        allowTenantJoinRequest: _allowTenantJoinRequest,
        allowManagerApplication: _allowManagerApplication,
        requireApproval: _requireApproval,
        autoJoinGroupChat: _autoJoinGroupChat,
        showAddress: _showAddress,
        showRoomPrice: _showRoomPrice,
        showAvailableRooms: _showAvailableRooms,
        onWifiChanged: (value) => setState(() => _wifi = value),
        onElevatorChanged: (value) => setState(() => _elevator = value),
        onCameraChanged: (value) => setState(() => _camera = value),
        onParkingChanged: (value) => setState(() => _parking = value),
        onLaundryChanged: (value) => setState(() => _laundry = value),
        onSecurityChanged: (value) => setState(() => _security = value),
        onPublicChanged: (value) => setState(() => _isPublic = value),
        onAllowPreJoinMessageChanged: (value) =>
            setState(() => _allowPreJoinMessage = value),
        onAllowTenantJoinRequestChanged: (value) =>
            setState(() => _allowTenantJoinRequest = value),
        onAllowManagerApplicationChanged: (value) =>
            setState(() => _allowManagerApplication = value),
        onRequireApprovalChanged: (value) =>
            setState(() => _requireApproval = value),
        onAutoJoinGroupChatChanged: (value) =>
            setState(() => _autoJoinGroupChat = value),
        onShowAddressChanged: (value) => setState(() => _showAddress = value),
        onShowRoomPriceChanged: (value) =>
            setState(() => _showRoomPrice = value),
        onShowAvailableRoomsChanged: (value) =>
            setState(() => _showAvailableRooms = value),
        onSave: _saveBuilding,
      ),
    );
  }

  void _openRulesSettings() {
    _openSettingsPage(
      AdminRulesSettingsScreen(
        rulesController: _rulesController,
        onSave: _saveBuilding,
      ),
    );
  }

  int _setupProgressPercent() {
    final checks = [
      _nameController.text.trim().isNotEmpty,
      _provinceController.text.trim().isNotEmpty &&
          _wardController.text.trim().isNotEmpty,
      _readInt(_floorCountController) > 0 && _effectiveTotalRooms > 0,
      _readInt(_defaultRentController) > 0,
      _phoneController.text.trim().isNotEmpty ||
          _emailController.text.trim().isNotEmpty,
      _isPayosConfigured,
      _rulesController.text.trim().isNotEmpty,
    ];

    final done = checks.where((value) => value).length;
    return ((done / checks.length) * 100).round();
  }

  List<_SettingsTaskData> _settingsTasks() {
    final tasks = <_SettingsTaskData>[];

    if (_buildingId == null || _buildingId!.isEmpty) {
      tasks.add(
        _SettingsTaskData(
          icon: Icons.save_outlined,
          title: 'Lưu thiết lập tòa nhà',
          subtitle: 'Cần lưu lần đầu để tạo tòa nhà và danh sách phòng.',
          color: AppColors.primary,
          onTap: () => _saveBuilding(),
        ),
      );
    }

    if (!_isPayosConfigured) {
      tasks.add(
        _SettingsTaskData(
          icon: Icons.payments_outlined,
          title: 'Cấu hình PayOS',
          subtitle: 'Bật thanh toán tự động cho hóa đơn phòng.',
          color: const Color(0xFFF59E0B),
          onTap: _openPaymentSettings,
        ),
      );
    }

    if (_rulesController.text.trim().isEmpty) {
      tasks.add(
        _SettingsTaskData(
          icon: Icons.article_outlined,
          title: 'Bổ sung nội quy',
          subtitle: 'Giúp người thuê nắm rõ quy định tòa nhà.',
          color: AppColors.tenantAccent,
          onTap: _openRulesSettings,
        ),
      );
    }

    if (tasks.length < 2) {
      tasks.add(
        _SettingsTaskData(
          icon: Icons.campaign_outlined,
          title: 'Kiểm tra quảng cáo',
          subtitle: 'Cập nhật nội dung và ảnh phòng đang hiển trên Trang chủ.',
          color: AppColors.managerAccent,
          onTap: _openAdSettings,
        ),
      );
    }

    return tasks.take(2).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    if (_loadError != null) {
      return AdminPermissionErrorView(
        message: _loadError!,
        onRetry: _loadBuilding,
      );
    }

    final buildingName = _nameController.text.trim();
    final province = _provinceController.text.trim();
    final ward = _wardController.text.trim();
    final area = [ward, province].where((part) => part.isNotEmpty).join(', ');
    final floorCount = _readInt(_floorCountController);
    final totalRooms = _effectiveTotalRooms;

    final progress = _setupProgressPercent();
    final tasks = _settingsTasks();
    final statusLabel = progress >= 100 ? 'Sẵn sàng vận hành' : 'Cần cập nhật';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      children: [
        Text(
          'Cài đặt',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Quản lý thiết lập và vận hành tòa nhà.',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        _SettingsOverviewCard(
          buildingName: buildingName.isEmpty
              ? 'Chưa đặt tên tòa nhà'
              : buildingName,
          area: area.isEmpty ? 'Chưa chọn khu vực' : area,
          totalRooms: totalRooms,
          floorCount: floorCount,
          progress: progress,
          statusLabel: statusLabel,
          payosConfigured: _isPayosConfigured,
        ),
        const SizedBox(height: 14),
        _SettingsTasksCard(tasks: tasks),
        const SizedBox(height: 16),
        Row(
          children: [
            Text(
              'Nhóm cài đặt',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: _isSaving ? null : () => _saveBuilding(),
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Lưu nhanh'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 680 ? 3 : 2;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.03,
              children: [
                _SettingsModuleCard(
                  icon: Icons.apartment_outlined,
                  title: 'Thông tin',
                  subtitle: 'Tên, liên hệ, vị trí',
                  color: AppColors.primary,
                  onTap: _openBuildingInfoSettings,
                ),
                _SettingsModuleCard(
                  icon: Icons.meeting_room_outlined,
                  title: 'Phòng & giá',
                  subtitle: 'Số phòng, tiền thuê',
                  color: AppColors.tenantAccent,
                  onTap: _openRoomBillingSettings,
                ),
                _SettingsModuleCard(
                  icon: Icons.payments_outlined,
                  title: 'Thanh toán',
                  subtitle: 'Ngân hàng, PayOS',
                  color: const Color(0xFFF59E0B),
                  onTap: _openPaymentSettings,
                ),
                _SettingsModuleCard(
                  icon: Icons.campaign_outlined,
                  title: 'Quảng cáo',
                  subtitle: 'Nội dung và ảnh',
                  color: AppColors.managerAccent,
                  onTap: _openAdSettings,
                ),
                _SettingsModuleCard(
                  icon: Icons.verified_user_outlined,
                  title: 'Quyền & hiển thị',
                  subtitle: 'Xin vào, Trang chủ, tiện ích',
                  color: const Color(0xFF0EA5E9),
                  onTap: _openAccessDisplaySettings,
                ),
                _SettingsModuleCard(
                  icon: Icons.article_outlined,
                  title: 'Nội quy',
                  subtitle: 'Quy định tòa nhà',
                  color: const Color(0xFFA855F7),
                  onTap: _openRulesSettings,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

}

class _SettingsTaskData {
  const _SettingsTaskData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
}

class _SettingsOverviewCard extends StatelessWidget {
  const _SettingsOverviewCard({
    required this.buildingName,
    required this.area,
    required this.totalRooms,
    required this.floorCount,
    required this.progress,
    required this.statusLabel,
    required this.payosConfigured,
  });

  final String buildingName;
  final String area;
  final int totalRooms;
  final int floorCount;
  final int progress;
  final String statusLabel;
  final bool payosConfigured;

  @override
  Widget build(BuildContext context) {
    final statusColor =
        progress >= 100 ? AppColors.managerAccent : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: -30,
            child: Icon(
              Icons.settings_rounded,
              color: Colors.white.withValues(alpha: 0.12),
              size: 148,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          buildingName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          area,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      statusLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '$progress% hoàn tất',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Text(
                          'Tiến độ thiết lập',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 9),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 100).toDouble() / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white.withValues(alpha: 0.22),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _SettingsOverviewChip(label: '$totalRooms phòng'),
                  _SettingsOverviewChip(label: '$floorCount tầng'),
                  _SettingsOverviewChip(
                    label: payosConfigured
                        ? 'PayOS Đã cấu hình'
                        : 'PayOS chưa cấu hình',
                    color: payosConfigured
                        ? AppColors.managerAccent
                        : const Color(0xFFF59E0B),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsOverviewChip extends StatelessWidget {
  const _SettingsOverviewChip({
    required this.label,
    this.color,
  });

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(
          alpha: color == null ? 0.16 : 0.20,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SettingsTasksCard extends StatelessWidget {
  const _SettingsTasksCard({required this.tasks});

  final List<_SettingsTaskData> tasks;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: AppColors.managerAccent),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Tòa nhà đã sẵn sàng vận hành.',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Việc cần làm',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < tasks.length; i++) ...[
            _SettingsTaskTile(task: tasks[i]),
            if (i != tasks.length - 1) const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _SettingsTaskTile extends StatelessWidget {
  const _SettingsTaskTile({required this.task});

  final _SettingsTaskData task;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: task.color.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: task.onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: task.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(task.icon, color: task.color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: task.color),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsModuleCard extends StatelessWidget {
  const _SettingsModuleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_forward_rounded, color: color, size: 20),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
