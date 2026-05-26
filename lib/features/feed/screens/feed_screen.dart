import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../../core/services/map_service.dart';
import '../../../core/widgets/building_map_preview.dart';
import '../../messages/screens/chat_detail_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../view_models/feed_view_model.dart';

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
  final _viewModel = FeedViewModel();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      _viewModel.setQuery(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) {
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
                  selected: _viewModel.filter == FeedFilter.buildings,
                  onSelected: (_) => _viewModel.setFilter(FeedFilter.buildings),
                ),
                ChoiceChip(
                  label: const Text('Quan ly'),
                  selected: _viewModel.filter == FeedFilter.managers,
                  onSelected: (_) => _viewModel.setFilter(FeedFilter.managers),
                ),
                ChoiceChip(
                  label: const Text('Nguoi thue'),
                  selected: _viewModel.filter == FeedFilter.tenants,
                  onSelected: (_) => _viewModel.setFilter(FeedFilter.tenants),
                ),
              ],
            ),
            const SizedBox(height: 16),
            switch (_viewModel.filter) {
              FeedFilter.buildings => _BuildingAdList(
                  user: widget.user,
                  role: widget.role,
                  query: _viewModel.query,
                  viewModel: _viewModel,
                ),
              FeedFilter.managers => _UserDirectoryList(
                  currentUser: widget.user,
                  role: UserRole.manager,
                  query: _viewModel.query,
                  viewModel: _viewModel,
                ),
              FeedFilter.tenants => _UserDirectoryList(
                  currentUser: widget.user,
                  role: UserRole.user,
                  query: _viewModel.query,
                  viewModel: _viewModel,
                ),
            },
          ],
        );
      },
    );
  }
}

class _BuildingAdList extends StatelessWidget {
  const _BuildingAdList({
    required this.user,
    required this.role,
    required this.query,
    required this.viewModel,
  });

  final User user;
  final String role;
  final String query;
  final FeedViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: viewModel.publishedBuildings(),
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
              viewModel: viewModel,
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
    required this.viewModel,
    this.showFullDetails = false,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final User user;
  final String role;
  final FeedViewModel viewModel;
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
    final canOpenDirections = MapService.canOpenDirections(building);

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
              _RoomStatusBoard(
                buildingId: buildingId,
                viewModel: viewModel,
              ),
              const SizedBox(height: 12),
              Text(
                'Lien he: $phone - $email',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            if (canOpenDirections && !showFullDetails) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openDirections(context),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Chi duong'),
              ),
            ],
            if (showFullDetails) ...[
              const SizedBox(height: 12),
              BuildingMapPreview(building: building),
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
              viewModel: viewModel,
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
          viewModel: viewModel,
        ),
      ),
    );
  }

  Future<void> _requestJoin(BuildContext context) async {
    final joined = await viewModel.requestJoin(
      buildingId: buildingId,
      building: building,
      user: user,
      role: role,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          joined
              ? 'Da gui yeu cau tham gia toa nha.'
              : viewModel.errorMessage ?? 'Khong gui duoc yeu cau.',
        ),
      ),
    );
  }

  Future<void> _messageAdmin(BuildContext context) async {
    final adminId = (building['adminId'] ?? '').toString();
    if (adminId.isEmpty) return;

    final title = 'Chat voi admin ${(building['adminName'] ?? '').toString()}';
    final chatId = await viewModel.findOrCreatePrivateChat(
      currentUser: user,
      otherUserId: adminId,
      otherUserName: (building['adminName'] ?? '').toString(),
      buildingId: buildingId,
      ownerId: adminId,
      title: title,
    );

    if (!context.mounted) return;
    if (chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(viewModel.errorMessage ?? 'Khong mo duoc khung chat.'),
        ),
      );
      return;
    }

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

  Future<void> _openDirections(BuildContext context) async {
    final opened = await MapService.openDirectionsForBuilding(building);
    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Khong mo duoc Google Maps.')),
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
    required this.viewModel,
  });

  final String buildingId;
  final Map<String, dynamic> building;
  final User user;
  final String role;
  final FeedViewModel viewModel;

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
            viewModel: viewModel,
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
    required this.viewModel,
    required this.showAll,
    this.onShowMore,
  });

  final String buildingId;
  final User user;
  final String role;
  final FeedViewModel viewModel;
  final bool showAll;
  final VoidCallback? onShowMore;

  @override
  State<_BuildingCommentsSection> createState() =>
      _BuildingCommentsSectionState();
}

