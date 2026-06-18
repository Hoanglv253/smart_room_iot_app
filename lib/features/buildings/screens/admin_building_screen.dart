import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/services/app_firestore_service.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../settings/screens/admin_ad_settings_screen.dart';
import '../view_models/admin_building_view_model.dart';
import '../widgets/building_dashboard_widgets.dart';
import 'admin_invoice_management_screen.dart';
import 'admin_room_management_screen.dart';

class AdminBuildingScreen extends StatefulWidget {
  const AdminBuildingScreen({
    required this.user,
    required this.onOpenUserManagement,
    super.key,
  });

  final User user;
  final void Function(String buildingId, String buildingName)
      onOpenUserManagement;

  @override
  State<AdminBuildingScreen> createState() => _AdminBuildingScreenState();
}

class _AdminBuildingScreenState extends State<AdminBuildingScreen> {
  final _viewModel = AdminBuildingViewModel();

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _viewModel.adminBuilding(widget.user.uid),
      builder: (context, snapshot) {
        final buildingDoc = snapshot.data?.docs.isNotEmpty == true
            ? snapshot.data!.docs.first
            : null;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (buildingDoc == null) {
          return const _NoBuildingView();
        }

        final buildingId = buildingDoc.id;
        final building = buildingDoc.data();

        return _AdminBuildingDashboard(
          user: widget.user,
          buildingId: buildingId,
          building: building,
          viewModel: _viewModel,
          onOpenUserManagement: widget.onOpenUserManagement,
        );
      },
    );
  }
}

