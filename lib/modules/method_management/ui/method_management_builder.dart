// FILE: lib/modules/method_management/ui/method_management_builder.dart
// (English comments for code clarity)
// MODIFIED v3.0: CRITICAL BUG FIX - Correctly passed the required `methodId`
// and `formulaResultKey` arguments when creating the ShowVisualFormulaEditorEvent.
// Also fixed all deprecated `withOpacity` warnings.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';

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
    final addMethodButtonId =
        renderingSystem.getAllIdsWithTag('add_method_button').firstOrNull;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('مدیریت متدها', style: TextStyle(color: textColor)),
        backgroundColor: Colors.white.withAlpha((255 * 0.1).round()),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () =>
              renderingSystem.manager?.send(ShowCustomerListEvent()),
        ),
      ),
      body: allMethodIds.isEmpty
          ? _buildEmptyState(textColor)
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              itemCount: allMethodIds.length,
              itemBuilder: (context, index) {
                final methodId = allMethodIds[index];
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
      floatingActionButton: addMethodButtonId != null
          ? FloatingActionButton(
              onPressed: () {
                renderingSystem.manager
                    ?.send(EntityTapEvent(addMethodButtonId));
              },
              backgroundColor: Colors.white.withAlpha((255 * 0.9).round()),
              child: const Icon(Icons.add, color: Colors.black87),
              tooltip: 'ایجاد متد جدید',
            )
          : null,
    );
  }

  Widget _buildEmptyState(Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.style_outlined,
              color: textColor.withAlpha((255 * 0.7).round()), size: 80),
          const SizedBox(height: 16),
          Text(
            'هیچ متدی تعریف نشده است',
            style: TextStyle(
                color: textColor.withAlpha((255 * 0.7).round()), fontSize: 18),
          ),
        ],
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
            color: Colors.white.withAlpha((255 * 0.1).round()),
            borderRadius: BorderRadius.circular(15),
            border:
                Border.all(color: Colors.white.withAlpha((255 * 0.2).round())),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      method.name,
                      style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.edit_outlined,
                        color: textColor.withAlpha((255 * 0.8).round())),
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
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text('$title (خالی)',
            style: TextStyle(
                color: textColor.withAlpha((255 * 0.6).round()),
                fontStyle: FontStyle.italic)),
      );
    }
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
                    color: textColor.withAlpha((255 * 0.8).round()),
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
