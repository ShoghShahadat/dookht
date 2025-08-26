import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';
import '../../ui/rendering_system.dart';

class EditMethodBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    final viewManagerId = rs.getAllIdsWithTag('view_manager').firstOrNull;
    if (viewManagerId == null) return const SizedBox.shrink();

    final viewState = rs.get<ViewStateComponent>(viewManagerId);
    final activeMethodId = viewState?.activeMethodId;
    if (activeMethodId == null) {
      return const Center(child: Text('No method selected for editing.'));
    }

    return _EditMethodWidget(
      renderingSystem: rs,
      methodId: activeMethodId,
    );
  }
}

class _EditMethodWidget extends StatefulWidget {
  final FlutterRenderingSystem renderingSystem;
  final EntityId methodId;

  const _EditMethodWidget(
      {required this.renderingSystem, required this.methodId});

  @override
  State<_EditMethodWidget> createState() => _EditMethodWidgetState();
}

class _EditMethodWidgetState extends State<_EditMethodWidget> {
  late TextEditingController _nameController;
  late List<TextEditingController> _varLabelControllers;
  late List<TextEditingController> _formulaLabelControllers;
  late List<TextEditingController> _formulaExpressionControllers;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final method =
        widget.renderingSystem.get<PatternMethodComponent>(widget.methodId);
    if (method == null) return;

    _nameController = TextEditingController(text: method.name);
    _varLabelControllers = method.variables
        .map((v) => TextEditingController(text: v.label))
        .toList();
    _formulaLabelControllers = method.formulas
        .map((f) => TextEditingController(text: f.label))
        .toList();
    _formulaExpressionControllers = method.formulas
        .map((f) => TextEditingController(text: f.expression))
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _varLabelControllers.forEach((c) => c.dispose());
    _formulaLabelControllers.forEach((c) => c.dispose());
    _formulaExpressionControllers.forEach((c) => c.dispose());
    super.dispose();
  }

  void _saveChanges() {
    final originalMethod =
        widget.renderingSystem.get<PatternMethodComponent>(widget.methodId);
    if (originalMethod == null) return;

    final updatedVariables = <DynamicVariable>[];
    for (int i = 0; i < originalMethod.variables.length; i++) {
      updatedVariables.add(DynamicVariable(
        key: originalMethod.variables[i].key, // Key is immutable for now
        label: _varLabelControllers[i].text,
        defaultValue: originalMethod.variables[i].defaultValue,
      ));
    }

    final updatedFormulas = <Formula>[];
    for (int i = 0; i < originalMethod.formulas.length; i++) {
      updatedFormulas.add(Formula(
        resultKey: originalMethod.formulas[i].resultKey, // Key is immutable
        label: _formulaLabelControllers[i].text,
        expression: _formulaExpressionControllers[i].text,
      ));
    }

    widget.renderingSystem.manager?.send(UpdatePatternMethodEvent(
      methodId: widget.methodId,
      newName: _nameController.text,
      newVariables: updatedVariables,
      newFormulas: updatedFormulas,
    ));

    // Navigate back to the management list
    widget.renderingSystem.manager?.send(ShowMethodManagementEvent());
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
    final method =
        widget.renderingSystem.get<PatternMethodComponent>(widget.methodId);
    if (method == null) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: Text('Method not found!')),
      );
    }
    final textColor = _getTextColor();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title:
            Text('ویرایش: ${method.name}', style: TextStyle(color: textColor)),
        backgroundColor: Colors.white.withOpacity(0.1),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () =>
              widget.renderingSystem.manager?.send(ShowMethodManagementEvent()),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: textColor),
            onPressed: _saveChanges,
            tooltip: 'ذخیره تغییرات',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSection('اطلاعات کلی', textColor, [
              _buildTextField(_nameController, 'نام متد', textColor),
            ]),
            const SizedBox(height: 20),
            _buildSection(
                'متغیرها', textColor, _buildVariableEditors(method, textColor)),
            const SizedBox(height: 20),
            _buildSection(
                'فرمول‌ها', textColor, _buildFormulaEditors(method, textColor)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVariableEditors(
      PatternMethodComponent method, Color textColor) {
    return List.generate(method.variables.length, (index) {
      return _buildTextField(_varLabelControllers[index],
          'برچسب متغیر: ${method.variables[index].key}', textColor);
    });
  }

  List<Widget> _buildFormulaEditors(
      PatternMethodComponent method, Color textColor) {
    return List.generate(method.formulas.length, (index) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField(_formulaLabelControllers[index],
              'برچسب نتیجه: ${method.formulas[index].resultKey}', textColor),
          const SizedBox(height: 8),
          _buildTextField(
              _formulaExpressionControllers[index], 'عبارت فرمول', textColor,
              isExpression: true),
          if (index < method.formulas.length - 1)
            const Divider(color: Colors.white24, height: 24),
        ],
      );
    });
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
              const Divider(color: Colors.white30, height: 20, thickness: 0.5),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, Color textColor,
      {bool isExpression = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
            color: textColor, fontFamily: isExpression ? 'monospace' : null),
        textDirection: isExpression ? TextDirection.ltr : TextDirection.rtl,
        textAlign: isExpression ? TextAlign.left : TextAlign.right,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: textColor.withOpacity(0.3))),
          focusedBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: textColor)),
        ),
      ),
    );
  }
}