class _NoBuildingView extends StatelessWidget {
  const _NoBuildingView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Bạn chưa thiết lập tòa nhà. Hãy vào tab Cài đặt để tạo thông tin tòa nhà.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _AdminBuildingDashboard extends StatelessWidget {
  const _AdminBuildingDashboard({
    required this.user,
    required this.buildingId,
    required this.building,
    required this.viewModel,
    required this.onOpenUserManagement,
  });

  final User user;
  final String buildingId;
  final Map<String, dynamic> building;
  final AdminBuildingViewModel viewModel;
  final void Function(String buildingId, String buildingName)
      onOpenUserManagement;

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
                return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: viewModel.pendingJoinRequests(buildingId),
                  builder: (context, requestSnapshot) {
                    final members = memberSnapshot.data?.docs ?? [];
                    final requests = requestSnapshot.data?.docs ?? [];
                    final pendingRequestCount = requests.length;

                    return BuildingDashboardContent(
                      building: building,
                      rooms: roomSnapshot.data?.docs ?? [],
                      tenantCount: viewModel.tenantCount(members),
                      pendingRequestCount: pendingRequestCount,
                      pendingInvoiceCount:
                          _pendingInvoiceCount(invoiceSnapshot.data?.docs ?? []),
                      actions: _actions(context),
                      footer: pendingRequestCount == 0
                          ? null
                          : _JoinRequestBoard(
                              buildingId: buildingId,
                              adminId: user.uid,
                              viewModel: viewModel,
                            ),
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

  List<BuildingDashboardAction> _actions(BuildContext context) {
    return [
      BuildingDashboardAction(
        icon: Icons.meeting_room_outlined,
        label: 'Phòng',
        subtitle: 'Số do và trạng thái',
        onTap: () => _openRooms(context),
      ),
      BuildingDashboardAction(
        icon: Icons.people_outline,
        label: 'Người thuê',
        subtitle: 'Thành viên tòa nhà',
        color: const Color(0xFF16A34A),
        onTap: () {
          onOpenUserManagement(
            buildingId,
            (building['name'] ?? 'tòa nhà').toString(),
          );
        },
      ),
      BuildingDashboardAction(
        icon: Icons.receipt_long_outlined,
        label: 'Hóa đơn',
        subtitle: 'Thu tiền hàng tháng',
        color: const Color(0xFFF59E0B),
        onTap: () => _openInvoices(context),
      ),
      BuildingDashboardAction(
        icon: Icons.notifications_active_outlined,
        label: 'Thông báo',
        subtitle: 'Gửi tin cho tòa nhà',
        color: const Color(0xFF7C3AED),
        onTap: () => _openNotifications(context),
      ),
      BuildingDashboardAction(
        icon: Icons.campaign_outlined,
        label: 'Quảng cáo',
        subtitle: 'Đang lên Trang chủ',
        color: const Color(0xFF0EA5E9),
        onTap: () => _openAds(context),
      ),
    ];
  }

  void _openRooms(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminRoomManagementScreen(
          buildingId: buildingId,
          building: building,
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
        ),
      ),
    );
  }

  void _openNotifications(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationsScreen(
          user: user,
          role: UserRole.admin,
          buildingId: buildingId,
          buildingName: (building['name'] ?? 'Tòa nhà').toString(),
        ),
      ),
    );
  }

  void _openAds(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminAdSettingsScreen(
          user: user,
          buildingId: buildingId,
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

class _JoinRequestBoard extends StatelessWidget {
  const _JoinRequestBoard({
    required this.buildingId,
    required this.adminId,
    required this.viewModel,
  });

  final String buildingId;
  final String adminId;
  final AdminBuildingViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_outlined),
                const SizedBox(width: 8),
                Text(
                  'Yêu cầu tham gia',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: viewModel.pendingJoinRequests(buildingId),
              builder: (context, snapshot) {
                final requests = snapshot.data?.docs ?? [];
                if (requests.isEmpty) {
                  return const Text('Chưa có yêu cầu tham gia nào.');
                }

                return Column(
                  children: requests.map((doc) {
                    final data = doc.data();
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const CircleAvatar(
                        backgroundColor: Color(0xFFEFF6FF),
                        child: Icon(Icons.person_add_alt_1_outlined),
                      ),
                      title: Text(
                        (data['requesterName'] ?? 'Người dùng').toString(),
                      ),
                      subtitle: Text(
                        'Muốn tham gia với vai trò ${UserRole.label((data['requesterRole'] ?? UserRole.user).toString())}',
                      ),
                      trailing: Wrap(
                        children: [
                          IconButton(
                            tooltip: 'Duyet',
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approve(context, doc.id, data),
                          ),
                          IconButton(
                            tooltip: 'Từ choi',
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => _reject(context, doc.id),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _approve(
    BuildContext context,
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final result = await viewModel.approveJoinRequest(
      requestId: requestId,
      buildingId: buildingId,
      adminId: adminId,
      requestData: data,
    );
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_approvalMessage(result))),
    );
  }

  Future<void> _reject(BuildContext context, String requestId) async {
    final rejected = await viewModel.rejectJoinRequest(requestId);
    if (!context.mounted) return;

    if (!rejected) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_rejectErrorMessage())),
      );
    }
  }

  String _approvalMessage(JoinRequestApprovalResult result) {
    if (result == JoinRequestApprovalResult.approved) {
      return 'Đã duyệt yêu cầu tham gia.';
    }

    if (result == JoinRequestApprovalResult.approvedWithoutGroupChat) {
      if (viewModel.errorMessage?.contains('permission-denied') == true) {
        return 'Đã duyệt, nhưng Firestore chưa cấp quyền thêm vào nhóm chat.';
      }

      return 'Đã duyệt, nhưng chưa thêm được vào nhóm chat.';
    }

    if (viewModel.errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chưa cấp quyền duyệt yêu cầu tham gia.';
    }

    return 'Không duyệt được yêu cầu.';
  }

  String _rejectErrorMessage() {
    if (viewModel.errorMessage?.contains('permission-denied') == true) {
      return 'Firestore chưa cấp quyền từ chối yêu cầu tham gia.';
    }

    return 'Không từ choi được yêu cầu.';
  }
}
