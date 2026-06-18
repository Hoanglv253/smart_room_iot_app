import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../view_models/admin_ad_settings_view_model.dart';

class AdminAdSettingsScreen extends StatefulWidget {
  const AdminAdSettingsScreen({
    required this.user,
    required this.buildingId,
    super.key,
  });

  final User user;
  final String buildingId;

  @override
  State<AdminAdSettingsScreen> createState() => _AdminAdSettingsScreenState();
}

class _AdminAdSettingsScreenState extends State<AdminAdSettingsScreen> {
  final _viewModel = AdminAdSettingsViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _publishAd() async {
    final saved = await _viewModel.publishAd(
      buildingId: widget.buildingId,
      userId: widget.user.uid,
    );

    if (saved) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã đẩy quảng cáo lên trang chủ.')),
      );
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_publishErrorMessage())),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Thiết lập quảng cáo',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _viewModel.building(widget.buildingId),
            builder: (context, buildingSnapshot) {
              if (buildingSnapshot.hasError) {
                return const _AdEmptyState(
                  icon: Icons.lock_outline,
                  message: 'Không tải được thông tin tòa nhà.',
                );
              }

              if (buildingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (buildingSnapshot.data?.exists != true) {
                return const _AdEmptyState(
                  icon: Icons.apartment_outlined,
                  message: 'Hãy lưu thiết lập tòa nhà trước khi tạo quảng cáo.',
                );
              }

              final building = buildingSnapshot.data!.data() ?? {};

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _viewModel.buildingRooms(widget.buildingId),
                builder: (context, roomSnapshot) {
                  final rooms = roomSnapshot.data?.docs ?? [];
                  final imageCount = rooms.fold<int>(
                    0,
                    (total, room) => total + _imageUrls(room.data()).length,
                  );

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _BuildingPreviewCard(building: building),
                      const SizedBox(height: 14),
                      _AdContentSummaryCard(building: building),
                      const SizedBox(height: 14),
                      _RoomButtonSection(
                        viewModel: _viewModel,
                        buildingId: widget.buildingId,
                        isLoading: roomSnapshot.connectionState ==
                            ConnectionState.waiting,
                        hasError: roomSnapshot.hasError,
                        rooms: rooms,
                      ),
                      const SizedBox(height: 14),
                      _PublishActionCard(
                        isLoading: _viewModel.isLoading,
                        isPublished: building['adPublished'] == true,
                        imageCount: imageCount,
                        onPressed: _publishAd,
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  String _publishErrorMessage() {
    if (_viewModel.errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chưa cấp quyền cập nhật quảng cáo tòa nhà.';
    }

    return 'Không lưu được quảng cáo.';
  }
}

class _BuildingPreviewCard extends StatelessWidget {
  const _BuildingPreviewCard({required this.building});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    final name = _text(building['name'], 'Tòa nhà');
    final address = _text(building['address'], 'Chưa có Địa chỉ');
    final description = _text(building['description'], 'Chưa có mô tả');
    final totalRooms = _readInt(building['totalRooms']);
    final floorCount = _readInt(building['floorCount']);
    final defaultRent = _readInt(building['defaultRent']);
    final adPublished = building['adPublished'] == true;

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient(),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.24),
            blurRadius: 22,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -34,
            top: -26,
            child: _DecorCircle(size: 116, opacity: 0.13),
          ),
          Positioned(
            right: 38,
            bottom: -48,
            child: _DecorCircle(size: 118, opacity: 0.09),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Icon(
                        Icons.campaign_outlined,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            adPublished
                                ? 'Đang hiển thị trên Trang chủ'
                                : 'Bản nháp quảng cáo',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.78),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _LiveBadge(isLive: adPublished),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        address,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _HeroMetricPill(
                      icon: Icons.meeting_room_outlined,
                      label: totalRooms > 0
                          ? '$totalRooms phòng'
                          : 'Chưa có phòng',
                    ),
                    _HeroMetricPill(
                      icon: Icons.layers_outlined,
                      label: floorCount > 0 ? '$floorCount tầng' : 'Chưa có tầng',
                    ),
                    _HeroMetricPill(
                      icon: Icons.payments_outlined,
                      label: defaultRent > 0
                          ? '${_money(defaultRent)}/tháng'
                          : 'Chưa đặt giá',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdContentSummaryCard extends StatelessWidget {
  const _AdContentSummaryCard({required this.building});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    final phone = _text(building['phone'], 'Chưa có số điện thoại');
    final email = _text(building['email'], 'Chưa có email');
    final adminName = _text(building['adminName'], 'Admin');
    final amenities = _amenitiesText(building['amenities']);
    final servicePrices = _servicePricesText(building);
    final rules = _text(building['rulesText'], 'Chưa có nội quy');

    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionIcon(icon: Icons.article_outlined),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nội dung quảng cáo',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Dữ liệu này sẽ hiển thị cho người thuê trên Trang chủ.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _AdContentTile(
            icon: Icons.person_outline,
            label: 'Quản trị viên',
            value: adminName,
            tint: AppColors.primary,
          ),
          const SizedBox(height: 10),
          _AdContentTile(
            icon: Icons.call_outlined,
            label: 'Liên hệ',
            value: '$phone - $email',
            tint: const Color(0xFF0EA5E9),
          ),
          const SizedBox(height: 10),
          _AdContentTile(
            icon: Icons.auto_awesome_outlined,
            label: 'Tiện ích nổi bật',
            value: amenities.isEmpty ? 'Chưa thiết lập tiện ích' : amenities,
            tint: const Color(0xFF16A34A),
          ),
          const SizedBox(height: 10),
          _AdContentTile(
            icon: Icons.receipt_long_outlined,
            label: 'Phí dịch vụ',
            value: servicePrices.isEmpty
                ? 'Chưa thiết lập phí dịch vụ'
                : servicePrices,
            tint: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _AdContentTile(
            icon: Icons.rule_outlined,
            label: 'Nội quy',
            value: rules,
            tint: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}

class _RoomButtonSection extends StatefulWidget {
  const _RoomButtonSection({
    required this.viewModel,
    required this.buildingId,
    required this.isLoading,
    required this.hasError,
    required this.rooms,
  });

  final AdminAdSettingsViewModel viewModel;
  final String buildingId;
  final bool isLoading;
  final bool hasError;
  final List<QueryDocumentSnapshot<Map<String, dynamic>>> rooms;

  @override
  State<_RoomButtonSection> createState() => _RoomButtonSectionState();
}

class _RoomButtonSectionState extends State<_RoomButtonSection> {
  int? _selectedFloor;

  @override
  Widget build(BuildContext context) {
    final floors = widget.rooms
        .map((room) => _roomFloor(room.data()))
        .where((floor) => floor > 0)
        .toSet()
        .toList()
      ..sort();
    final activeFloor = floors.contains(_selectedFloor) ? _selectedFloor : null;
    final visibleRooms = activeFloor == null
        ? widget.rooms
        : widget.rooms
            .where((room) => _roomFloor(room.data()) == activeFloor)
            .toList();
    final totalImages = widget.rooms.fold<int>(
      0,
      (total, room) => total + _imageUrls(room.data()).length,
    );

    return _SectionShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _SectionIcon(icon: Icons.photo_library_outlined),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ảnh phòng đang quảng cáo',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.rooms.length} phòng - $totalImages ảnh đã tải lên',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FloorFilterChip(
                  label: 'Tất cả',
                  selected: activeFloor == null,
                  onTap: () => setState(() => _selectedFloor = null),
                ),
                for (final floor in floors) ...[
                  const SizedBox(width: 8),
                  _FloorFilterChip(
                    label: 'Tầng $floor',
                    selected: activeFloor == floor,
                    onTap: () => setState(() => _selectedFloor = floor),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          if (widget.isLoading)
            const LinearProgressIndicator(minHeight: 3)
          else if (widget.hasError)
            const _InlineState(
              icon: Icons.wifi_off_outlined,
              message: 'Không tải được danh sách phòng.',
            )
          else if (widget.rooms.isEmpty)
            const _InlineState(
              icon: Icons.meeting_room_outlined,
              message: 'Chưa có phòng nào để hiển thị.',
            )
          else if (visibleRooms.isEmpty)
            const _InlineState(
              icon: Icons.filter_alt_off_outlined,
              message: 'Tầng này chưa có phòng phù hợp.',
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: visibleRooms.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width >= 560 ? 3 : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),
              itemBuilder: (context, index) {
                final roomDoc = visibleRooms[index];
                return _RoomImageTile(
                  roomId: roomDoc.id,
                  room: roomDoc.data(),
                  onTap: () => _openRoomImages(context, roomDoc.id),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openRoomImages(BuildContext context, String roomId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: widget.viewModel.room(
            buildingId: widget.buildingId,
            roomId: roomId,
          ),
          builder: (context, snapshot) {
            final room = snapshot.data?.data() ?? {};
            final name = (room['name'] ?? roomId).toString();
            final imageUrls = _imageUrls(room);
            final coverImageUrl = (room['coverImageUrl'] ?? '').toString();
            final status = _statusFromRoom(room);

            return AnimatedBuilder(
              animation: widget.viewModel,
              builder: (context, _) {
                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.88,
                  minChildSize: 0.55,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 10, 18, 26),
                      children: [
                        Center(
                          child: Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _RoomImageSheetHeader(
                          name: name,
                          status: status,
                          imageCount: imageUrls.length,
                          isBusy: widget.viewModel.isLoading,
                          onClose: () => Navigator.of(sheetContext).pop(),
                        ),
                        const SizedBox(height: 14),
                        _RoomCoverPreview(imageUrl: coverImageUrl),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: widget.viewModel.isLoading
                              ? null
                              : () => _pickAndUploadImages(sheetContext, roomId),
                          icon: widget.viewModel.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Thêm nhiều ảnh từ thiết bị'),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Tất cả ảnh phòng',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Text(
                              '${imageUrls.length} ảnh',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (imageUrls.isEmpty)
                          const _RoomImageEmptyState()
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: imageUrls.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount:
                                  MediaQuery.of(context).size.width >= 560
                                      ? 3
                                      : 2,
                              mainAxisSpacing: 12,
                              crossAxisSpacing: 12,
                              childAspectRatio: 0.78,
                            ),
                            itemBuilder: (context, index) {
                              final imageUrl = imageUrls[index];
                              return _RoomImageManageTile(
                                imageUrl: imageUrl,
                                isCover: imageUrl == coverImageUrl,
                                onSetCover: widget.viewModel.isLoading
                                    ? null
                                    : () => _setCover(
                                          sheetContext,
                                          roomId,
                                          imageUrl,
                                        ),
                                onDelete: widget.viewModel.isLoading
                                    ? null
                                    : () => _confirmDeleteImage(
                                          sheetContext,
                                          roomId,
                                          imageUrl,
                                        ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImages(BuildContext context, String roomId) async {
    final result = await widget.viewModel.pickAndUploadRoomImages(
      buildingId: widget.buildingId,
      roomId: roomId,
    );

    if (!context.mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result > 0 ? 'Đã thêm $result Ảnh phòng.' : _imageErrorMessage(),
        ),
      ),
    );
  }

  Future<void> _setCover(
    BuildContext context,
    String roomId,
    String imageUrl,
  ) async {
    final ok = await widget.viewModel.setCoverImage(
      buildingId: widget.buildingId,
      roomId: roomId,
      imageUrl: imageUrl,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã đặt ảnh chọnh.' : _imageErrorMessage())),
    );
  }

  Future<void> _confirmDeleteImage(
    BuildContext context,
    String roomId,
    String imageUrl,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xóa ảnh phòng?'),
          content: const Text(
            'Ảnh này sẽ bị xóa khỏi danh sách ảnh của phòng.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Xóa'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    final ok = await widget.viewModel.deleteRoomImage(
      buildingId: widget.buildingId,
      roomId: roomId,
      imageUrl: imageUrl,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã xóa Ảnh phòng.' : _imageErrorMessage())),
    );
  }

  String _imageErrorMessage() {
    final error = widget.viewModel.errorMessage ?? '';
    if (error.contains('MissingPluginException')) {
      return 'Cần dừng app và chạy lại từ đầu sau khi thêm image_picker.';
    }
    if (error.contains('firebase_storage/unauthorized') ||
        error.contains('permission-denied') ||
        error.contains('unauthorized')) {
      return 'Firebase Storage chưa cấp quyền upload Ảnh phòng.';
    }
    if (error.contains('object-not-found')) {
      return 'Firebase Storage chưa trả về link ảnh. Thử lại sau với giây.';
    }
    if (error.contains('TimeoutException')) {
      return 'Kết nối Firebase Storage quá lâu. Kiểm tra mạng rồi thử lại.';
    }
    return 'Không xử lý được Ảnh phòng.';
  }

}

class _RoomImageTile extends StatelessWidget {
  const _RoomImageTile({
    required this.roomId,
    required this.room,
    required this.onTap,
  });

  final String roomId;
  final Map<String, dynamic> room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final name = (room['name'] ?? roomId).toString();
    final floor = _roomFloor(room);
    final coverImageUrl = (room['coverImageUrl'] ?? '').toString();
    final imageCount = _imageUrls(room).length;
    final status = _statusFromRoom(room);
    final color = _statusColor(status);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22),
                      ),
                      child: coverImageUrl.isEmpty
                          ? const _RoomImagePlaceholder()
                          : Image.network(
                              coverImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const _RoomImagePlaceholder(),
                            ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _ImageCountBadge(count: imageCount),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.94),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          floor > 0 ? 'Tầng $floor' : 'Chưa rõ tầng',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.11),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          _statusLabel(status),
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

class _RoomCoverPreview extends StatelessWidget {
  const _RoomCoverPreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        color: Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: imageUrl.isEmpty
                ? const _RoomImagePlaceholder()
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _RoomImagePlaceholder(),
                  ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.52),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Ảnh chính trên quảng cáo',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomImageManageTile extends StatelessWidget {
  const _RoomImageManageTile({
    required this.imageUrl,
    required this.isCover,
    required this.onSetCover,
    required this.onDelete,
  });

  final String imageUrl;
  final bool isCover;
  final VoidCallback? onSetCover;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCover ? AppColors.primary : AppColors.border,
          width: isCover ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            imageUrl,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const _RoomImagePlaceholder(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.62),
                  ],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isCover ? 'Ảnh chính' : 'Đặt ảnh chính',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  if (!isCover)
                    IconButton.filledTonal(
                      visualDensity: VisualDensity.compact,
                      onPressed: onSetCover,
                      icon: const Icon(Icons.star_border, size: 18),
                    )
                  else
                    const Icon(Icons.star, color: Colors.white, size: 22),
                ],
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton.filled(
              visualDensity: VisualDensity.compact,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.92),
                foregroundColor: Colors.redAccent,
              ),
              tooltip: 'Xóa ảnh',
              onPressed: onDelete,
              icon: const Icon(Icons.delete_outline, size: 19),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomImagePlaceholder extends StatelessWidget {
  const _RoomImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFEAF1FF), Color(0xFFF8FBFF)],
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.primary,
          size: 36,
        ),
      ),
    );
  }
}

class _RoomImageEmptyState extends StatelessWidget {
  const _RoomImageEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: const [
          Icon(Icons.photo_library_outlined, size: 48, color: AppColors.primary),
          SizedBox(height: 10),
          Text(
            'Phòng này chưa có ảnh. Hủy thêm nhiều ảnh từ thiết bị.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _PublishActionCard extends StatelessWidget {
  const _PublishActionCard({
    required this.isLoading,
    required this.isPublished,
    required this.imageCount,
    required this.onPressed,
  });

  final bool isLoading;
  final bool isPublished;
  final int imageCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isPublished
                  ? Icons.verified_outlined
                  : Icons.rocket_launch_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPublished
                      ? 'Quảng cáo đang hiển thị'
                      : 'Sẵn sàng đẩy lên Trang chủ',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '$imageCount ảnh phòng sẽ đi kèm nội dung quảng cáo.',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: isLoading ? null : onPressed,
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 46),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.campaign_outlined, size: 18),
            label: const Text('Lưu'),
          ),
        ],
      ),
    );
  }
}

class _RoomImageSheetHeader extends StatelessWidget {
  const _RoomImageSheetHeader({
    required this.name,
    required this.status,
    required this.imageCount,
    required this.isBusy,
    required this.onClose,
  });

  final String name;
  final String status;
  final int imageCount;
  final bool isBusy;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);

    return _SectionShell(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.meeting_room_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ảnh phòng $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _TinyPill(
                      icon: Icons.circle,
                      label: _statusLabel(status),
                      color: color,
                    ),
                    _TinyPill(
                      icon: Icons.image_outlined,
                      label: '$imageCount ảnh',
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'đếng',
            onPressed: isBusy ? null : onClose,
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, color: AppColors.primary),
    );
  }
}

