import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../view_models/manager_building_view_model.dart';
import '../widgets/building_dashboard_widgets.dart';
import 'admin_invoice_management_screen.dart';
import 'admin_room_management_screen.dart';
import 'admin_user_management_screen.dart';

class ManagerBuildingScreen extends StatefulWidget {
  const ManagerBuildingScreen({required this.user, super.key});

  final User user;

  @override
  State<ManagerBuildingScreen> createState() => _ManagerBuildingScreenState();
}

class _ManagerBuildingScreenState extends State<ManagerBuildingScreen> {
  final _viewModel = ManagerBuildingViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _viewModel.userProfile(widget.user.uid),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final profile = userSnapshot.data?.data() ?? {};
        final buildingId = (profile['buildingId'] ?? '').toString();
        if (buildingId.isEmpty) {
          return const SizedBox.shrink();
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _viewModel.building(buildingId),
          builder: (context, buildingSnapshot) {
            if (buildingSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (buildingSnapshot.hasError ||
                buildingSnapshot.data?.exists != true) {
              return const SizedBox.shrink();
            }

            final building = buildingSnapshot.data!.data() ?? {};
            return _ManagerBuildingDashboard(
              user: widget.user,
              buildingId: buildingId,
              building: building,
              viewModel: _viewModel,
            );
          },
        );
      },
    );
  }
}

class _ManagerBuildingDashboard extends StatelessWidget {
  const _ManagerBuildingDashboard({
    required this.user,
    required this.buildingId,
    required this.building,
    required this.viewModel,
  });

  final User user;
  final String buildingId;
  final Map<String, dynamic> building;
  final ManagerBuildingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: viewModel.rooms(buildingId),
      builder: (context, roomSnapshot) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: viewModel.members(buildingId),
          builder: (context, memberSnapshot) {
            return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: viewModel.invoices(buildingId),
              builder: (context, invoiceSnapshot) {
                final members = memberSnapshot.data?.docs ?? [];
                return BuildingDashboardContent(
                  building: building,
                  rooms: roomSnapshot.data?.docs ?? [],
                  tenantCount: viewModel.tenantCount(members),
                  pendingRequestCount: 0,
                  pendingInvoiceCount:
                      _pendingInvoiceCount(invoiceSnapshot.data?.docs ?? []),
                  actions: _actions(context),
                );
              },
            );
          },
        );
      },
    );
  }

  List<BuildingDashboardAction> _actions(BuildContext context) {
    return [
      BuildingDashboardAction(
        icon: Icons.meeting_room_outlined,
        label: 'Phòng',
        subtitle: 'Xem số do và trạng thái',
        onTap: () => _openRooms(context),
      ),
      BuildingDashboardAction(
        icon: Icons.people_outline,
        label: 'Người thuê',
        subtitle: 'Danh sách thành viên',
        color: const Color(0xFF16A34A),
        onTap: () => _openUsers(context),
      ),
      BuildingDashboardAction(
        icon: Icons.receipt_long_outlined,
        label: 'Hóa đơn',
        subtitle: 'Theo dõi thanh toán',
        color: const Color(0xFFF59E0B),
        onTap: () => _openInvoices(context),
      ),
      BuildingDashboardAction(
        icon: Icons.notifications_active_outlined,
        label: 'Thông báo',
        subtitle: 'Gửi và theo dõi',
        color: const Color(0xFF7C3AED),
        onTap: () => _openNotifications(context),
      ),
    ];
  }

  void _openRooms(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminRoomManagementScreen(
          buildingId: buildingId,
          building: building,
          canEditRoom: false,
          canManageTenant: false,
        ),
      ),
    );
  }

  void _openUsers(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminUserManagementScreen(
          buildingId: buildingId,
          buildingName: (building['name'] ?? 'tòa nhà').toString(),
        ),
      ),
    );
  }

  void _openInvoices(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminInvoiceManagementScreen(
          buildingId: buildingId,
          building: building,
          canCreate: false,
          canConfirmPayment: false,
        ),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          user: user,
          role: UserRole.manager,
          buildingId: buildingId,
          buildingName: (building['name'] ?? 'Tòa nhà').toString(),
        ),
      ),
    );
  }

  static int _pendingInvoiceCount(
    Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> invoices,
  ) {
    return invoices.where((doc) {
      final status = (doc.data()['status'] ?? InvoiceStatus.unpaid).toString();
      return status == InvoiceStatus.pending;
    }).length;
  }
}
