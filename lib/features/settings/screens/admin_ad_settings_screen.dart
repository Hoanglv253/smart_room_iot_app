import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        const SnackBar(content: Text('Da day quang cao len trang chu.')),
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
      appBar: AppBar(title: const Text('Thiet lap quang cao')),
      body: AnimatedBuilder(
        animation: _viewModel,
        builder: (context, _) {
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: _viewModel.building(widget.buildingId),
            builder: (context, buildingSnapshot) {
              if (buildingSnapshot.hasError) {
                return const _AdEmptyState(
                  icon: Icons.lock_outline,
                  message: 'Khong tai duoc thong tin toa nha.',
                );
              }

              if (buildingSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (buildingSnapshot.data?.exists != true) {
                return const _AdEmptyState(
                  icon: Icons.apartment_outlined,
                  message: 'Hay luu thiet lap toa nha truoc khi tao quang cao.',
                );
              }

              final building = buildingSnapshot.data!.data() ?? {};

              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _viewModel.buildingRooms(widget.buildingId),
                builder: (context, roomSnapshot) {
                  final rooms = roomSnapshot.data?.docs ?? [];

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _BuildingPreviewCard(building: building),
                      const SizedBox(height: 16),
                      _RoomButtonSection(
                        viewModel: _viewModel,
                        buildingId: widget.buildingId,
                        isLoading: roomSnapshot.connectionState ==
                            ConnectionState.waiting,
                        hasError: roomSnapshot.hasError,
                        rooms: rooms,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _viewModel.isLoading ? null : _publishAd,
                        icon: _viewModel.isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.campaign_outlined),
                        label: const Text('Luu va day len trang chu'),
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
      return 'Firestore chua cap quyen cap nhat quang cao toa nha.';
    }

    return 'Khong luu duoc quang cao.';
  }
}

class _BuildingPreviewCard extends StatelessWidget {
  const _BuildingPreviewCard({required this.building});

  final Map<String, dynamic> building;

  @override
  Widget build(BuildContext context) {
    final name = _text(building['name'], 'Toa nha');
    final address = _text(building['address'], 'Chua co dia chi');
    final description = _text(building['description'], 'Chua co mo ta');
    final phone = _text(building['phone'], 'Chua co so dien thoai');
    final email = _text(building['email'], 'Chua co email');
    final adminName = _text(building['adminName'], 'Admin');
    final amenities = _amenitiesText(building['amenities']);
    final servicePrices = _servicePricesText(building);
    final rules = _text(building['rulesText'], 'Chua co noi quy');
    final totalRooms = _readInt(building['totalRooms']);
    final floorCount = _readInt(building['floorCount']);
    final defaultRent = _readInt(building['defaultRent']);
    final adPublished = building['adPublished'] == true;

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: Color(0xFFE0F2FE),
                  child: Icon(Icons.campaign_outlined, color: Color(0xFF2563EB)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Noi dung quang cao',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Chip(
                  label: Text(adPublished ? 'Dang hien thi' : 'Chua dang'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _AdInfoRow(label: 'Ten toa nha', value: name),
            _AdInfoRow(label: 'Dia chi', value: address),
            _AdInfoRow(label: 'Mo ta', value: description),
            _AdInfoRow(label: 'Admin', value: adminName),
            _AdInfoRow(label: 'Lien he', value: '$phone - $email'),
            _AdInfoRow(
              label: 'Tien ich',
              value: amenities.isEmpty ? 'Chua thiet lap' : amenities,
            ),
            _AdInfoRow(
              label: 'Phi dich vu',
              value: servicePrices.isEmpty ? 'Chua thiet lap' : servicePrices,
            ),
            _AdInfoRow(
              label: 'Quy mo',
              value: [
                if (floorCount > 0) '$floorCount tang',
                if (totalRooms > 0) '$totalRooms phong',
              ].isEmpty
                  ? 'Chua thiet lap'
                  : [
                      if (floorCount > 0) '$floorCount tang',
                      if (totalRooms > 0) '$totalRooms phong',
                    ].join(' - '),
            ),
            _AdInfoRow(
              label: 'Gia mac dinh',
              value: defaultRent > 0 ? '$defaultRent VND/thang' : 'Chua thiet lap',
            ),
            _AdInfoRow(label: 'Noi quy', value: rules),
          ],
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
}

class _RoomButtonSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ảnh và trạng thái phòng',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Bấm vào từng phòng để thêm ảnh từ thư viện, đặt ảnh chính hoặc xóa ảnh.',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const LinearProgressIndicator(minHeight: 2)
            else if (hasError)
              const Text('Khong tai duoc danh sach phong.')
            else if (rooms.isEmpty)
              const Text('Chua co phong nao de hien thi.')
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: rooms.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: MediaQuery.of(context).size.width >= 560 ? 3 : 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.78,
                ),
                itemBuilder: (context, index) {
                  final roomDoc = rooms[index];
                  return _RoomImageTile(
                    roomId: roomDoc.id,
                    room: roomDoc.data(),
                    onTap: () => _openRoomImages(context, roomDoc.id),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  void _openRoomImages(BuildContext context, String roomId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: viewModel.room(buildingId: buildingId, roomId: roomId),
          builder: (context, snapshot) {
            final room = snapshot.data?.data() ?? {};
            final name = (room['name'] ?? roomId).toString();
            final imageUrls = _imageUrls(room);
            final coverImageUrl = (room['coverImageUrl'] ?? '').toString();

            return AnimatedBuilder(
              animation: viewModel,
              builder: (context, _) {
                return DraggableScrollableSheet(
                  expand: false,
                  initialChildSize: 0.86,
                  minChildSize: 0.55,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Ảnh phòng $name',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Đóng',
                              onPressed: viewModel.isLoading
                                  ? null
                                  : () => Navigator.of(sheetContext).pop(),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _RoomCoverPreview(imageUrl: coverImageUrl),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: viewModel.isLoading
                              ? null
                              : () => _pickAndUploadImage(sheetContext, roomId),
                          icon: viewModel.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.photo_library_outlined),
                          label: const Text('Thêm ảnh từ thư viện'),
                        ),
                        const SizedBox(height: 18),
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
                              mainAxisSpacing: 10,
                              crossAxisSpacing: 10,
                              childAspectRatio: 0.78,
                            ),
                            itemBuilder: (context, index) {
                              final imageUrl = imageUrls[index];
                              return _RoomImageManageTile(
                                imageUrl: imageUrl,
                                isCover: imageUrl == coverImageUrl,
                                onSetCover: viewModel.isLoading
                                    ? null
                                    : () => _setCover(sheetContext, roomId, imageUrl),
                                onDelete: viewModel.isLoading
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

  Future<void> _pickAndUploadImage(BuildContext context, String roomId) async {
    final result = await viewModel.pickAndUploadRoomImage(
      buildingId: buildingId,
      roomId: roomId,
    );

    if (!context.mounted || result == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result ? 'Đã thêm ảnh phòng.' : _imageErrorMessage(),
        ),
      ),
    );
  }

  Future<void> _setCover(
    BuildContext context,
    String roomId,
    String imageUrl,
  ) async {
    final ok = await viewModel.setCoverImage(
      buildingId: buildingId,
      roomId: roomId,
      imageUrl: imageUrl,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã đặt ảnh chính.' : _imageErrorMessage())),
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

    final ok = await viewModel.deleteRoomImage(
      buildingId: buildingId,
      roomId: roomId,
      imageUrl: imageUrl,
    );

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ok ? 'Đã xóa ảnh phòng.' : _imageErrorMessage())),
    );
  }

  String _imageErrorMessage() {
    final error = viewModel.errorMessage ?? '';
    if (error.contains('MissingPluginException')) {
      return 'Cần dừng app và chạy lại từ đầu sau khi thêm image_picker.';
    }
    if (error.contains('CLOUDINARY_CLOUD_NAME')) {
      return 'Chưa cấu hình Cloudinary cho app.';
    }
    if (error.contains('Cloudinary upload failed')) {
      return 'Cloudinary chưa nhận ảnh. Kiểm tra cloud name hoặc upload preset.';
    }
    if (error.contains('permission-denied')) {
      return 'Firestore chưa cấp quyền lưu link ảnh phòng.';
    }
    if (error.contains('TimeoutException')) {
      return 'Kết nối Cloudinary quá lâu. Kiểm tra mạng rồi thử lại.';
    }
    return 'Không xử lý được ảnh phòng.';
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

  static List<String> _imageUrls(Map<String, dynamic> room) {
    final value = room['imageUrls'];
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
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
    final coverImageUrl = (room['coverImageUrl'] ?? '').toString();
    final imageCount = _RoomButtonSection._imageUrls(room).length;
    final status = _RoomButtonSection._statusFromRoom(room);
    final color = _RoomButtonSection._statusColor(status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
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
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_RoomButtonSection._statusLabel(status)} - $imageCount ảnh',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: color, fontSize: 12),
                        ),
                      ),
                      const Icon(Icons.add_photo_alternate_outlined, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: imageUrl.isEmpty
            ? const _RoomImagePlaceholder()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _RoomImagePlaceholder(),
              ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCover ? Colors.blueAccent : const Color(0xFFE5E7EB),
          width: isCover ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const _RoomImagePlaceholder(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  tooltip: 'Đặt làm ảnh chính',
                  onPressed: isCover ? null : onSetCover,
                  icon: Icon(
                    isCover ? Icons.star : Icons.star_border,
                    color: Colors.blueAccent,
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa ảnh',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                ),
              ],
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
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: Color(0xFF2563EB),
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
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Column(
        children: [
          Icon(Icons.photo_library_outlined, size: 48, color: Colors.blueAccent),
          SizedBox(height: 10),
          Text(
            'Phòng này chưa có ảnh. Hãy thêm ảnh từ thư viện điện thoại.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AdInfoRow extends StatelessWidget {
  const _AdInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.blueAccent),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
