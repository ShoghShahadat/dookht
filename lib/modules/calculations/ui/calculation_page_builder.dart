import 'dart:ui';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/calculations/components/calculation_state_component.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';
import '../../customers/components/customer_component.dart';
import '../../customers/components/measurement_component.dart';
import '../../customers/customer_events.dart';
import '../../ui/rendering_system.dart';
import '../../ui/view_manager/view_manager_component.dart';
import '../calculation_events.dart';
import '../components/calculation_result_component.dart';

class CalculationPageBuilder implements IWidgetBuilder {
  @override
  Widget build(
      BuildContext context, FlutterRenderingSystem rs, EntityId entityId) {
    final viewManagerId = rs.getAllIdsWithTag('view_manager').firstOrNull;
    if (viewManagerId == null) return const SizedBox.shrink();

    final viewState = rs.get<ViewStateComponent>(viewManagerId);
    final activeCustomerId = viewState?.activeCustomerId;
    if (activeCustomerId == null) return const SizedBox.shrink();

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
  final Map<String, TextEditingController> _measurementControllers = {};
  final Map<String, TextEditingController> _variableControllers = {};

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final rs = widget.renderingSystem;
    final measurements = rs.get<MeasurementComponent>(widget.customerId);

    // Initialize measurement controllers
    _initMeasurementController(
        'bustCircumference', measurements?.bustCircumference);
    _initMeasurementController(
        'waistCircumference', measurements?.waistCircumference);
    _initMeasurementController(
        'hipCircumference', measurements?.hipCircumference);
    _initMeasurementController('frontInterscye', measurements?.frontInterscye);
    _initMeasurementController('backInterscye', measurements?.backInterscye);
    _initMeasurementController('sleeveLength', measurements?.sleeveLength);
    _initMeasurementController(
        'armCircumference', measurements?.armCircumference);
    _initMeasurementController(
        'wristCircumference', measurements?.wristCircumference);

    // Initialize variable controllers based on the selected method
    _initVariableControllers();
  }

  void _initVariableControllers() {
    final rs = widget.renderingSystem;
    final calcState = rs.get<CalculationStateComponent>(widget.customerId);
    final methodId = calcState?.selectedMethodId;
    if (methodId == null) return;

    final method = rs.get<PatternMethodComponent>(methodId);
    if (method == null) return;

    for (var variable in method.variables) {
      final value =
          calcState?.variableValues[variable.key] ?? variable.defaultValue;
      _variableControllers[variable.key] =
          TextEditingController(text: value.toString());
    }
  }

  void _initMeasurementController(String key, double? value) {
    _measurementControllers[key] =
        TextEditingController(text: value?.toString() ?? '');
  }

