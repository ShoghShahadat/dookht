import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:nexus/nexus.dart';
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
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    final rs = widget.renderingSystem;
    final measurements = rs.get<MeasurementComponent>(widget.customerId);

    _initializeController('bustCircumference', measurements?.bustCircumference);
    _initializeController(
        'waistCircumference', measurements?.waistCircumference);
    _initializeController('hipCircumference', measurements?.hipCircumference);
    _initializeController('frontInterscye', measurements?.frontInterscye);
    _initializeController('backInterscye', measurements?.backInterscye);
    _initializeController('sleeveLength', measurements?.sleeveLength);
    _initializeController('armCircumference', measurements?.armCircumference);
    _initializeController(
        'wristCircumference', measurements?.wristCircumference);
  }

  void _initializeController(String key, double? value) {
    _controllers[key] = TextEditingController(text: value?.toString() ?? '');
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
          onPressed: () => rs.manager?.send(ShowCustomerListEvent()),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
        child: Column(
          children: [
            _buildSection('اندازه‌ها', textColor, [
              _buildTextField('bustCircumference', 'دور سینه', textColor),
              _buildTextField('waistCircumference', 'دور کمر', textColor),
              _buildTextField('hipCircumference', 'دور باسن', textColor),
              _buildTextField('frontInterscye', 'کارور جلو', textColor),
              _buildTextField('backInterscye', 'کارور پشت', textColor),
              _buildTextField('sleeveLength', 'قد آستین', textColor),
              _buildTextField('armCircumference', 'دور بازو', textColor),
              _buildTextField('wristCircumference', 'دور مچ', textColor),
            ]),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () =>
                  rs.manager?.send(PerformCalculationEvent(widget.customerId)),
              icon: const Icon(Icons.calculate_outlined),
              label: const Text('محاسبه کن'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30)),
              ),
            ),
            const SizedBox(height: 30),
            // The results section now listens for changes on the customer entity.
            AnimatedBuilder(
                animation: rs.getNotifier(widget.customerId),
                builder: (context, _) {
                  final results =
                      rs.get<CalculationResultComponent>(widget.customerId);
                  return _buildSection('نتایج الگو', textColor,
                      _buildResultTiles(results, textColor));
                }),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildResultTiles(
      CalculationResultComponent? results, Color textColor) {
    if (results == null)
      return [const Text('...', style: TextStyle(color: Colors.white70))];

    final tiles = <Widget>[];
    if (results.bodiceBustWidth != null)
      tiles.add(
          _resultTile('عرض کادر سینه', results.bodiceBustWidth, textColor));
    if (results.bodiceWaistWidth != null)
      tiles.add(
          _resultTile('عرض کادر کمر', results.bodiceWaistWidth, textColor));
    if (results.bodiceHipWidth != null)
      tiles
          .add(_resultTile('عرض کادر باسن', results.bodiceHipWidth, textColor));
    if (results.frontInterscyeWidth != null)
      tiles.add(_resultTile(
          'پهنای کارور جلو', results.frontInterscyeWidth, textColor));
    if (results.backInterscyeWidth != null)
      tiles.add(_resultTile(
          'پهنای کارور پشت', results.backInterscyeWidth, textColor));
    if (results.sleeveWidth != null)
      tiles.add(
          _resultTile('گشادی کف حلقه آستین', results.sleeveWidth, textColor));
    if (results.sleeveCuffWidth != null)
      tiles
          .add(_resultTile('عرض مچ آستین', results.sleeveCuffWidth, textColor));

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

  Widget _buildTextField(String key, String label, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: _controllers[key],
        onChanged: (value) {
          widget.renderingSystem.manager?.send(UpdateMeasurementEvent(
            customerId: widget.customerId,
            fieldKey: key,
            value: double.tryParse(value),
          ));
        },
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: textColor.withOpacity(0.7)),
          suffixText: 'cm',
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
