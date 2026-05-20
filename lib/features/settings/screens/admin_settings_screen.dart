import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';

class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({required this.user, super.key});

  final User user;

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _totalRoomsController = TextEditingController();
  final _defaultRentController = TextEditingController();

  String? _buildingId;
  String? _loadError;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadBuilding();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _totalRoomsController.dispose();
    _defaultRentController.dispose();
    super.dispose();
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
        _buildingId = doc.id;
        _nameController.text = (data['name'] ?? '').toString();
        _addressController.text = (data['address'] ?? '').toString();
        _totalRoomsController.text = (data['totalRooms'] ?? '').toString();
        _defaultRentController.text = (data['defaultRent'] ?? '').toString();
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
    setState(() => _isSaving = true);

    try {
      final doc = _buildingId == null
          ? AppFirestoreService.buildings.doc()
          : AppFirestoreService.buildings.doc(_buildingId);

      await doc.set({
        'id': doc.id,
        'adminId': widget.user.uid,
        'adminName': widget.user.displayName ?? widget.user.email ?? 'Admin',
        'name': _nameController.text.trim(),
        'address': _addressController.text.trim(),
        'totalRooms': int.tryParse(_totalRoomsController.text.trim()) ?? 0,
        'defaultRent': int.tryParse(_defaultRentController.text.trim()) ?? 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _buildingId = doc.id;
      await _ensureBuildingGroupChat(doc.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Da luu thiet lap toa nha.')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'permission-denied'
                  ? 'Firestore chua cap quyen ghi buildings/chats.'
                  : e.message ?? 'Khong luu duoc toa nha.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _ensureBuildingGroupChat(String buildingId) async {
    final query = await AppFirestoreService.chats
        .where('type', isEqualTo: ChatType.group)
        .where('buildingId', isEqualTo: buildingId)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) return;

    await AppFirestoreService.chats.add({
      'type': ChatType.group,
      'buildingId': buildingId,
      'ownerId': widget.user.uid,
      'title': _nameController.text.trim().isEmpty
          ? 'Nhom chat toa nha'
          : _nameController.text.trim(),
      'memberIds': [widget.user.uid],
      'lastMessage': '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
          'Thiết lập toà nhà',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Tên toà nhà',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: 'Địa chỉ toà nhà',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _totalRoomsController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tổng số phòng',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _defaultRentController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Tiền thuê mặc định',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _isSaving ? null : _saveBuilding,
          icon: const Icon(Icons.save_outlined),
          label: const Text('Lưu thiết lập'),
        ),
      ],
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
