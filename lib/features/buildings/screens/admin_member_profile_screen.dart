import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';

class AdminMemberProfileScreen extends StatefulWidget {
  const AdminMemberProfileScreen({
    required this.userId,
    required this.userData,
    required this.buildingId,
    required this.buildingName,
    super.key,
  });

  final String userId;
  final Map<String, dynamic> userData;
  final String buildingId;
  final String buildingName;

  @override
  State<AdminMemberProfileScreen> createState() =>
      _AdminMemberProfileScreenState();
}

class _AdminMemberProfileScreenState extends State<AdminMemberProfileScreen> {
  bool _isRemoving = false;

  String get _name {
    return (widget.userData['name'] ??
            widget.userData['displayName'] ??
            widget.userData['email'] ??
            'Tai khoan')
        .toString();
  }

  String get _email {
    return (widget.userData['email'] ?? '').toString();
  }

  String get _role {
    return (widget.userData['role'] ?? UserRole.user).toString();
  }

  String get _initials {
    final source = _name.trim().isNotEmpty ? _name.trim() : _email.trim();
    if (source.isEmpty) return '?';
    return source.substring(0, 1).toUpperCase();
  }

  Future<void> _confirmRemove() async {
    final shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Xoa khoi toa nha?'),
          content: Text('Ban co chac muon xoa $_name khoi ${widget.buildingName}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Huy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Xoa'),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      await _removeFromBuilding();
    }
  }

  Future<void> _removeFromBuilding() async {
    setState(() => _isRemoving = true);

    try {
      await AppFirestoreService.db.runTransaction((transaction) async {
        final userRef = AppFirestoreService.users.doc(widget.userId);
        final roomId = (widget.userData['roomId'] ?? '').toString();
        final roomRef = roomId.isNotEmpty
            ? AppFirestoreService.buildingRooms(widget.buildingId).doc(roomId)
            : null;
        final roomSnapshot =
            roomRef == null ? null : await transaction.get(roomRef);

        transaction.update(userRef, {
          'buildingId': null,
          'roomId': FieldValue.delete(),
          'roomNumber': FieldValue.delete(),
          'roomName': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        if (roomRef != null && roomSnapshot?.exists == true) {
          transaction.update(roomRef, {
            'tenantId': FieldValue.delete(),
            'tenantName': FieldValue.delete(),
            'tenantEmail': FieldValue.delete(),
            'status': 'available',
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      await _removeFromBuildingGroupChat();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Da xoa tai khoan khoi toa nha.')),
      );
      Navigator.of(context).pop();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firestore chua cap quyen xoa thanh vien khoi toa nha.'
                : e.message ?? 'Khong xoa duoc thanh vien.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isRemoving = false);
    }
  }

  Future<void> _removeFromBuildingGroupChat() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final query = await AppFirestoreService.chats
        .where('memberIds', arrayContains: currentUser.uid)
        .get();

    final matchedChats = query.docs.where((doc) {
      final chat = doc.data();
      return chat['type'] == ChatType.group &&
          chat['buildingId'] == widget.buildingId;
    }).toList();

    if (matchedChats.isEmpty) return;

    await matchedChats.first.reference.update({
      'memberIds': FieldValue.arrayRemove([widget.userId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ho so thanh vien')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 56,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  _initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _name,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 6),
              Text(UserRole.label(_role)),
              if (_email.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(_email, textAlign: TextAlign.center),
              ],
              const SizedBox(height: 6),
              Text(
                widget.buildingName,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                ),
                onPressed: _isRemoving ? null : _confirmRemove,
                icon: _isRemoving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.person_remove_outlined),
                label: const Text('Xoa khoi toa nha'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
