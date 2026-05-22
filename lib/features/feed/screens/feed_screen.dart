import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../messages/screens/chat_detail_screen.dart';

enum _FeedFilter { buildings, managers, tenants }

class FeedScreen extends StatefulWidget {
  const FeedScreen({
    required this.user,
    required this.role,
    super.key,
  });

  final User user;
  final String role;

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _searchController = TextEditingController();
  var _filter = _FeedFilter.buildings;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Tim toa nha, quan ly, nguoi thue...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('Toa nha'),
              selected: _filter == _FeedFilter.buildings,
              onSelected: (_) => setState(() => _filter = _FeedFilter.buildings),
            ),
            ChoiceChip(
              label: const Text('Quan ly'),
              selected: _filter == _FeedFilter.managers,
              onSelected: (_) => setState(() => _filter = _FeedFilter.managers),
            ),
            ChoiceChip(
              label: const Text('Nguoi thue'),
              selected: _filter == _FeedFilter.tenants,
              onSelected: (_) => setState(() => _filter = _FeedFilter.tenants),
            ),
          ],
        ),
        const SizedBox(height: 16),
        switch (_filter) {
          _FeedFilter.buildings => _BuildingAdList(
              user: widget.user,
              role: widget.role,
              query: _query,
            ),
          _FeedFilter.managers => _UserDirectoryList(
              currentUser: widget.user,
              role: UserRole.manager,
              query: _query,
            ),
          _FeedFilter.tenants => _UserDirectoryList(
              currentUser: widget.user,
              role: UserRole.user,
              query: _query,
            ),
        },
      ],
    );
  }
}

Future<String> _findOrCreatePrivateChat({
  required User currentUser,
  required String otherUserId,
  required String otherUserName,
}) async {
  final existing = await AppFirestoreService.chats
      .where('type', isEqualTo: ChatType.private)
      .where('memberIds', arrayContains: currentUser.uid)
      .get();

  final found = existing.docs.where((doc) {
    final data = doc.data();
    if (data['isDeleted'] == true) return false;
    final deletedFor = List<String>.from(data['deletedFor'] ?? []);
    if (deletedFor.contains(currentUser.uid)) return false;
    final members = List<String>.from(data['memberIds'] ?? []);
    return members.contains(otherUserId);
  }).toList();

  if (found.isNotEmpty) {
    return found.first.id;
  }

  final currentName = currentUser.displayName ?? currentUser.email ?? 'Ban';
  final chatDoc = await AppFirestoreService.chats.add({
    'type': ChatType.private,
    'ownerId': currentUser.uid,
    'title': '$currentName - $otherUserName',
    'memberIds': [currentUser.uid, otherUserId],
    'deletedFor': [],
    'isDeleted': false,
    'lastMessage': '',
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  });

  return chatDoc.id;
}

class _BuildingAdList extends StatelessWidget {
  const _BuildingAdList({
    required this.user,
    required this.role,
    required this.query,
  });

  final User user;
  final String role;
  final String query;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.buildings
          .where('adPublished', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedEmptyState(
            icon: Icons.lock_outline,
            message: 'Khong tai duoc danh sach quang cao toa nha.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final buildings = (snapshot.data?.docs ?? [])
            .where((doc) => _matchesBuilding(doc.data(), query))
            .toList();

        buildings.sort((a, b) {
          final left = _timestampMillis(a.data()['adUpdatedAt']);
          final right = _timestampMillis(b.data()['adUpdatedAt']);
          return right.compareTo(left);
        });

        if (buildings.isEmpty) {
          return const _FeedEmptyState(
            icon: Icons.apartment_outlined,
            message: 'Chua co quang cao toa nha phu hop.',
          );
        }

        return Column(
          children: buildings.map((doc) {
            return _BuildingAdCard(
              buildingId: doc.id,
              building: doc.data(),
              user: user,
              role: role,
            );
          }).toList(),
        );
      },
    );
  }

  static bool _matchesBuilding(Map<String, dynamic> data, String query) {
    if (query.isEmpty) return true;
    final haystack = [
      data['name'],
      data['address'],
      data['description'],
      data['adminName'],
      data['phone'],
      data['email'],
    ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');

    return haystack.contains(query);
  }

  static int _timestampMillis(Object? value) {
    if (value is Timestamp) return value.millisecondsSinceEpoch;
    return 0;
  }
}

