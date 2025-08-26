import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import '../../customers/components/customer_component.dart';
import '../../customers/customer_events.dart';
import '../../ui/rendering_system.dart';
import '../../ui/view_manager/view_manager_component.dart';

/// A dedicated, self-contained widget builder for the pattern calculation screen.
class CalculationPageBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    final viewManagerId = rs.getAllIdsWithTag('view_manager').firstOrNull;
    if (viewManagerId == null) {
      return const Center(child: Text("View manager not found!"));
    }

    // This builder needs the active customer ID from the ViewStateComponent.
    final viewState = rs.get<ViewStateComponent>(viewManagerId);
    final activeCustomerId = viewState?.activeCustomerId;

    if (activeCustomerId == null) {
      return const Center(child: Text("No active customer selected!"));
    }

    return _CalculationPageWidget(
      renderingSystem: rs,
      customerId: activeCustomerId,
    );
  }
}

class _CalculationPageWidget extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId customerId;

  const _CalculationPageWidget(
      {required this.renderingSystem, required this.customerId});

  @override
  State<_CalculationPageWidget> createState() => _CalculationPageWidgetState();
}

class _CalculationPageWidgetState extends State<_CalculationPageWidget> {
  // Controllers for all measurement fields
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    // Initialize controllers for all fields
    _controllers['bustCircumference'] = TextEditingController();
    _controllers['waistCircumference'] = TextEditingController();
    _controllers['hipCircumference'] = TextEditingController();
    _controllers['frontInterscye'] = TextEditingController();
    _controllers['backInterscye'] = TextEditingController();
    _controllers['sleeveLength'] = TextEditingController();
    _controllers['armCircumference'] = TextEditingController();
    _controllers['wristCircumference'] = TextEditingController();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Color _getTextColor() {
    final rs = widget.renderingSystem;
    final themeManagerId = rs.getAllIdsWithTag('theme_manager').firstOrNull;
    if (themeManagerId == null) return Colors.white;
    final themeComp = rs.get<ThemeComponent>(themeManagerId);
    return Color(themeComp?.properties['textColor'] as int? ?? 0xFFFFFFFF);
  }

  @override
  Widget build(BuildContext context) {
    final rs = widget.renderingSystem;
    final customer = rs.get<CustomerComponent>(widget.customerId);
    final customerName = customer != null
        ? '${customer.firstName} ${customer.lastName}'
        : 'مشتری';
    final textColor = _getTextColor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('محاسبات برای $customerName',
            style: TextStyle(color: textColor)),
        backgroundColor: Colors.white.withOpacity(0.1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            rs.manager?.send(ShowCustomerListEvent());
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildSection('اندازه‌های اصلی', textColor, [
              _buildTextField('bustCircumference', 'دور سینه', textColor),
              _buildTextField('waistCircumference', 'دور کمر', textColor),
              _buildTextField('hipCircumference', 'دور باسن', textColor),
            ]),
            const SizedBox(height: 20),
            _buildSection('اندازه‌های عرضی', textColor, [
              _buildTextField('frontInterscye', 'کارور جلو', textColor),
              _buildTextField('backInterscye', 'کارور پشت', textColor),
            ]),
            const SizedBox(height: 20),
            _buildSection('اندازه‌های آستین', textColor, [
              _buildTextField('sleeveLength', 'قد آستین', textColor),
              _buildTextField('armCircumference', 'دور بازو', textColor),
              _buildTextField('wristCircumference', 'دور مچ', textColor),
            ]),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Calculation logic will be triggered here in the future
              },
              icon: const Icon(Icons.calculate),
              label: const Text('محاسبه کن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildSection('نتایج الگو', textColor, [
              // Results will be displayed here
              const ListTile(
                title: Text('نتایج در اینجا نمایش داده خواهند شد',
                    style: TextStyle(color: Colors.white70)),
              )
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Color textColor, List<Widget> children) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const Divider(color: Colors.white30, height: 20),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String key, String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _controllers[key],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          suffixText: 'cm',
          suffixStyle: TextStyle(color: textColor.withOpacity(0.5)),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: textColor.withOpacity(0.3)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: textColor),
          ),
        ),
      ),
    );
  }
}