class _AdContentTile extends StatelessWidget {
  const _AdContentTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.tint,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color tint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: tint.withValues(alpha: 0.13)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.88),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: tint, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: tint,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    height: 1.28,
                    fontWeight: FontWeight.w800,
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

class _HeroMetricPill extends StatelessWidget {
  const _HeroMetricPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge({required this.isLive});

  final bool isLive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLive ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            isLive ? 'Live' : 'Nháp',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloorFilterChip extends StatelessWidget {
  const _FloorFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, color: Colors.white, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageCountBadge extends StatelessWidget {
  const _ImageCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined, size: 14, color: AppColors.primary),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  const _TinyPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineState extends StatelessWidget {
  const _InlineState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 22),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 34),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DecorCircle extends StatelessWidget {
  const _DecorCircle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

class _AdEmptyState extends StatelessWidget {
  const _AdEmptyState({
    required this.icon,
    required this.message,
  });

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: _SectionShell(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(icon, size: 42, color: AppColors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _text(Object? value, String fallback) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? fallback : text;
}

int _readInt(Object? value) {
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _roomFloor(Map<String, dynamic> room) {
  final floor = _readInt(room['floor']);
  if (floor > 0) return floor;

  final roomNumber = _readInt(room['roomNumber']);
  if (roomNumber >= 100) return roomNumber ~/ 100;
  return 0;
}

String _money(int amount) {
  final negative = amount < 0;
  final digits = amount.abs().toString();
  final buffer = StringBuffer();

  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(digits[index]);
  }

  return '${negative ? '-' : ''}${buffer.toString()} VND';
}

String _amenitiesText(Object? value) {
  if (value is! Map) return '';

  final labels = <String>[];
  if (value['wifi'] == true) labels.add('Wifi');
  if (value['elevator'] == true) labels.add('Thang máy');
  if (value['camera'] == true) labels.add('Camera');
  if (value['parking'] == true) labels.add('Chỗ để xe');
  if (value['laundry'] == true) labels.add('Máy giặt');
  if (value['security'] == true) labels.add('Bảo vệ');
  return labels.join(', ');
}

String _servicePricesText(Map<String, dynamic> building) {
  final items = <String>[];

  void addPrice(String label, Object? value) {
    final amount = _readInt(value);
    if (amount > 0) items.add('$label ${_money(amount)}');
  }

  addPrice('Điện', building['electricityPrice']);
  addPrice('Nước', building['waterPrice']);
  addPrice('Dịch vụ', building['serviceFee']);
  addPrice('Internet', building['internetFee']);
  addPrice('Gửi xe', building['parkingFee']);
  return items.join(', ');
}

String _statusFromRoom(Map<String, dynamic> room) {
  final tenantId = (room['tenantId'] ?? '').toString();
  final tenantName = (room['tenantName'] ?? '').toString();
  if (tenantId.isNotEmpty || tenantName.isNotEmpty) return 'occupied';
  final status = (room['status'] ?? 'available').toString();
  if (status == 'occupied' || status == 'maintenance' || status == 'reserved') {
    return status;
  }
  return 'available';
}

String _statusLabel(String status) {
  return switch (status) {
    'occupied' => 'Đã thuê',
    'maintenance' => 'Bảo trì',
    'reserved' => 'Đã đặt',
    _ => 'Trống',
  };
}

Color _statusColor(String status) {
  return switch (status) {
    'occupied' => AppColors.primary,
    'maintenance' => const Color(0xFFF59E0B),
    'reserved' => const Color(0xFFA855F7),
    _ => const Color(0xFF16A34A),
  };
}

List<String> _imageUrls(Map<String, dynamic> room) {
  final urls = <String>{};
  final value = room['imageUrls'];
  if (value is List) {
    urls.addAll(
      value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty),
    );
  }

  for (final key in ['coverImageUrl', 'imageUrl', 'thumbnailUrl']) {
    final url = room[key]?.toString().trim() ?? '';
    if (url.isNotEmpty) urls.add(url);
  }

  return urls.toList();
}
