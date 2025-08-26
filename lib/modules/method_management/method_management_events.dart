import 'package:nexus/nexus.dart';
import 'package:tailor_assistant/modules/pattern_methods/models/pattern_method_model.dart';

/// Event fired to navigate to the page for editing a specific pattern method.
class ShowEditMethodEvent {
  final EntityId methodId;

  ShowEditMethodEvent(this.methodId);
}

/// Event fired from the edit page to save the updated method details.
class UpdatePatternMethodEvent {
  final EntityId methodId;
  final String newName;
  final List<DynamicVariable> newVariables;
  final List<Formula> newFormulas;

  UpdatePatternMethodEvent({
    required this.methodId,
    required this.newName,
    required this.newVariables,
    required this.newFormulas,
  });
}

/// Event fired to create a new, blank pattern method and navigate to its edit page.
class CreatePatternMethodEvent {}

/// Event fired to delete a pattern method.
class DeletePatternMethodEvent {
  final EntityId methodId;

  DeletePatternMethodEvent(this.methodId);
}
