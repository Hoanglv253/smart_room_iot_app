import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/data/vietnam_admin_units.dart';
import '../../../core/services/app_firestore_service.dart';
import '../../../core/services/map_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/building_map_preview.dart';
import '../../messages/screens/chat_detail_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../view_models/feed_view_model.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({required this.user, required this.role, super.key});

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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Text(
              'Trang chủ',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Tìm tòa nhà, quản lý, người thuê...',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                _FeedFilterButton(
                  active: _hasActiveFilters,
                  onPressed: _showFilterSheet,
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

  bool get _hasActiveFilters {
    return _viewModel.filter != FeedFilter.buildings ||
        _viewModel.hasBuildingFilters;
  }

  void _showFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: AnimatedBuilder(
            animation: _viewModel,
            builder: (context, _) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Bộ lọc hiển thị',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Tòa nhà'),
                          selected: _viewModel.filter == FeedFilter.buildings,
                          onSelected: (_) =>
                              _viewModel.setFilter(FeedFilter.buildings),
                        ),
                        ChoiceChip(
                          label: const Text('Quản lý'),
                          selected: _viewModel.filter == FeedFilter.managers,
                          onSelected: (_) =>
                              _viewModel.setFilter(FeedFilter.managers),
                        ),
                        ChoiceChip(
                          label: const Text('Người thuê'),
                          selected: _viewModel.filter == FeedFilter.tenants,
                          onSelected: (_) =>
                              _viewModel.setFilter(FeedFilter.tenants),
                        ),
                      ],
                    ),
                    if (_viewModel.filter == FeedFilter.buildings) ...[
                      const SizedBox(height: 18),
                      Text(
                        'Lọc tòa nhà',
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                      ),
                      const SizedBox(height: 10),
                      _BuildingFilterBar(viewModel: _viewModel),
                    ],
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FeedFilterButton extends StatelessWidget {
  const _FeedFilterButton({
    required this.active,
    required this.onPressed,
  });

  final bool active;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final accent = active ? AppColors.primary : AppColors.textSecondary;

    return Material(
      color: active ? AppColors.primarySoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: active
              ? AppColors.primary.withValues(alpha: 0.28)
              : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onPressed,
        child: SizedBox(
          width: 54,
          height: 54,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(Icons.tune_rounded, color: accent),
              if (active)
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String _normalizeSearchText(Object? value) {
  final text = value?.toString().toLowerCase() ?? '';
  return text
      .replaceAll(RegExp(r'[àáạảãâầấậẩẫăằắặẳẵ]'), 'a')
      .replaceAll(RegExp(r'[èéẹẻẽêềếệểễ]'), 'e')
      .replaceAll(RegExp(r'[ìíịỉĩ]'), 'i')
      .replaceAll(RegExp(r'[òóọỏõôồốộổỗơờớợởỡ]'), 'o')
      .replaceAll(RegExp(r'[ùúụủũưừứựửữ]'), 'u')
      .replaceAll(RegExp(r'[ỳýỵỷỹ]'), 'y')
      .replaceAll('đ', 'd');
}

class _BuildingFilterBar extends StatelessWidget {
  const _BuildingFilterBar({required this.viewModel});

  final FeedViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final onlyAvailable =
        viewModel.availabilityFilter == BuildingAvailabilityFilter.available;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          selected: onlyAvailable,
          avatar: const Icon(Icons.meeting_room_outlined, size: 18),
          label: const Text('Còn phòng'),
          onSelected: (selected) {
            viewModel.setAvailabilityFilter(
              selected
                  ? BuildingAvailabilityFilter.available
                  : BuildingAvailabilityFilter.all,
            );
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.payments_outlined, size: 18),
          label: Text(_priceLabel(viewModel.priceFilter)),
          onPressed: () => _showPriceSheet(context),
        ),
        ActionChip(
          avatar: const Icon(Icons.location_on_outlined, size: 18),
          label: Text(_provinceLabel(viewModel.provinceFilter)),
          onPressed: () => _showProvinceSheet(context),
        ),
        ActionChip(
          avatar: const Icon(Icons.place_outlined, size: 18),
          label: Text(_wardLabel(viewModel.wardFilter)),
          onPressed: () => _showWardSheet(context),
        ),
        ActionChip(
          avatar: const Icon(Icons.sort_outlined, size: 18),
          label: Text(_sortLabel(viewModel.sortOption)),
          onPressed: () => _showSortSheet(context),
        ),
        if (viewModel.hasBuildingFilters)
          ActionChip(
            avatar: const Icon(Icons.refresh_outlined, size: 18),
            label: const Text('Đặt lại'),
            onPressed: viewModel.resetBuildingFilters,
          ),
      ],
    );
  }

  void _showProvinceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHeader(title: 'Lọc theo tỉnh/thành'),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _ProvinceOption(
                      value: '',
                      groupValue: viewModel.provinceFilter,
                      title: 'Tất cả tỉnh/thành',
                      onChanged: (value) => _selectProvince(context, value),
                    ),
                    ...vietnamProvinceNames.map(
                      (province) => _ProvinceOption(
                        value: province,
                        groupValue: viewModel.provinceFilter,
                        title: province,
                        onChanged: (value) => _selectProvince(context, value),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWardSheet(BuildContext context) {
    final controller = TextEditingController(text: viewModel.wardFilter);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _SheetHeader(title: 'Lọc theo xã/phường'),
                TextField(
                  controller: controller,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'Nhập tên xã/phường',
                    prefixIcon: Icon(Icons.place_outlined),
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) =>
                      _applyWardFilter(context, controller.text),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => _applyWardFilter(context, ''),
                      child: const Text('Xóa'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: () =>
                          _applyWardFilter(context, controller.text),
                      child: const Text('Áp dụng'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(controller.dispose);
  }

  void _showPriceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHeader(title: 'Lọc theo giá phòng'),
              _PriceOption(
                value: BuildingPriceFilter.all,
                groupValue: viewModel.priceFilter,
                title: 'Tất cả',
                onChanged: (value) => _selectPrice(context, value),
              ),
              _PriceOption(
                value: BuildingPriceFilter.under2m,
                groupValue: viewModel.priceFilter,
                title: 'Dưới 2 triệu',
                onChanged: (value) => _selectPrice(context, value),
              ),
              _PriceOption(
                value: BuildingPriceFilter.from2mTo4m,
                groupValue: viewModel.priceFilter,
                title: 'Từ 2 đến 4 triệu',
                onChanged: (value) => _selectPrice(context, value),
              ),
              _PriceOption(
                value: BuildingPriceFilter.above4m,
                groupValue: viewModel.priceFilter,
                title: 'Trên 4 triệu',
                onChanged: (value) => _selectPrice(context, value),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const _SheetHeader(title: 'Sắp xếp quảng cáo'),
              _SortOption(
                value: BuildingSortOption.newest,
                groupValue: viewModel.sortOption,
                title: 'Mới nhất',
                onChanged: (value) => _selectSort(context, value),
              ),
              _SortOption(
                value: BuildingSortOption.priceAsc,
                groupValue: viewModel.sortOption,
                title: 'Giá thấp đến cao',
                onChanged: (value) => _selectSort(context, value),
              ),
              _SortOption(
                value: BuildingSortOption.priceDesc,
                groupValue: viewModel.sortOption,
                title: 'Giá cao đến thấp',
                onChanged: (value) => _selectSort(context, value),
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectProvince(BuildContext context, String? value) {
    if (value == null) return;
    viewModel.setProvinceFilter(value);
    Navigator.pop(context);
  }

  void _applyWardFilter(BuildContext context, String value) {
    viewModel.setWardFilter(value);
    Navigator.pop(context);
  }

  void _selectPrice(BuildContext context, BuildingPriceFilter? value) {
    if (value == null) return;
    viewModel.setPriceFilter(value);
    Navigator.pop(context);
  }

  void _selectSort(BuildContext context, BuildingSortOption? value) {
    if (value == null) return;
    viewModel.setSortOption(value);
    Navigator.pop(context);
  }

  static String _priceLabel(BuildingPriceFilter filter) {
    return switch (filter) {
      BuildingPriceFilter.all => 'Giá',
      BuildingPriceFilter.under2m => 'Dưới 2 triệu',
      BuildingPriceFilter.from2mTo4m => '2-4 triệu',
      BuildingPriceFilter.above4m => 'Trên 4 triệu',
    };
  }

  static String _provinceLabel(String value) =>
      value.trim().isEmpty ? 'Tỉnh/thành' : value.trim();

  static String _wardLabel(String value) =>
      value.trim().isEmpty ? 'Xã/phường' : value.trim();

  static String _sortLabel(BuildingSortOption option) {
    return switch (option) {
      BuildingSortOption.newest => 'Mới nhất',
      BuildingSortOption.priceAsc => 'Giá thấp',
      BuildingSortOption.priceDesc => 'Giá cao',
    };
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _ProvinceOption extends StatelessWidget {
  const _ProvinceOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  final String value;
  final String groupValue;
  final String title;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return ListTile(
      title: Text(title),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF365A9B))
          : null,
      selected: selected,
      onTap: () => onChanged(value),
    );
  }
}

class _PriceOption extends StatelessWidget {
  const _PriceOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  final BuildingPriceFilter value;
  final BuildingPriceFilter groupValue;
  final String title;
  final ValueChanged<BuildingPriceFilter?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return ListTile(
      title: Text(title),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF365A9B))
          : null,
      selected: selected,
      onTap: () => onChanged(value),
    );
  }
}

class _SortOption extends StatelessWidget {
  const _SortOption({
    required this.value,
    required this.groupValue,
    required this.title,
    required this.onChanged,
  });

  final BuildingSortOption value;
  final BuildingSortOption groupValue;
  final String title;
  final ValueChanged<BuildingSortOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;

    return ListTile(
      title: Text(title),
      trailing: selected
          ? const Icon(Icons.check, color: Color(0xFF365A9B))
          : null,
      selected: selected,
      onTap: () => onChanged(value),
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
            message: 'Không tải được danh sách quảng cáo tòa nhà.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final buildings = (snapshot.data?.docs ?? [])
            .where((doc) => _matchesBuildingSearch(doc.data(), query))
            .where(
              (doc) => _matchesArea(
                doc.data(),
                province: viewModel.provinceFilter,
                ward: viewModel.wardFilter,
              ),
            )
            .where(
              (doc) => _matchesAvailability(
                doc.data(),
                viewModel.availabilityFilter,
              ),
            )
            .where((doc) => _matchesPrice(doc.data(), viewModel.priceFilter))
            .toList();

        _sortBuildings(buildings, viewModel.sortOption);

        if (buildings.isEmpty) {
          return const _FeedEmptyState(
            icon: Icons.apartment_outlined,
            message: 'Chưa có quảng cáo tòa nhà phù hợp.',
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

  static Map<String, dynamic> _readMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, dynamic value) => MapEntry(key.toString(), value));
    }
    return {};
  }

  static bool _matchesBuildingSearch(Map<String, dynamic> data, String query) {
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return true;
    final location = _readMap(data['location']);
    final haystack = [
      data['name'],
      data['address'],
      data['fullAddress'],
      data['formattedAddress'],
      data['province'],
      data['provinceName'],
      data['district'],
      data['ward'],
      data['wardName'],
      data['city'],
      location['address'],
      location['fullAddress'],
      location['formattedAddress'],
      location['province'],
      location['provinceName'],
      location['ward'],
      location['wardName'],
      location['city'],
      data['description'],
      data['adminName'],
      data['phone'],
      data['email'],
    ].map(_normalizeSearchText).join(' ');

    return haystack.contains(normalizedQuery);
  }

  static bool _matchesArea(
    Map<String, dynamic> data, {
    required String province,
    required String ward,
  }) {
    final normalizedProvince = _normalizeSearchText(province);
    final normalizedWard = _normalizeSearchText(ward);
    if (normalizedProvince.isEmpty && normalizedWard.isEmpty) return true;

    final location = _readMap(data['location']);
    final provinceText = [
      data['province'],
      data['provinceName'],
      data['city'],
      location['province'],
      location['provinceName'],
      location['city'],
      data['address'],
      data['fullAddress'],
      data['formattedAddress'],
      location['address'],
      location['fullAddress'],
      location['formattedAddress'],
    ].map(_normalizeSearchText).join(' ');

    final wardText = [
      data['ward'],
      data['wardName'],
      location['ward'],
      location['wardName'],
      data['address'],
      data['fullAddress'],
      data['formattedAddress'],
      location['address'],
      location['fullAddress'],
      location['formattedAddress'],
    ].map(_normalizeSearchText).join(' ');

    if (normalizedProvince.isNotEmpty &&
        !provinceText.contains(normalizedProvince)) {
      return false;
    }
    if (normalizedWard.isNotEmpty && !wardText.contains(normalizedWard)) {
      return false;
    }
    return true;
  }

  static bool _matchesAvailability(
    Map<String, dynamic> data,
    BuildingAvailabilityFilter filter,
  ) {
    if (filter == BuildingAvailabilityFilter.all) return true;

    final availableRooms =
        _optionalInt(data['availableRoomCount']) ??
        _optionalInt(data['availableRooms']) ??
        _optionalInt(data['emptyRoomCount']) ??
        _optionalInt(data['emptyRooms']) ??
        _optionalInt(data['vacantRoomCount']) ??
        _optionalInt(data['vacantRooms']);
    if (availableRooms != null) return availableRooms > 0;

    final totalRooms = _optionalInt(data['totalRooms']);
    final occupiedRooms =
        _optionalInt(data['occupiedRoomCount']) ??
        _optionalInt(data['occupiedRooms']) ??
        _optionalInt(data['rentedRoomCount']) ??
        _optionalInt(data['rentedRooms']);
    if (totalRooms != null && occupiedRooms != null) {
      return totalRooms > occupiedRooms;
    }

    final status = [
      data['availabilityStatus'],
      data['roomStatus'],
      data['status'],
    ].map((value) => value?.toString().toLowerCase() ?? '').join(' ');
    if (status.contains('full') || status.contains('het')) return false;
    if (status.contains('available') || status.contains('con')) return true;

    return true;
  }

  static bool _matchesPrice(
    Map<String, dynamic> data,
    BuildingPriceFilter filter,
  ) {
    if (filter == BuildingPriceFilter.all) return true;

    final rent = _buildingRent(data);
    if (rent <= 0) return false;

    return switch (filter) {
      BuildingPriceFilter.all => true,
      BuildingPriceFilter.under2m => rent < 2000000,
      BuildingPriceFilter.from2mTo4m => rent >= 2000000 && rent <= 4000000,
      BuildingPriceFilter.above4m => rent > 4000000,
    };
  }

  static void _sortBuildings(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> buildings,
    BuildingSortOption option,
  ) {
    buildings.sort((a, b) {
      return switch (option) {
        BuildingSortOption.newest => _compareNewest(a, b),
        BuildingSortOption.priceAsc => _compareRent(a, b, ascending: true),
        BuildingSortOption.priceDesc => _compareRent(a, b, ascending: false),
      };
    });
  }

  static int _compareNewest(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b,
  ) {
    final left = _timestampMillis(a.data()['adUpdatedAt']);
    final right = _timestampMillis(b.data()['adUpdatedAt']);
    return right.compareTo(left);
  }

  static int _compareRent(
    QueryDocumentSnapshot<Map<String, dynamic>> a,
    QueryDocumentSnapshot<Map<String, dynamic>> b, {
    required bool ascending,
  }) {
    final left = _buildingRent(a.data());
    final right = _buildingRent(b.data());
    if (left <= 0 && right <= 0) return _compareNewest(a, b);
    if (left <= 0) return 1;
    if (right <= 0) return -1;
    final compared = left.compareTo(right);
    return ascending ? compared : -compared;
  }

  static int _buildingRent(Map<String, dynamic> data) {
    for (final key in ['defaultRent', 'minRent', 'roomRent', 'rent', 'price']) {
      final value = _moneyInt(data[key]);
      if (value > 0) return value;
    }
    return 0;
  }

  static int? _optionalInt(Object? value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static int _moneyInt(Object? value) {
    if (value is num) return value.toInt();
    final digits = value?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    return int.tryParse(digits) ?? 0;
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
    final name = _text(building['name'], 'Tòa nhà');
    final address = _text(building['address'], 'Chưa có Địa chỉ');
    final description = _text(building['description'], 'Chưa có mô tả');
    final adminName = _text(building['adminName'], 'Admin');
    final phone = _text(building['phone'], 'Chưa có số điện thoại');
    final email = _text(building['email'], 'Chưa có email');
    final amenities = _amenitiesText(building['amenities']);
    final servicePrices = _servicePricesText(building);
    final rules = _text(building['rulesText'], '');
    final totalRooms = _readInt(building['totalRooms']);
    final floorCount = _readInt(building['floorCount']);
    final defaultRent = _readInt(building['defaultRent']);
    final adminId = (building['adminId'] ?? '').toString();
    final isOwnBuilding = adminId == user.uid;
    final canOpenDirections = MapService.canOpenDirections(building);

    if (!showFullDetails) {
      return _CompactBuildingAdCard(
        name: name,
        address: address,
        description: description,
        totalRooms: totalRooms,
        floorCount: floorCount,
        defaultRent: defaultRent,
        coverImageUrl: _coverImageUrl(building),
        isOwnBuilding: isOwnBuilding,
        canOpenDirections: canOpenDirections,
        onOpenDetails: () => _openDetails(context),
        onMessageAdmin: () => _messageAdmin(context),
        onOpenDirections: () => _openDirections(context),
      );
    }

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
                  child: Icon(
                    Icons.apartment_outlined,
                    color: Color(0xFF2563EB),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        address,
                        style: const TextStyle(color: Colors.black54),
                      ),
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
                Text('Tiện ích: $amenities'),
              ],
              if (servicePrices.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Phí dịch vụ: $servicePrices'),
              ],
              if (rules.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Nội quy: $rules'),
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
                  text: totalRooms > 0 ? '$totalRooms phòng' : 'Chưa có phòng',
                ),
                _InfoPill(
                  icon: Icons.layers_outlined,
                  text: floorCount > 0 ? '$floorCount tầng' : 'Chưa có số tầng',
                ),
                _InfoPill(
                  icon: Icons.payments_outlined,
                  text: defaultRent > 0
                      ? '${_money(defaultRent)}/tháng'
                      : 'Chưa có giá',
                ),
              ],
            ),
            if (showFullDetails) ...[
              const SizedBox(height: 12),
              _RoomStatusBoard(buildingId: buildingId, viewModel: viewModel),
              const SizedBox(height: 12),
              Text(
                'Liên hệ: $phone - $email',
                style: const TextStyle(color: Colors.black54),
              ),
            ],
            if (canOpenDirections && !showFullDetails) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openDirections(context),
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Chỉ đường'),
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
                        label: const Text('Chat với admin'),
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openDetails(context),
                      icon: const Icon(Icons.expand_more),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      label: const Text('Xem thêm'),
                    ),
                  ),
                ],
              )
            else if (isOwnBuilding)
              const Align(
                alignment: Alignment.centerRight,
                child: Chip(label: Text('Tòa nhà của bạn')),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _messageAdmin(context),
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat với admin'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _requestJoin(context),
                      icon: const Icon(Icons.login_outlined),
                      label: const Text('Xin vào'),
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
              ? 'Đã gửi yêu cầu tham gia tòa nhà.'
              : viewModel.errorMessage ?? 'Không gửi được yêu cầu.',
        ),
      ),
    );
  }

  Future<void> _messageAdmin(BuildContext context) async {
    final adminId = (building['adminId'] ?? '').toString();
    if (adminId.isEmpty) return;

    final title = 'Chat với admin ${(building['adminName'] ?? '').toString()}';
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
          content: Text(viewModel.errorMessage ?? 'Không mở được khung chat.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatDetailScreen(chatId: chatId, chatTitle: title, user: user),
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final opened = await MapService.openDirectionsForBuilding(building);
    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Không mở được Google Maps.')));
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
    if (value['elevator'] == true) labels.add('Thang máy');
    if (value['camera'] == true) labels.add('Camera');
    if (value['parking'] == true) labels.add('Chỗ để xe');
    if (value['laundry'] == true) labels.add('Máy giặt');
    if (value['security'] == true) labels.add('Bảo vệ');
    return labels.join(', ');
  }

  static String _servicePricesText(Map<String, dynamic> building) {
    final items = <String>[];
    void addPrice(String label, Object? value) {
      final amount = _readInt(value);
      if (amount > 0) items.add('$label $amount VND');
    }

    addPrice('Điện', building['electricityPrice']);
    addPrice('Nước', building['waterPrice']);
    addPrice('Dịch vụ', building['serviceFee']);
    addPrice('Internet', building['internetFee']);
    addPrice('Gửi xe', building['parkingFee']);
    return items.join(', ');
  }

  static String _money(int value) {
    return '$value VND';
  }

  static String _coverImageUrl(Map<String, dynamic> building) {
    for (final key in ['coverImageUrl', 'imageUrl', 'thumbnailUrl']) {
      final value = building[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }

    final images = building['images'];
    if (images is List && images.isNotEmpty) {
      return images.first?.toString().trim() ?? '';
    }

    return '';
  }
}

class _CompactBuildingAdCard extends StatelessWidget {
  const _CompactBuildingAdCard({
    required this.name,
    required this.address,
    required this.description,
    required this.totalRooms,
    required this.floorCount,
    required this.defaultRent,
    required this.coverImageUrl,
    required this.isOwnBuilding,
    required this.canOpenDirections,
    required this.onOpenDetails,
    required this.onMessageAdmin,
    required this.onOpenDirections,
  });

  final String name;
  final String address;
  final String description;
  final int totalRooms;
  final int floorCount;
  final int defaultRent;
  final String coverImageUrl;
  final bool isOwnBuilding;
  final bool canOpenDirections;
  final VoidCallback onOpenDetails;
  final VoidCallback onMessageAdmin;
  final VoidCallback onOpenDirections;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BuildingAdThumbnail(imageUrl: coverImageUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _PrimaryCardAction(
                        icon: Icons.open_in_new_rounded,
                        label: 'Chi tiết',
                        onTap: onOpenDetails,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, height: 1.15),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _CompactInfoBadge(
                        icon: Icons.meeting_room_outlined,
                        text: totalRooms > 0 ? '$totalRooms phòng' : 'Phòng',
                      ),
                      if (floorCount > 0)
                        _CompactInfoBadge(
                          icon: Icons.layers_outlined,
                          text: '$floorCount tầng',
                        ),
                      const _CompactInfoBadge(
                        icon: Icons.check_circle_outline,
                        text: 'Còn phòng',
                        color: Color(0xFF16A34A),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          defaultRent > 0
                              ? '${_compactMoney(defaultRent)}/tháng'
                              : 'Liên hệ giá',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFD97706),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      if (!isOwnBuilding)
                        _SmallCardAction(
                          icon: Icons.chat_bubble_outline,
                          label: 'Chat',
                          onTap: onMessageAdmin,
                        ),
                      if (canOpenDirections) ...[
                        const SizedBox(width: 6),
                        _SmallCardAction(
                          icon: Icons.directions_outlined,
                          label: 'đường',
                          onTap: onOpenDirections,
                        ),
                      ],
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

  static String _compactMoney(int value) {
    if (value >= 1000000 && value % 1000000 == 0) {
      return '${value ~/ 1000000}.000.000 VND';
    }

    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '$buffer VND';
  }
}

class _BuildingAdThumbnail extends StatelessWidget {
  const _BuildingAdThumbnail({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 92,
        height: 104,
        child: imageUrl.isEmpty
            ? const _BuildingThumbnailFallback()
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const _BuildingThumbnailFallback(),
              ),
      ),
    );
  }
}