class _BuildingAdCard extends StatelessWidget {
  const _BuildingAdCard({
    required this.buildingId,
    required this.building,
    required this.user,
    required this.role,
    this.showFullDetails = false,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final User user;
  final String role;
  final bool showFullDetails;

  @override
  Widget build(BuildContext context) {
    final name = _text(building['name'], 'Toa nha');
    final address = _text(building['address'], 'Chua co dia chi');
    final description = _text(building['description'], 'Chua co mo ta');
    final adminName = _text(building['adminName'], 'Admin');
    final phone = _text(building['phone'], 'Chua co so dien thoai');
    final email = _text(building['email'], 'Chua co email');
    final amenities = _amenitiesText(building['amenities']);
    final servicePrices = _servicePricesText(building);
    final rules = _text(building['rulesText'], '');
    final totalRooms = _readInt(building['totalRooms']);
    final floorCount = _readInt(building['floorCount']);
    final defaultRent = _readInt(building['defaultRent']);
    final adminId = (building['adminId'] ?? '').toString();
    final isOwnBuilding = adminId == user.uid;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.apartment_outlined, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(address, style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: showFullDetails ? null : 2,
              overflow: showFullDetails ? null : TextOverflow.ellipsis,
            ),
            if (showFullDetails) ...[
              if (amenities.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Tien ich: $amenities'),
              ],
              if (servicePrices.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Phi dich vu: $servicePrices'),
              ],
              if (rules.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Noi quy: $rules'),
              ],
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (showFullDetails)
                  _InfoPill(icon: Icons.person_outline, text: adminName),
                _InfoPill(
                  icon: Icons.meeting_room_outlined,
                  text: totalRooms > 0 ? '$totalRooms phong' : 'Chua co phong',
                ),
                _InfoPill(
                  icon: Icons.layers_outlined,
                  text: floorCount > 0 ? '$floorCount tang' : 'Chua co so tang',
                ),
                _InfoPill(
                  icon: Icons.payments_outlined,
                  text: defaultRent > 0
                      ? '${_money(defaultRent)}/thang'
                      : 'Chua co gia',
                ),
              ],
            ),
            if (showFullDetails) ...[
              const SizedBox(height: 12),
              _RoomStatusBoard(buildingId: buildingId),
              const SizedBox(height: 12),
              Text(
                'Lien he: $phone - $email',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            const SizedBox(height: 12),
            if (!showFullDetails)
              Row(
                children: [
                  if (!isOwnBuilding) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _messageAdmin(context),
                        icon: const Icon(Icons.chat_bubble_outline),
                        label: const Text('Chat voi admin'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _openDetails(context),
                      icon: const Icon(Icons.expand_more),
                      label: const Text('Xem them'),
                    ),
                  ),
                ],
              )
            else if (isOwnBuilding)
              const Align(
                alignment: Alignment.centerRight,
                child: Chip(label: Text('Toa nha cua ban')),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _messageAdmin(context),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat voi admin'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _requestJoin(context),
                      icon: const Icon(Icons.login_outlined),
                      label: const Text('Xin vao'),
                    ),
                  ),
                ],
              ),
            const Divider(height: 24),
            _BuildingCommentsSection(
              buildingId: buildingId,
              user: user,
              role: role,
              showAll: showFullDetails,
              onShowMore: showFullDetails ? null : () => _openDetails(context),
            ),
          ],
        ),
      ),
    );
  }

  void _openDetails(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _BuildingAdDetailScreen(
          buildingId: buildingId,
          building: building,
          user: user,
          role: role,
        ),
      ),
    );
  }

  Future<void> _requestJoin(BuildContext context) async {
    final adminId = (building['adminId'] ?? '').toString();
    if (adminId.isEmpty) return;

    final existing = await AppFirestoreService.joinRequests
        .where('buildingId', isEqualTo: buildingId)
        .where('requesterId', isEqualTo: user.uid)
        .where('status', isEqualTo: JoinRequestStatus.pending)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ban da gui yeu cau truoc do.')),
      );
      return;
    }

    await AppFirestoreService.joinRequests.add({
      'buildingId': buildingId,
      'buildingName': building['name'] ?? '',
      'adminId': adminId,
      'requesterId': user.uid,
      'requesterName': user.displayName ?? user.email ?? 'Nguoi dung',
      'requesterEmail': user.email ?? '',
      'requesterRole': role,
      'status': JoinRequestStatus.pending,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Da gui yeu cau tham gia toa nha.')),
    );
  }

  Future<void> _messageAdmin(BuildContext context) async {
    final adminId = (building['adminId'] ?? '').toString();
    if (adminId.isEmpty) return;

    final title = 'Chat voi admin ${(building['adminName'] ?? '').toString()}';
    final existing = await AppFirestoreService.chats
        .where('type', isEqualTo: ChatType.private)
        .where('memberIds', arrayContains: user.uid)
        .get();

    final found = existing.docs.where((doc) {
      final data = doc.data();
      if (data['isDeleted'] == true) return false;
      final deletedFor = List<String>.from(data['deletedFor'] ?? []);
      if (deletedFor.contains(user.uid)) return false;
      final members = List<String>.from(data['memberIds'] ?? []);
      return members.contains(adminId);
    }).toList();

    String chatId;
    if (found.isEmpty) {
      final chatDoc = await AppFirestoreService.chats.add({
        'type': ChatType.private,
        'buildingId': buildingId,
        'ownerId': adminId,
        'title': title,
        'memberIds': [user.uid, adminId],
        'deletedFor': [],
        'isDeleted': false,
        'lastMessage': '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      chatId = chatDoc.id;
    } else {
      chatId = found.first.id;
    }

    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chatId: chatId,
          chatTitle: title,
          user: user,
        ),
      ),
    );
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _amenitiesText(Object? value) {
    if (value is! Map) return '';

    final labels = <String>[];
    if (value['wifi'] == true) labels.add('Wifi');
    if (value['elevator'] == true) labels.add('Thang may');
    if (value['camera'] == true) labels.add('Camera');
    if (value['parking'] == true) labels.add('Cho de xe');
    if (value['laundry'] == true) labels.add('May giat');
    if (value['security'] == true) labels.add('Bao ve');
    return labels.join(', ');
  }

  static String _servicePricesText(Map<String, dynamic> building) {
    final items = <String>[];
    void addPrice(String label, Object? value) {
      final amount = _readInt(value);
      if (amount > 0) items.add('$label $amount VND');
    }

    addPrice('Dien', building['electricityPrice']);
    addPrice('Nuoc', building['waterPrice']);
    addPrice('Dich vu', building['serviceFee']);
    addPrice('Internet', building['internetFee']);
    addPrice('Gui xe', building['parkingFee']);
    return items.join(', ');
  }

  static String _money(int value) {
    return '$value VND';
  }
}

