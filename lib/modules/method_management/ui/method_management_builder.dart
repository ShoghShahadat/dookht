import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import '../../ui/rendering_system.dart';

/// A dedicated widget builder for the method management screen.
class MethodManagementBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    return _MethodManagementWidget(renderingSystem: rs);
  }
}

class _MethodManagementWidget extends StatelessWidget {
  final FlutterRenderingSystem renderingSystem;

  const _MethodManagementWidget({required this.renderingSystem});

  Color _getTextColor() {
    final rs = renderingSystem;
    final themeManagerId = rs.getAllIdsWithTag('theme_manager').firstOrNull;
    if (themeManagerId == null) return Colors.white;
    final themeComp = rs.get<ThemeComponent>(themeManagerId);
    return Color(themeComp?.properties['textColor'] as int? ?? 0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final textColor = _getTextColor();
    final allMethodIds = renderingSystem.getAllIdsWithTag('pattern_method');

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('مدیریت متدها', style: TextStyle(color: textColor)),
        backgroundColor: Colors.white.withOpacity(0.1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () =>
              renderingSystem.manager?.send(ShowCustomerListEvent()),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: allMethodIds.length,
        itemBuilder: (context, index) {
          final methodId = allMethodIds[index];
          // Use AnimatedBuilder to listen for changes on the method entity itself
          return AnimatedBuilder(
            animation: renderingSystem.getNotifier(methodId),
            builder: (context, _) {
              final method =
                  renderingSystem.get<PatternMethodComponent>(methodId);
              if (method == null) return const SizedBox.shrink();
              return _buildMethodCard(methodId, method, textColor);
            },
          );
        },
      ),
    );
  }

  Widget _buildMethodCard(
      EntityId methodId, PatternMethodComponent method, Color textColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    method.name,
                    style: TextStyle(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: textColor.withOpacity(0.8)),
                    onPressed: () {
                      renderingSystem.manager
                          ?.send(ShowEditMethodEvent(methodId));
                    },
                    tooltip: 'ویرایش متد',
                  )
                ],
              ),
              const Divider(color: Colors.white30, height: 20, thickness: 0.5),
              _buildDetailSection(
                  'متغیرها:',
                  method.variables.map((v) => '${v.label} (${v.key})').toList(),
                  textColor),
              const SizedBox(height: 12),
              _buildDetailSection(
                  'فرمول‌ها:',
                  method.formulas
                      .map((f) => '${f.label}: ${f.expression}')
                      .toList(),
                  textColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailSection(
      String title, List<String> items, Color textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: textColor, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0, right: 8.0),
              child: Text(
                '• $item',
                style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 14,
                    height: 1.5),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.left,
              ),
            )),
      ],
    );
  }
}