class _BuildingCommentsSectionState extends State<_BuildingCommentsSection> {
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || widget.viewModel.isLoading) return;

    final sent = await widget.viewModel.sendBuildingComment(
      buildingId: widget.buildingId,
      user: widget.user,
      role: widget.role,
      text: text,
    );
    if (!mounted) return;

    if (sent) {
      _commentController.clear();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_commentErrorMessage(widget.viewModel.errorMessage)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          stream: widget.viewModel.buildingComments(
            buildingId: widget.buildingId,
            showAll: widget.showAll,
          ),
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
            AnimatedBuilder(
              animation: widget.viewModel,
              builder: (context, _) {
                return IconButton.filled(
                  onPressed: widget.viewModel.isLoading ? null : _sendComment,
                  icon: widget.viewModel.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  String _commentErrorMessage(String? errorMessage) {
    if (errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chua cap quyen binh luan quang cao.';
    }

    return 'Khong gui duoc binh luan.';
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
  const _RoomStatusBoard({
    required this.buildingId,
    required this.viewModel,
  });

  final String buildingId;
  final FeedViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: viewModel.buildingRooms(buildingId),
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
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: rooms.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width >= 560 ? 3 : 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final doc = rooms[index];
                final data = doc.data();
                return _FeedRoomAdTile(
                  name: (data['name'] ?? doc.id).toString(),
                  status: _statusFromRoom(data),
                  coverImageUrl: (data['coverImageUrl'] ?? '').toString(),
                );
              },
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
    required this.viewModel,
  });

  final User currentUser;
  final String role;
  final String query;
  final FeedViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: viewModel.usersByRole(role),
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
              viewModel: viewModel,
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
    required this.viewModel,
  });

  final User currentUser;
  final String userId;
  final Map<String, dynamic> data;
  final String role;
  final FeedViewModel viewModel;

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
        onTap: () => _openProfile(context, name, email),
      ),
    );
  }

  void _openProfile(BuildContext context, String name, String email) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProfileScreen(
          user: currentUser,
          roleLabel: UserRole.label(role),
          avatarText: _initials(name, email),
          avatarColor: _avatarColor(role),
          avatarTextColor: _avatarTextColor(role),
          profileUserId: userId,
          initialProfile: data,
          onChat: (profileContext) => _openChat(profileContext, name),
        ),
      ),
    );
  }

  Future<void> _openChat(BuildContext context, String name) async {
    if (viewModel.isLoading || userId == currentUser.uid) return;

    final chatId = await viewModel.findOrCreatePrivateChat(
      currentUser: currentUser,
      otherUserId: userId,
      otherUserName: name,
    );

    if (!context.mounted) return;
    if (chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            viewModel.errorMessage?.contains('permission-denied') == true
                ? 'Firestore chưa cấp quyền tạo chat riêng.'
                : 'Không mở được khung chat.',
          ),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChatDetailScreen(
          chatId: chatId,
          chatTitle: 'Chat với $name',
          user: currentUser,
        ),
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

  static Color _avatarColor(String role) {
    return switch (role) {
      UserRole.manager => const Color(0xFFC8E6C9),
      UserRole.admin => const Color(0xFFFFCCBC),
      _ => const Color(0xFFBBDEFB),
    };
  }

  static Color _avatarTextColor(String role) {
    return switch (role) {
      UserRole.manager => const Color(0xFF1B5E20),
      UserRole.admin => const Color(0xFF5D4037),
      _ => const Color(0xFF0D47A1),
    };
  }
}

class _FeedRoomAdTile extends StatelessWidget {
  const _FeedRoomAdTile({
    required this.name,
    required this.status,
    required this.coverImageUrl,
  });

  final String name;
  final String status;
  final String coverImageUrl;

  @override
  Widget build(BuildContext context) {
    final color = _RoomStatusBoard._statusColor(status);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: coverImageUrl.isEmpty
                  ? const _FeedRoomImagePlaceholder()
                  : Image.network(
                      coverImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const _FeedRoomImagePlaceholder(),
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _RoomStatusBoard._statusLabel(status),
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedRoomImagePlaceholder extends StatelessWidget {
  const _FeedRoomImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF2563EB)),
      ),
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
