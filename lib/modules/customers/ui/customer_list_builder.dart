// FILE: lib/modules/customers/ui/customer_list_builder.dart
// (English comments for code clarity)

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import '../../ui/rendering_system.dart';
import '../components/customer_component.dart';
import '../customer_events.dart';

/// A dedicated and self-contained widget builder for the customer list screen.
class CustomerListBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    return AnimatedBuilder(
      animation: rs.getNotifier(entityId),
      builder: (context, _) {
        final childrenComp = rs.get<ChildrenComponent>(entityId);
        final customerIds = childrenComp?.children ?? [];
        final addCustomerButtonId =
            rs.getAllIdsWithTag('add_customer_button').firstOrNull;
        final settingsButtonId =
            rs.getAllIdsWithTag('method_management_button').firstOrNull;
        final themeManagerId = rs.getAllIdsWithTag('theme_manager').firstOrNull;
        final textColor = _getTextColor(rs, themeManagerId);

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: Text('مشتریان', style: TextStyle(color: textColor)),
            backgroundColor: Colors.white.withOpacity(0.1),
            elevation: 0,
            centerTitle: true,
            actions: [
              if (settingsButtonId != null)
                IconButton(
                  icon: Icon(Icons.settings_outlined, color: textColor),
                  onPressed: () =>
                      rs.manager?.send(EntityTapEvent(settingsButtonId)),
                  tooltip: 'مدیریت متدها',
                ),
            ],
          ),
          body: customerIds.isEmpty
              ? _buildEmptyState(context, textColor)
              : _buildCustomerList(context, rs, customerIds, textColor),
          floatingActionButton: addCustomerButtonId != null
              ? _buildFab(context, rs, addCustomerButtonId)
              : null,
        );
      },
    );
  }

  Color _getTextColor(FlutterRenderingSystem rs, EntityId? themeManagerId) {
    if (themeManagerId == null) return Colors.white;
    final themeComp = rs.get<ThemeComponent>(themeManagerId);
    return Color(themeComp?.properties['textColor'] as int? ?? 0xFFFFFFFF);
  }

  Widget _buildEmptyState(BuildContext context, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline,
              color: textColor.withOpacity(0.7), size: 80),
          const SizedBox(height: 16),
          Text(
            'هیچ مشتری ثبت نشده است',
            style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'برای شروع، یک مشتری جدید اضافه کنید',
            style: TextStyle(color: textColor.withOpacity(0.5), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerList(BuildContext context, FlutterRenderingSystem rs,
      List<EntityId> ids, Color textColor) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: ids.length,
      itemBuilder: (context, index) {
        final customerId = ids[index];
        return AnimatedBuilder(
          animation: rs.getNotifier(customerId),
          builder: (context, _) {
            final customer = rs.get<CustomerComponent>(customerId);
            if (customer == null) return const SizedBox.shrink();
            return _buildCustomerCard(
                context, rs, customerId, customer, textColor);
          },
        );
      },
    );
  }

  Widget _buildCustomerCard(BuildContext context, FlutterRenderingSystem rs,
      EntityId customerId, CustomerComponent customer, Color textColor) {
    return GestureDetector(
      onTap: () {
        rs.manager?.send(ShowCalculationPageEvent(customerId));
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Text(
                    customer.firstName.isNotEmpty
                        ? customer.firstName[0].toUpperCase()
                        : '',
                    style: TextStyle(
                        color: textColor, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${customer.firstName} ${customer.lastName}',
                        style: TextStyle(
                            color: textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        customer.phone,
                        style: TextStyle(
                            color: textColor.withOpacity(0.7), fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios,
                    color: textColor.withOpacity(0.5), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFab(
      BuildContext context, FlutterRenderingSystem rs, EntityId buttonId) {
    return FloatingActionButton(
      onPressed: () {
        rs.manager?.send(EntityTapEvent(buttonId));
      },
      backgroundColor: Colors.white.withOpacity(0.9),
      child: const Icon(Icons.add, color: Colors.black87),
      tooltip: 'افزودن مشتری جدید',
    );
  }
}