class _BuildingThumbnailFallback extends StatelessWidget {
  const _BuildingThumbnailFallback();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC)],
        ),
      ),
      child: Center(
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.apartment_rounded,
            color: AppColors.primary,
            size: 28,
          ),
        ),
      ),
    );
  }
}

class _CompactInfoBadge extends StatelessWidget {
  const _CompactInfoBadge({
    required this.icon,
    required this.text,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryCardAction extends StatelessWidget {
  const _PrimaryCardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallCardAction extends StatelessWidget {
  const _SmallCardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 3),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
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
    final name = _text(building['name'], 'Tòa nhà');
    final address = _text(building['address'], 'Chưa có Địa chỉ');
    final description = _text(building['description'], 'Chưa có mô tả');
    final adminName = _text(building['adminName'], 'Admin');
    final phone = _text(building['phone'], 'Chưa có số điện thoại');
    final email = _text(building['email'], 'Chưa có email');
    final rules = _text(building['rulesText'], '');
    final totalRooms = _readInt(building['totalRooms']);
    final floorCount = _readInt(building['floorCount']);
    final defaultRent = _readInt(building['defaultRent']);
    final adminId = (building['adminId'] ?? '').toString();
    final isOwnBuilding = adminId == user.uid;
    final canOpenDirections = MapService.canOpenDirections(building);
    final amenities = _amenityLabels(building['amenities']);
    final serviceFees = _serviceFees(building);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Chi tiết quảng cáo'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _AdDetailHeaderBackdrop(name: name),
          Transform.translate(
            offset: const Offset(0, -52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _AdDetailHeroCard(
                    name: name,
                    address: address,
                    adminName: adminName,
                    phone: phone,
                    email: email,
                    totalRooms: totalRooms,
                    floorCount: floorCount,
                    defaultRent: defaultRent,
                    isOwnBuilding: isOwnBuilding,
                    canOpenDirections: canOpenDirections,
                    onMessageAdmin: () => _messageAdmin(context),
                    onRequestJoin: () => _requestJoin(context),
                    onOpenDirections: () => _openDirections(context),
                  ),
                  const SizedBox(height: 14),
                  _AdDetailInfoGrid(
                    description: description,
                    amenities: amenities,
                    serviceFees: serviceFees,
                    rules: rules,
                  ),
                  const SizedBox(height: 14),
                  _RoomStatusBoard(
                    buildingId: buildingId,
                    viewModel: viewModel,
                  ),
                  const SizedBox(height: 14),
                  _AdDetailSectionCard(
                    icon: Icons.map_outlined,
                    title: 'Vị trí tòa nhà',
                    child: BuildingMapPreview(building: building),
                  ),
                  const SizedBox(height: 14),
                  _AdDetailSectionCard(
                    icon: Icons.mode_comment_outlined,
                    title: 'Bình luận',
                    child: _BuildingCommentsSection(
                      buildingId: buildingId,
                      user: user,
                      role: role,
                      viewModel: viewModel,
                      showAll: true,
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
              ? 'Đã gửi yêu cầu tham gia tòa nhà.'
              : viewModel.errorMessage ?? 'Không gửi được yêu cầu.',
        ),
      ),
    );
  }

  Future<void> _messageAdmin(BuildContext context) async {
    final adminId = (building['adminId'] ?? '').toString();
    if (adminId.isEmpty) return;

    final title = 'Chat với admin ${(building['adminName'] ?? '').toString()}';
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
          content: Text(viewModel.errorMessage ?? 'Không mở được khung chat.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ChatDetailScreen(chatId: chatId, chatTitle: title, user: user),
      ),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final opened = await MapService.openDirectionsForBuilding(building);
    if (!context.mounted || opened) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Không mở được Google Maps.')));
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<String> _amenityLabels(Object? value) {
    if (value is! Map) return const [];

    final labels = <String>[];
    if (value['wifi'] == true) labels.add('Wifi');
    if (value['elevator'] == true) labels.add('Thang máy');
    if (value['camera'] == true) labels.add('Camera');
    if (value['parking'] == true) labels.add('Chỗ để xe');
    if (value['laundry'] == true) labels.add('Máy giặt');
    if (value['security'] == true) labels.add('Bảo vệ');
    return labels;
  }

  static List<_ServiceFeeItem> _serviceFees(Map<String, dynamic> building) {
    final items = <_ServiceFeeItem>[];
    void addPrice(String label, Object? value) {
      final amount = _readInt(value);
      if (amount > 0) items.add(_ServiceFeeItem(label, amount));
    }

    addPrice('Điện', building['electricityPrice']);
    addPrice('Nước', building['waterPrice']);
    addPrice('Dịch vụ', building['serviceFee']);
    addPrice('Internet', building['internetFee']);
    addPrice('Gửi xe', building['parkingFee']);
    return items;
  }
}

class _AdDetailHeaderBackdrop extends StatelessWidget {
  const _AdDetailHeaderBackdrop({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(gradient: AppTheme.primaryGradient()),
      child: Stack(
        children: [
          Positioned(
            right: -28,
            top: 54,
            child: Icon(
              Icons.apartment_rounded,
              size: 152,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 72,
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdDetailHeroCard extends StatelessWidget {
  const _AdDetailHeroCard({
    required this.name,
    required this.address,
    required this.adminName,
    required this.phone,
    required this.email,
    required this.totalRooms,
    required this.floorCount,
    required this.defaultRent,
    required this.isOwnBuilding,
    required this.canOpenDirections,
    required this.onMessageAdmin,
    required this.onRequestJoin,
    required this.onOpenDirections,
  });

  final String name;
  final String address;
  final String adminName;
  final String phone;
  final String email;
  final int totalRooms;
  final int floorCount;
  final int defaultRent;
  final bool isOwnBuilding;
  final bool canOpenDirections;
  final VoidCallback onMessageAdmin;
  final VoidCallback onRequestJoin;
  final VoidCallback onOpenDirections;

  @override
  Widget build(BuildContext context) {
    return _AdDetailSurface(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: AppColors.primary,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.textSecondary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
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
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.payments_outlined, color: Color(0xFFD97706)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    defaultRent > 0
                        ? '${_detailMoney(defaultRent)}/tháng'
                        : 'Liên hệ giá',
                    style: const TextStyle(
                      color: Color(0xFFD97706),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (isOwnBuilding)
                  const Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text('Của bạn'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AdDetailPill(
                icon: Icons.person_outline,
                text: adminName,
              ),
              _AdDetailPill(
                icon: Icons.meeting_room_outlined,
                text: totalRooms > 0 ? '$totalRooms phòng' : 'Chưa có phòng',
              ),
              _AdDetailPill(
                icon: Icons.layers_outlined,
                text: floorCount > 0 ? '$floorCount tầng' : 'Chưa có tầng',
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AdContactLine(icon: Icons.phone_outlined, text: phone),
          const SizedBox(height: 6),
          _AdContactLine(icon: Icons.email_outlined, text: email),
          const SizedBox(height: 14),
          if (isOwnBuilding)
            const _OwnBuildingNotice()
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: onMessageAdmin,
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text('Liên hệ ngay'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onRequestJoin,
                    icon: const Icon(Icons.login_outlined),
                    label: const Text('Xin vào'),
                  ),
                ),
              ],
            ),
          if (canOpenDirections) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onOpenDirections,
                icon: const Icon(Icons.directions_outlined),
                label: const Text('Chỉ đường'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _detailMoney(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < text.length; i++) {
      final remaining = text.length - i;
      buffer.write(text[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '$buffer VND';
  }
}

class _AdDetailInfoGrid extends StatelessWidget {
  const _AdDetailInfoGrid({
    required this.description,
    required this.amenities,
    required this.serviceFees,
    required this.rules,
  });

  final String description;
  final List<String> amenities;
  final List<_ServiceFeeItem> serviceFees;
  final String rules;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AdDetailSectionCard(
          icon: Icons.notes_outlined,
          title: 'Mô tả',
          child: Text(description, style: const TextStyle(height: 1.35)),
        ),
        const SizedBox(height: 14),
        LayoutBuilder(
          builder: (context, constraints) {
            final amenitiesCard = _AdDetailSectionCard(
              icon: Icons.check_circle_outline,
              title: 'Tiện ích',
              child: amenities.isEmpty
                  ? const Text(
                      'Chưa có tiện ích.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: amenities
                          .map((label) => _AmenityTag(label: label))
                          .toList(),
                    ),
            );
            final feesCard = _AdDetailSectionCard(
              icon: Icons.receipt_long_outlined,
              title: 'Phí dịch vụ',
              child: serviceFees.isEmpty
                  ? const Text(
                      'Chưa có phí dịch vụ.',
                      style: TextStyle(color: AppColors.textSecondary),
                    )
                  : Column(
                      children: serviceFees
                          .map((item) => _ServiceFeeRow(item: item))
                          .toList(),
                    ),
            );

            if (constraints.maxWidth < 430) {
              return Column(
                children: [
                  amenitiesCard,
                  const SizedBox(height: 14),
                  feesCard,
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: amenitiesCard),
                const SizedBox(width: 14),
                Expanded(child: feesCard),
              ],
            );
          },
        ),
        if (rules.isNotEmpty) ...[
          const SizedBox(height: 14),
          _AdDetailSectionCard(
            icon: Icons.rule_outlined,
            title: 'Nội quy',
            child: Text(rules, style: const TextStyle(height: 1.35)),
          ),
        ],
      ],
    );
  }
}

class _AdDetailSectionCard extends StatelessWidget {
  const _AdDetailSectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _AdDetailSurface(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 21),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _AdDetailSurface extends StatelessWidget {
  const _AdDetailSurface({
    required this.child,
    required this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _AdDetailPill extends StatelessWidget {
  const _AdDetailPill({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _AdContactLine extends StatelessWidget {
  const _AdContactLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 17, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        ),
      ],
    );
  }
}

class _OwnBuildingNotice extends StatelessWidget {
  const _OwnBuildingNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEAFBF1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_outlined, color: Color(0xFF16A34A), size: 19),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Đây là tòa nhà của bạn.',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmenityTag extends StatelessWidget {
  const _AmenityTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }
}

class _ServiceFeeItem {
  const _ServiceFeeItem(this.label, this.amount);

  final String label;
  final int amount;
}

class _ServiceFeeRow extends StatelessWidget {
  const _ServiceFeeRow({required this.item});

  final _ServiceFeeItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          Text(
            '${item.amount} VND',
            style: const TextStyle(fontWeight: FontWeight.w900),
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
              'Bình luận',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
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
                child: Text('Không tải được bình luận.'),
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
                  'Chưa có bình luận nào.',
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
                      child: const Text('Xem tất cả bình luận'),
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
                  hintText: 'Viết bình luận...',
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
      return 'Firestore chưa cấp quyền bảnh luan quảng cáo.';
    }

    return 'Không gửi được bình luận.';
  }
}

class _CommentBubble extends StatelessWidget {
  const _CommentBubble({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final authorName = (data['authorName'] ?? 'Người dùng').toString();
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
          Text(authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(text),
        ],
      ),
    );
  }
}

class _RoomStatusBoard extends StatefulWidget {
  const _RoomStatusBoard({required this.buildingId, required this.viewModel});

  final String buildingId;
  final FeedViewModel viewModel;

  @override
  State<_RoomStatusBoard> createState() => _RoomStatusBoardState();

  static String _statusFromRoom(Map<String, dynamic> room) {
    final tenantId = (room['tenantId'] ?? '').toString();
    final tenantName = (room['tenantName'] ?? '').toString();
    if (tenantId.isNotEmpty || tenantName.isNotEmpty) return 'occupied';
    final status = (room['status'] ?? 'available').toString();
    if (status == 'occupied' ||
        status == 'maintenance' ||
        status == 'reserved') {
      return status;
    }
    return 'available';
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'occupied' => 'Đã thuê',
      'maintenance' => 'Bảo trì',
      'reserved' => 'Đã đặt',
      _ => 'Trống',
    };
  }

  static Color _statusColor(String status) {
    return switch (status) {
      'occupied' => AppColors.primary,
      'maintenance' => const Color(0xFFF59E0B),
      'reserved' => const Color(0xFFA855F7),
      _ => const Color(0xFF16A34A),
    };
  }
}

class _RoomStatusBoardState extends State<_RoomStatusBoard> {
  int? _selectedFloor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: widget.viewModel.buildingRooms(widget.buildingId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AdDetailSectionCard(
            icon: Icons.layers_outlined,
            title: 'Chọn tầng để xem phòng',
            child: LinearProgressIndicator(minHeight: 2),
          );
        }

        if (snapshot.hasError) {
          return const _AdDetailSectionCard(
            icon: Icons.layers_outlined,
            title: 'Chọn tầng để xem phòng',
            child: Text('Không tải được trạng thái phòng.'),
          );
        }

        final rooms = (snapshot.data?.docs ?? [])
            .map(_FeedRoomView.fromDoc)
            .toList()
          ..sort((left, right) {
            final floorCompare = left.floor.compareTo(right.floor);
            if (floorCompare != 0) return floorCompare;
            return left.number.compareTo(right.number);
          });

        if (rooms.isEmpty) {
          return const _AdDetailSectionCard(
            icon: Icons.layers_outlined,
            title: 'Chọn tầng để xem phòng',
            child: Text('Chưa có danh sách phòng.'),
          );
        }

        final floors = <int, List<_FeedRoomView>>{};
        for (final room in rooms) {
          floors.putIfAbsent(room.floor, () => []).add(room);
        }

        final floorNumbers = floors.keys.toList()..sort();
        final selectedFloor = floorNumbers.contains(_selectedFloor)
            ? _selectedFloor!
            : floorNumbers.first;
        final selectedRooms = floors[selectedFloor] ?? const <_FeedRoomView>[];

        return _AdDetailSectionCard(
          icon: Icons.layers_outlined,
          title: 'Chọn tầng để xem phòng',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (var index = 0; index < floorNumbers.length; index++) ...[
                      _FloorSelectorPill(
                        floor: floorNumbers[index],
                        rooms: floors[floorNumbers[index]] ?? const [],
                        selected: floorNumbers[index] == selectedFloor,
                        onTap: () {
                          setState(() {
                            _selectedFloor = floorNumbers[index];
                          });
                        },
                      ),
                      if (index != floorNumbers.length - 1)
                        const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SelectedFloorRoomPanel(
                floor: selectedFloor,
                rooms: selectedRooms,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FloorSelectorPill extends StatelessWidget {
  const _FloorSelectorPill({
    required this.floor,
    required this.rooms,
    required this.selected,
    required this.onTap,
  });

  final int floor;
  final List<_FeedRoomView> rooms;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final availableCount = rooms
        .where((room) => room.status == 'available')
        .length;
    final label = floor > 0 ? 'Tầng $floor' : 'Khác';
    final foreground = selected ? Colors.white : AppColors.textPrimary;
    final secondary = selected
        ? Colors.white.withValues(alpha: 0.78)
        : AppColors.textSecondary;

    return Material(
      color: selected ? AppColors.primary : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          width: 126,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.layers_outlined,
                    color: selected ? Colors.white : AppColors.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: foreground,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '${rooms.length} phòng',
                style: TextStyle(color: secondary, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                '$availableCount trống',
                style: TextStyle(
                  color: selected ? Colors.white : const Color(0xFF16A34A),
                  fontSize: 12,
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

class _SelectedFloorRoomPanel extends StatelessWidget {
  const _SelectedFloorRoomPanel({required this.floor, required this.rooms});

  final int floor;
  final List<_FeedRoomView> rooms;

  @override
  Widget build(BuildContext context) {
    final title = floor > 0 ? 'Phòng tầng $floor' : 'Phòng khác';
    final sortedRooms = [...rooms]
      ..sort((left, right) => left.number.compareTo(right.number));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const Spacer(),
              Text(
                '${sortedRooms.length} phòng',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedRooms.map((room) {
              return _InlineRoomChip(
                room: room,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => _RoomImagesScreen(room: room),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _InlineRoomChip extends StatelessWidget {
  const _InlineRoomChip({required this.room, required this.onTap});

  final _FeedRoomView room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = room.statusColor;
    final label = room.number > 0 ? '${room.number}' : room.name;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 7),
              Icon(
                room.imageUrls.isEmpty
                    ? Icons.image_not_supported_outlined
                    : Icons.photo_library_outlined,
                color: room.imageUrls.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.primary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
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
            message: 'Không tải được danh sách tài khoản.',
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
                ? 'Chưa có tài khoản quản lý phù hợp.'
                : 'Chưa có tài khoản người thuê phù hợp.',
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
    final normalizedQuery = _normalizeSearchText(query);
    if (normalizedQuery.isEmpty) return true;
    final haystack = [
      data['name'],
      data['email'],
      data['displayName'],
    ].map(_normalizeSearchText).join(' ');
    return haystack.contains(normalizedQuery);
  }

  static String _displayName(Map<String, dynamic> data) {
    final name = (data['name'] ?? data['displayName'] ?? '').toString().trim();
    if (name.isNotEmpty) return name;
    final email = (data['email'] ?? '').toString().trim();
    return email.isEmpty ? 'Tài khoản' : email;
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
            buildingId.isEmpty
                ? 'Chưa tham gia tòa nhà'
                : 'Đã tham gia tòa nhà',
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
    return email.isEmpty ? 'Tài khoản' : email;
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

class _FeedRoomView {
  const _FeedRoomView({
    required this.id,
    required this.name,
    required this.number,
    required this.floor,
    required this.status,
    required this.rent,
    required this.area,
    required this.imageUrls,
  });

  final String id;
  final String name;
  final int number;
  final int floor;
  final String status;
  final int rent;
  final int area;
  final List<String> imageUrls;

  String get statusLabel => _RoomStatusBoard._statusLabel(status);
  Color get statusColor => _RoomStatusBoard._statusColor(status);

  factory _FeedRoomView.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    final number = _readInt(data['roomNumber']);
    final name = _text(data['name'], number > 0 ? 'Phòng $number' : doc.id);
    return _FeedRoomView(
      id: doc.id,
      name: name,
      number: number,
      floor: _readInt(data['floor']),
      status: _RoomStatusBoard._statusFromRoom(data),
      rent: _readInt(data['rent']),
      area: _readInt(data['area']),
      imageUrls: _imageUrls(data),
    );
  }

  static int _readInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _text(Object? value, String fallback) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty ? fallback : text;
  }

  static List<String> _imageUrls(Map<String, dynamic> data) {
    final urls = <String>[];

    void add(Object? value) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && !urls.contains(text)) urls.add(text);
    }

    for (final key in ['coverImageUrl', 'imageUrl', 'thumbnailUrl']) {
      add(data[key]);
    }

    for (final key in ['images', 'imageUrls', 'roomImages', 'photoUrls']) {
      final value = data[key];
      if (value is Iterable) {
        for (final item in value) {
          add(item);
        }
      }
    }

    return urls;
  }
}

class _FloorSummaryCard extends StatelessWidget {
  const _FloorSummaryCard({
    required this.floor,
    required this.rooms,
    required this.onTap,
  });

  final int floor;
  final List<_FeedRoomView> rooms;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final availableCount = rooms
        .where((room) => room.status == 'available')
        .length;
    final label = floor > 0 ? 'Tầng $floor' : 'Chưa xếp tầng';

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.layers_outlined,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${rooms.length} phòng',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$availableCount',
                style: const TextStyle(
                  color: Color(0xFF16A34A),
                  fontSize: 12,
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

class _FloorRoomsScreen extends StatelessWidget {
  const _FloorRoomsScreen({
    required this.floor,
    required this.rooms,
  });

  final int floor;
  final List<_FeedRoomView> rooms;

  @override
  Widget build(BuildContext context) {
    final title = floor > 0 ? 'Tầng $floor' : 'Phòng chưa xếp tầng';
    final sortedRooms = [...rooms]
      ..sort((left, right) => left.number.compareTo(right.number));

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: sortedRooms.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width >= 560 ? 3 : 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.28,
        ),
        itemBuilder: (context, index) {
          final room = sortedRooms[index];
          return _FloorRoomTile(
            room: room,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _RoomImagesScreen(room: room),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _FloorRoomTile extends StatelessWidget {
  const _FloorRoomTile({
    required this.room,
    required this.onTap,
  });

  final _FeedRoomView room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = room.statusColor;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Text(
                      room.number > 0 ? '${room.number}' : '?',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    room.imageUrls.isEmpty
                        ? Icons.image_not_supported_outlined
                        : Icons.photo_library_outlined,
                    color: room.imageUrls.isEmpty
                        ? AppColors.textSecondary
                        : AppColors.primary,
                    size: 20,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                room.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                room.statusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                room.imageUrls.isEmpty
                    ? 'Chưa có ảnh'
                    : '${room.imageUrls.length} ảnh',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoomImagesScreen extends StatelessWidget {
  const _RoomImagesScreen({required this.room});

  final _FeedRoomView room;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(room.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _RoomGalleryHeader(room: room),
          const SizedBox(height: 16),
          if (room.imageUrls.isEmpty)
            const _RoomImageEmptyState()
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: room.imageUrls.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: MediaQuery.of(context).size.width >= 560
                    ? 3
                    : 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.86,
              ),
              itemBuilder: (context, index) {
                final url = room.imageUrls[index];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const _RoomImageFallback(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _RoomGalleryHeader extends StatelessWidget {
  const _RoomGalleryHeader({required this.room});

  final _FeedRoomView room;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: room.statusColor.withValues(alpha: 0.14),
              child: Icon(Icons.meeting_room_outlined, color: room.statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    room.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (room.floor > 0) 'Tầng ${room.floor}',
                      room.statusLabel,
                      if (room.area > 0) '${room.area} m2',
                      if (room.rent > 0) '${room.rent} VND/tháng',
                    ].join(' - '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary),
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

class _RoomImageEmptyState extends StatelessWidget {
  const _RoomImageEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            color: AppColors.primary,
            size: 44,
          ),
          SizedBox(height: 10),
          Text(
            'Phòng này chưa có ảnh tải lên.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RoomImageFallback extends StatelessWidget {
  const _RoomImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF6FF),
      child: const Center(
        child: Icon(Icons.broken_image_outlined, color: AppColors.primary),
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

class _FeedEmptyState extends StatelessWidget {
  const _FeedEmptyState({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 56),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