class _BuildingAdDetailScreen extends StatelessWidget {
  const _BuildingAdDetailScreen({
    required this.buildingId,
    required this.building,
    required this.user,
    required this.role,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final User user;
  final String role;

  @override
  Widget build(BuildContext context) {
    final name = (building['name'] ?? 'Toa nha').toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Chi tiet quang cao')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            name,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          _BuildingAdCard(
            buildingId: buildingId,
            building: building,
            user: user,
            role: role,
            showFullDetails: true,
          ),
        ],
      ),
    );
  }
}

class _BuildingCommentsSection extends StatefulWidget {
  const _BuildingCommentsSection({
    required this.buildingId,
    required this.user,
    required this.role,
    required this.showAll,
    this.onShowMore,
  });

  final String buildingId;
  final User user;
  final String role;
  final bool showAll;
  final VoidCallback? onShowMore;

  @override
  State<_BuildingCommentsSection> createState() =>
      _BuildingCommentsSectionState();
}

class _BuildingCommentsSectionState extends State<_BuildingCommentsSection> {
  final _commentController = TextEditingController();
  bool _isSending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final authorName =
          widget.user.displayName ?? widget.user.email ?? 'Nguoi dung';

      await AppFirestoreService.buildingComments(widget.buildingId).add({
        'authorId': widget.user.uid,
        'authorName': authorName,
        'authorEmail': widget.user.email ?? '',
        'authorRole': widget.role,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firestore chua cap quyen binh luan quang cao.'
                : e.message ?? 'Khong gui duoc binh luan.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Query<Map<String, dynamic>> query = AppFirestoreService
        .buildingComments(widget.buildingId)
        .orderBy('createdAt', descending: true);

    if (!widget.showAll) {
      query = query.limit(1);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.mode_comment_outlined, size: 18),
            const SizedBox(width: 6),
            Text(
              'Binh luan',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: query.snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('Khong tai duoc binh luan.'),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 2),
              );
            }

            final comments = (snapshot.data?.docs ?? []).reversed.toList();
            if (comments.isEmpty) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Chua co binh luan nao.',
                  style: TextStyle(color: Colors.black54),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...comments.map((doc) => _CommentBubble(data: doc.data())),
                if (!widget.showAll && widget.onShowMore != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: widget.onShowMore,
                      child: const Text('Xem tat ca binh luan'),
                    ),
                  ),
              ],
            );
          },
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                minLines: 1,
                maxLines: 3,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendComment(),
                decoration: const InputDecoration(
                  hintText: 'Viet binh luan...',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _isSending ? null : _sendComment,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ],
    );
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final authorName = (data['authorName'] ?? 'Nguoi dung').toString();
    final text = (data['text'] ?? '').toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            authorName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(text),
        ],
      ),
    );
  }
}

