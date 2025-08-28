// FILE: lib/modules/method_management/ui/edit_method_builder.dart
// (English comments for code clarity)
// MODIFIED v2.0: Added an icon button next to each formula field to open
// the visual editor for that specific formula.

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/customers/customer_events.dart';
import 'package:tailor_assistant/modules/method_management/method_management_events.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import 'package:tailor_assistant/modules/ui/view_manager/view_manager_component.dart';

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
  late List<Formula> _formulas;
  late List<TextEditingController> _formulaLabelControllers;
  late List<TextEditingController> _formulaExpressionControllers;
  late List<TextEditingController> _formulaResultKeyControllers;
  late List<DynamicVariable> _variables;
  late List<TextEditingController> _varLabelControllers;
  late List<TextEditingController> _varKeyControllers;
  late List<TextEditingController> _varDefaultValueControllers;

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
    _variables = List.from(method.variables);
    _varLabelControllers =
        _variables.map((v) => TextEditingController(text: v.label)).toList();
    _varKeyControllers =
        _variables.map((v) => TextEditingController(text: v.key)).toList();
    _varDefaultValueControllers = _variables
        .map((v) => TextEditingController(text: v.defaultValue.toString()))
        .toList();
    _formulas = List.from(method.formulas);
    _formulaLabelControllers =
        _formulas.map((f) => TextEditingController(text: f.label)).toList();
    _formulaExpressionControllers = _formulas
        .map((f) => TextEditingController(text: f.expression))
        .toList();
    _formulaResultKeyControllers =
        _formulas.map((f) => TextEditingController(text: f.resultKey)).toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _varLabelControllers.forEach((c) => c.dispose());
    _varKeyControllers.forEach((c) => c.dispose());
    _varDefaultValueControllers.forEach((c) => c.dispose());
    _formulaLabelControllers.forEach((c) => c.dispose());
    _formulaExpressionControllers.forEach((c) => c.dispose());
    _formulaResultKeyControllers.forEach((c) => c.dispose());
    super.dispose();
  }

  void _addVariable() {
    setState(() {
      final newKey = 'newVar${_variables.length + 1}';
      _variables.add(
          DynamicVariable(key: newKey, label: 'متغیر جدید', defaultValue: 0.0));
      _varLabelControllers.add(TextEditingController(text: 'متغیر جدید'));
      _varKeyControllers.add(TextEditingController(text: newKey));
      _varDefaultValueControllers.add(TextEditingController(text: '0.0'));
    });
  }

  void _deleteVariable(int index) {
    setState(() {
      _variables.removeAt(index);
      _varLabelControllers[index].dispose();
      _varLabelControllers.removeAt(index);
      _varKeyControllers[index].dispose();
      _varKeyControllers.removeAt(index);
      _varDefaultValueControllers[index].dispose();
      _varDefaultValueControllers.removeAt(index);
    });
  }

  void _addFormula() {
    setState(() {
      final newKey = 'newResult${_formulas.length + 1}';
      _formulas
          .add(Formula(resultKey: newKey, expression: '', label: 'نتیجه جدید'));
      _formulaLabelControllers.add(TextEditingController(text: 'نتیجه جدید'));
      _formulaExpressionControllers.add(TextEditingController());
      _formulaResultKeyControllers.add(TextEditingController(text: newKey));
    });
  }

  void _deleteFormula(int index) {
    setState(() {
      _formulas.removeAt(index);
      _formulaLabelControllers[index].dispose();
      _formulaLabelControllers.removeAt(index);
      _formulaExpressionControllers[index].dispose();
      _formulaExpressionControllers.removeAt(index);
      _formulaResultKeyControllers[index].dispose();
      _formulaResultKeyControllers.removeAt(index);
    });
  }

  void _saveChanges() {
    final updatedVariables = <DynamicVariable>[];
    for (int i = 0; i < _variables.length; i++) {
      updatedVariables.add(DynamicVariable(
        key: _varKeyControllers[i].text,
        label: _varLabelControllers[i].text,
        defaultValue:
            double.tryParse(_varDefaultValueControllers[i].text) ?? 0.0,
      ));
    }

    final updatedFormulas = <Formula>[];
    for (int i = 0; i < _formulas.length; i++) {
      // Preserve existing visual graph data when saving
      final existingFormula = _formulas[i];
      updatedFormulas.add(Formula(
        resultKey: _formulaResultKeyControllers[i].text,
        label: _formulaLabelControllers[i].text,
        expression: _formulaExpressionControllers[i].text,
        visualGraphData: existingFormula.visualGraphData,
      ));
    }

    widget.renderingSystem.manager?.send(UpdatePatternMethodEvent(
      methodId: widget.methodId,
      newName: _nameController.text,
      newVariables: updatedVariables,
      newFormulas: updatedFormulas,
    ));

    widget.renderingSystem.manager?.send(ShowMethodManagementEvent());
  }

  Future<void> _showDeleteConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.grey[800]?.withOpacity(0.8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title:
                const Text('تایید حذف', style: TextStyle(color: Colors.white)),
            content: const Text(
                'آیا از حذف این متد اطمینان دارید؟ این عمل غیرقابل بازگشت است.',
                style: TextStyle(color: Colors.white70)),
            actions: <Widget>[
              TextButton(
                child: const Text('انصراف',
                    style: TextStyle(color: Colors.white70)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('حذف کن',
                    style: TextStyle(color: Colors.redAccent)),
                onPressed: () {
                  widget.renderingSystem.manager
                      ?.send(DeletePatternMethodEvent(widget.methodId));
                  Navigator.of(context).pop();
                  widget.renderingSystem.manager
                      ?.send(ShowMethodManagementEvent());
                },
              ),
            ],
          ),
        );
      },
    );
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
          body: Center(child: Text('Method not found!')));
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
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _showDeleteConfirmationDialog,
            tooltip: 'حذف متد',
          ),
          IconButton(
            icon: Icon(Icons.save, color: textColor),
            onPressed: _saveChanges,
            tooltip: 'ذخیره تغییرات',
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        child: Column(
          children: [
            _buildSection('اطلاعات کلی', textColor, [
              _buildTextField(_nameController, 'نام متد', textColor),
            ]),
            const SizedBox(height: 20),
            _buildSection(
                'متغیرها', textColor, _buildVariableEditors(textColor)),
            const SizedBox(height: 20),
            _buildSection(
                'فرمول‌ها', textColor, _buildFormulaEditors(textColor)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildVariableEditors(Color textColor) {
    List<Widget> variableWidgets = List.generate(_variables.length, (index) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildTextField(
                      _varLabelControllers[index], 'برچسب متغیر', textColor)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteVariable(index),
              )
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(_varKeyControllers[index],
              'کلید متغیر (انگلیسی، بدون فاصله)', textColor,
              isExpression: true),
          const SizedBox(height: 8),
          _buildTextField(
              _varDefaultValueControllers[index], 'مقدار پیش‌فرض', textColor,
              isExpression: true),
          if (index < _variables.length - 1)
            const Divider(color: Colors.white24, height: 32),
        ],
      );
    });

    variableWidgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: _addVariable,
            icon: const Icon(Icons.add),
            label: const Text('افزودن متغیر'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
    return variableWidgets;
  }

  List<Widget> _buildFormulaEditors(Color textColor) {
    List<Widget> formulaWidgets = List.generate(_formulas.length, (index) {
      final formula = _formulas[index];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: _buildTextField(_formulaLabelControllers[index],
                      'برچسب نتیجه', textColor)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.redAccent),
                onPressed: () => _deleteFormula(index),
              )
            ],
          ),
          const SizedBox(height: 8),
          _buildTextField(_formulaResultKeyControllers[index],
              'کلید نتیجه (انگلیسی، بدون فاصله)', textColor,
              isExpression: true),
          const SizedBox(height: 8),
          // MODIFIED: Added icon button for visual editor
          Row(
            children: [
              Expanded(
                child: _buildTextField(_formulaExpressionControllers[index],
                    'عبارت فرمول', textColor,
                    isExpression: true),
              ),
              IconButton(
                icon: Icon(Icons.schema_outlined,
                    color: textColor.withOpacity(0.8)),
                tooltip: 'ویرایشگر بصری فرمول',
                onPressed: () {
                  widget.renderingSystem.manager
                      ?.send(ShowVisualFormulaEditorEvent(
                    methodId: widget.methodId,
                    formulaResultKey: formula.resultKey,
                  ));
                },
              )
            ],
          ),
          if (index < _formulas.length - 1)
            const Divider(color: Colors.white24, height: 32),
        ],
      );
    });

    formulaWidgets.add(
      Padding(
        padding: const EdgeInsets.only(top: 16.0),
        child: Center(
          child: ElevatedButton.icon(
            onPressed: _addFormula,
            icon: const Icon(Icons.add),
            label: const Text('افزودن فرمول'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.black,
              backgroundColor: Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
    return formulaWidgets;
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
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