  @override
  void dispose() {
    _measurementControllers.values.forEach((c) => c.dispose());
    _variableControllers.values.forEach((c) => c.dispose());
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
          onPressed: () => rs.manager?.send(ShowCustomerListEvent()),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: AnimatedBuilder(
          animation: rs.getNotifier(widget.customerId),
          builder: (context, _) {
            // Re-initialize variable controllers if the method changes
            _initVariableControllers();
            return Column(
              children: [
                _buildMethodSelector(textColor),
                const SizedBox(height: 20),
                _buildSection(
                    'متغیرها', textColor, _buildVariableFields(textColor)),
                const SizedBox(height: 20),
                _buildSection('اندازه‌ها', textColor, [
                  _buildTextField(_measurementControllers, 'bustCircumference',
                      'دور سینه', textColor),
                  _buildTextField(_measurementControllers, 'waistCircumference',
                      'دور کمر', textColor),
                  _buildTextField(_measurementControllers, 'hipCircumference',
                      'دور باسن', textColor),
                  _buildTextField(_measurementControllers, 'frontInterscye',
                      'کارور جلو', textColor),
                  _buildTextField(_measurementControllers, 'backInterscye',
                      'کارور پشت', textColor),
                  _buildTextField(_measurementControllers, 'sleeveLength',
                      'قد آستین', textColor),
                  _buildTextField(_measurementControllers, 'armCircumference',
                      'دور بازو', textColor),
                  _buildTextField(_measurementControllers, 'wristCircumference',
                      'دور مچ', textColor),
                ]),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => rs.manager
                      ?.send(PerformCalculationEvent(widget.customerId)),
                  icon: const Icon(Icons.calculate_outlined),
                  label: const Text('محاسبه کن'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                  ),
                ),
                const SizedBox(height: 30),
                _buildResultsSection(textColor),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResultsSection(Color textColor) {
    final rs = widget.renderingSystem;
    final results = rs.get<CalculationResultComponent>(widget.customerId);
    final calcState = rs.get<CalculationStateComponent>(widget.customerId);
    final method = (calcState?.selectedMethodId != null)
        ? rs.get<PatternMethodComponent>(calcState!.selectedMethodId!)
        : null;

    return _buildSection(
        'نتایج الگو', textColor, _buildResultTiles(results, method, textColor));
  }

  List<Widget> _buildVariableFields(Color textColor) {
    final rs = widget.renderingSystem;
    final calcState = rs.get<CalculationStateComponent>(widget.customerId);
    final methodId = calcState?.selectedMethodId ??
        rs.getAllIdsWithTag('pattern_method').firstOrNull;
    if (methodId == null) return [const SizedBox.shrink()];

    final method = rs.get<PatternMethodComponent>(methodId);
    if (method == null || method.variables.isEmpty) {
      return [
        Text('این متد متغیر ورودی ندارد.',
            style: TextStyle(color: textColor.withOpacity(0.7)))
      ];
    }

    return method.variables.map((variable) {
      return _buildTextField(
        _variableControllers,
        variable.key,
        variable.label,
        textColor,
        isVariable: true,
      );
    }).toList();
  }

  Widget _buildMethodSelector(Color textColor) {
    final rs = widget.renderingSystem;
    final allMethodIds = rs.getAllIdsWithTag('pattern_method');
    final calcState = rs.get<CalculationStateComponent>(widget.customerId);
    final selectedMethodId =
        calcState?.selectedMethodId ?? allMethodIds.firstOrNull;

    final items = allMethodIds.map((id) {
      final method = rs.get<PatternMethodComponent>(id);
      return DropdownMenuItem<EntityId>(
        value: id,
        child: Text(method?.name ?? 'متد ناشناس',
            style: const TextStyle(color: Colors.black)),
      );
    }).toList();

    return _buildSection('انتخاب متد', textColor, [
      if (items.isNotEmpty)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<EntityId>(
              value: selectedMethodId,
              isExpanded: true,
              dropdownColor: Colors.white,
              items: items,
              onChanged: (newId) {
                if (newId != null) {
                  rs.manager?.send(SelectPatternMethodEvent(
                    customerId: widget.customerId,
                    methodId: newId,
                  ));
                }
              },
            ),
          ),
        )
      else
        Text('هیچ متدی یافت نشد.', style: TextStyle(color: textColor)),
    ]);
  }

  List<Widget> _buildResultTiles(CalculationResultComponent? results,
      PatternMethodComponent? method, Color textColor) {
    if (results == null || method == null)
      return [const Text('...', style: TextStyle(color: Colors.white70))];

    final tiles = method.formulas.map((formula) {
      final value = results.toJson()[formula.resultKey];
      if (value != null) {
        return _resultTile(formula.label, value as double?, textColor);
      }
      return const SizedBox.shrink();
    }).toList();

    return tiles.isNotEmpty
        ? tiles
        : [
            const Text('برای دیدن نتایج، مقادیر را وارد و محاسبه کنید.',
                style: TextStyle(color: Colors.white70))
          ];
  }

  Widget _resultTile(String title, double? value, Color textColor) {
    return ListTile(
      title: Text(title, style: TextStyle(color: textColor.withOpacity(0.8))),
      trailing: Text('${value?.toStringAsFixed(2) ?? '-'} cm',
          style: TextStyle(
              color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
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
              const Divider(color: Colors.white30, height: 20, thickness: 0.5),
              ...children,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(Map<String, TextEditingController> controllers,
      String key, String label, Color textColor,
      {bool isVariable = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controllers[key],
        onChanged: (value) {
          final parsedValue = double.tryParse(value);
          if (isVariable) {
            widget.renderingSystem.manager?.send(UpdateCalculationVariableEvent(
              customerId: widget.customerId,
              variableKey: key,
              value: parsedValue,
            ));
          } else {
            widget.renderingSystem.manager?.send(UpdateMeasurementEvent(
              customerId: widget.customerId,
              fieldKey: key,
              value: parsedValue,
            ));
          }
        },
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          suffixText: isVariable ? '' : 'cm',
          suffixStyle: TextStyle(color: textColor.withOpacity(0.5)),
          enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: textColor.withOpacity(0.3))),
          focusedBorder:
              UnderlineInputBorder(borderSide: BorderSide(color: textColor)),
        ),
      ),
    );
  }
}