class _RoomStatusBoard extends StatelessWidget {
  const _RoomStatusBoard({required this.buildingId});

  final String buildingId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.buildingRooms(buildingId)
          .orderBy('roomNumber')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const LinearProgressIndicator(minHeight: 2);
        }

        if (snapshot.hasError) {
          return const Text('Khong tai duoc trang thai phong.');
        }

        final rooms = snapshot.data?.docs ?? [];
        if (rooms.isEmpty) {
          return const Text('Chua co danh sach phong.');
        }

        final counts = <String, int>{
          'available': 0,
          'occupied': 0,
          'maintenance': 0,
          'reserved': 0,
        };

        for (final doc in rooms) {
          final status = _statusFromRoom(doc.data());
          counts[status] = (counts[status] ?? 0) + 1;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusSummaryChip(
                  label: 'Trong',
                  value: counts['available'] ?? 0,
                  color: Colors.green,
                ),
                _StatusSummaryChip(
                  label: 'Da thue',
                  value: counts['occupied'] ?? 0,
                  color: Colors.blueAccent,
                ),
                _StatusSummaryChip(
                  label: 'Bao tri',
                  value: counts['maintenance'] ?? 0,
                  color: Colors.orange,
                ),
                _StatusSummaryChip(
                  label: 'Da dat',
                  value: counts['reserved'] ?? 0,
                  color: Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: rooms.map((doc) {
                final data = doc.data();
                final name = (data['name'] ?? doc.id).toString();
                final status = _statusFromRoom(data);
                final color = _statusColor(status);

                return OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color.withValues(alpha: 0.45)),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text('$name - ${_statusLabel(status)}'),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }

  static String _statusFromRoom(Map<String, dynamic> room) {
    final tenantId = (room['tenantId'] ?? '').toString();
    final tenantName = (room['tenantName'] ?? '').toString();
    if (tenantId.isNotEmpty || tenantName.isNotEmpty) return 'occupied';
    final status = (room['status'] ?? 'available').toString();
    if (status == 'occupied' || status == 'maintenance' || status == 'reserved') {
      return status;
    }
    return 'available';
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'occupied' => 'Da thue',
      'maintenance' => 'Bao tri',
      'reserved' => 'Da dat',
      _ => 'Trong',
    };
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'occupied' => Colors.blueAccent,
      'maintenance' => Colors.orange,
      'reserved' => Colors.purple,
      _ => Colors.green,
    };
  }
}

class _UserDirectoryList extends StatelessWidget {
  const _UserDirectoryList({
    required this.currentUser,
    required this.role,
    required this.query,
  });

  final User currentUser;
  final String role;
  final String query;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: AppFirestoreService.users.where('role', isEqualTo: role).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _FeedEmptyState(
            icon: Icons.lock_outline,
            message: 'Khong tai duoc danh sach tai khoan.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = (snapshot.data?.docs ?? [])
            .where((doc) => _matchesUser(doc.data(), query))
            .toList();

        users.sort((a, b) {
          final left = _displayName(a.data()).toLowerCase();
          final right = _displayName(b.data()).toLowerCase();
          return left.compareTo(right);
        });

        if (users.isEmpty) {
          return _FeedEmptyState(
            icon: Icons.people_outline,
            message: role == UserRole.manager
                ? 'Chua co tai khoan quan ly phu hop.'
                : 'Chua co tai khoan nguoi thue phu hop.',
          );
        }

        return Column(
          children: users.map((doc) {
            return _UserDirectoryCard(
              currentUser: currentUser,
              userId: doc.id,
              data: doc.data(),
              role: role,
            );
          }).toList(),
        );
      },
    );
  }

  static bool _matchesUser(Map<String, dynamic> data, String query) {
    if (query.isEmpty) return true;
    final haystack = [
      data['name'],
      data['email'],
      data['displayName'],
    ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
    return haystack.contains(query);
  }

  static String _displayName(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['displayName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final email = (data['email'] ?? '').toString().trim();
    return email.isEmpty ? 'Tai khoan' : email;
  }
}

class _UserDirectoryCard extends StatelessWidget {
  const _UserDirectoryCard({
    required this.currentUser,
    required this.userId,
    required this.data,
    required this.role,
  });

  final User currentUser;
  final String userId;
  final Map<String, dynamic> data;
  final String role;

  @override
  Widget build(BuildContext context) {
    final name = _displayName(data);
    final email = (data['email'] ?? '').toString();
    final buildingId = (data['buildingId'] ?? '').toString();

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(child: Text(_initials(name, email))),
        title: Text(name),
        subtitle: Text(
          [
            UserRole.label(role),
            if (email.isNotEmpty) email,
            buildingId.isEmpty ? 'Chua tham gia toa nha' : 'Da tham gia toa nha',
          ].join(' - '),
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => _UserDirectoryProfileScreen(
                currentUser: currentUser,
                profileUserId: userId,
                profile: data,
                role: role,
              ),
            ),
          );
        },
      ),
    );
  }

  static String _displayName(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['displayName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final email = (data['email'] ?? '').toString().trim();
    return email.isEmpty ? 'Tai khoan' : email;
  }

  static String _initials(String name, String email) {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return '?';
    final words = source.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final initials = words.take(2).map((word) => word[0]).join();
    return initials.toUpperCase();
  }
}

