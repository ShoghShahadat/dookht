import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import '../../ui/rendering_system.dart';
import '../customer_events.dart';

/// A dedicated and self-contained widget builder for the "Add Customer" form.
class AddCustomerFormBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    return _AddCustomerFormWidget(renderingSystem: rs);
  }
}

class _AddCustomerFormWidget extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  const _AddCustomerFormWidget({required this.renderingSystem});
  @override
  State<_AddCustomerFormWidget> createState() => _AddCustomerFormWidgetState();
}

class _AddCustomerFormWidgetState extends State<_AddCustomerFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      widget.renderingSystem.manager?.send(AddCustomerEvent(
        firstName: _firstNameController.text,
        lastName: _lastNameController.text,
        phone: _phoneController.text,
      ));
      widget.renderingSystem.manager?.send(ShowCustomerListEvent());
    }
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
    final textColor = _getTextColor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('افزودن مشتری جدید', style: TextStyle(color: textColor)),
        backgroundColor: Colors.white.withOpacity(0.1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            widget.renderingSystem.manager?.send(ShowCustomerListEvent());
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(_firstNameController, 'نام', textColor),
                      const SizedBox(height: 16),
                      _buildTextField(
                          _lastNameController, 'نام خانوادگی', textColor),
                      const SizedBox(height: 16),
                      _buildTextField(_phoneController, 'شماره تماس', textColor,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text('ذخیره مشتری'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, Color textColor,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: textColor),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'لطفاً $label را وارد کنید';
        }
        return null;
      },
    );
  }
}
