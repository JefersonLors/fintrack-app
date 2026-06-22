import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

bool dismissKeyboardForBack(BuildContext context) {
  final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
  final primaryFocus = FocusManager.instance.primaryFocus;
  final editableFocused = _isEditableTextFocused(primaryFocus?.context);

  if (!keyboardVisible && !editableFocused) {
    return false;
  }

  primaryFocus?.unfocus();
  SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
  return true;
}

bool _isEditableTextFocused(BuildContext? context) {
  if (context == null) {
    return false;
  }

  if (context.widget is EditableText) {
    return true;
  }

  var found = false;
  context.visitAncestorElements((element) {
    if (element.widget is EditableText) {
      found = true;
      return false;
    }
    return true;
  });
  return found;
}