class _UserDirectoryProfileScreen extends StatefulWidget {
  const _UserDirectoryProfileScreen({
    required this.currentUser,
    required this.profileUserId,
    required this.profile,
    required this.role,
  });

  final User currentUser;
  final String profileUserId;
  final Map<String, dynamic> profile;
  final String role;

  @override
  State<_UserDirectoryProfileScreen> createState() =>
      _UserDirectoryProfileScreenState();
}

class _UserDirectoryProfileScreenState
    extends State<_UserDirectoryProfileScreen> {
  bool _isOpeningChat = false;

  Future<void> _openChat() async {
    if (_isOpeningChat || widget.profileUserId == widget.currentUser.uid) return;

    setState(() => _isOpeningChat = true);

    try {
      final chatId = await _findOrCreatePrivateChat(
        currentUser: widget.currentUser,
        otherUserId: widget.profileUserId,
        otherUserName: _displayName(widget.profile),
      );

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatDetailScreen(
            chatId: chatId,
            chatTitle: 'Chat voi ${_displayName(widget.profile)}',
            user: widget.currentUser,
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.code == 'permission-denied'
                ? 'Firestore chua cap quyen tao chat rieng.'
                : e.message ?? 'Khong mo duoc khung chat.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isOpeningChat = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _displayName(widget.profile);
    final email = (widget.profile['email'] ?? '').toString();
    final buildingId = (widget.profile['buildingId'] ?? '').toString();
    final isCurrentUser = widget.profileUserId == widget.currentUser.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Ho so tai khoan')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: CircleAvatar(
              radius: 54,
              backgroundColor: const Color(0xFFE0F2FE),
              child: Text(
                _initials(name, email),
                style: const TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            name,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            UserRole.label(widget.role),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          _ProfileInfoTile(
            icon: Icons.email_outlined,
            label: 'Email',
            value: email.isEmpty ? 'Chua co email' : email,
          ),
          const SizedBox(height: 10),
          _ProfileInfoTile(
            icon: Icons.apartment_outlined,
            label: 'Trang thai toa nha',
            value: buildingId.isEmpty ? 'Chua tham gia toa nha' : 'Da tham gia',
          ),
          const SizedBox(height: 24),
          if (isCurrentUser)
            const Center(child: Chip(label: Text('Tai khoan cua ban')))
          else
            FilledButton.icon(
              onPressed: _isOpeningChat ? null : _openChat,
              icon: _isOpeningChat
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.chat_bubble_outline),
              label: const Text('Chat'),
            ),
        ],
      ),
    );
  }

  static String _displayName(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['displayName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final email = (data['email'] ?? '').toString().trim();
    return email.isEmpty ? 'Tai khoan' : email;
  }

  static String _initials(String name, String email) {
    final source = name.trim().isNotEmpty ? name.trim() : email.trim();
    if (source.isEmpty) return '?';
    final words = source.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final initials = words.take(2).map((word) => word[0]).join();
    return initials.toUpperCase();
  }
}

class _ProfileInfoTile extends StatelessWidget {
  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.blueAccent),
          const SizedBox(width: 6),
          Text(text),
        ],
      ),
    );
  }
}

class _StatusSummaryChip extends StatelessWidget {
  const _StatusSummaryChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        backgroundColor: color.withValues(alpha: 0.15),
        child: Text(
          '$value',
          style: TextStyle(color: color, fontSize: 12),
        ),
      ),
      label: Text(label),
    );
  }
}

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
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
