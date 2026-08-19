// lib/modules/ui/dialogs.dart
// Dialog widgets for JA_PyToCy — fully localized

import 'package:flutter/material.dart';
import '../i18n.dart';
import 'styles.dart';

class HelpEnvironmentDialog extends StatelessWidget {
  const HelpEnvironmentDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final s = context.strings;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, color: c.linkAccent, size: 24),
          const SizedBox(width: 10),
          Text(s.dlgHelpTitle),
        ],
      ),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // C Compiler Info
              Text(
                s.envCompilerFound.split(':')[0],
                style: TextStyle(fontWeight: FontWeight.bold, color: c.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.bgTertiary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: c.borderDefault),
                ),
                child: Text(
                  s.dlgHelpCompilerDesc,
                  style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 20),

              // Cython Info
              Text(
                s.envCythonFound.split(':')[0],
                style: TextStyle(fontWeight: FontWeight.bold, color: c.textPrimary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.bgTertiary,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: c.borderDefault),
                ),
                child: Text(
                  s.dlgHelpCythonDesc,
                  style: TextStyle(color: c.textSecondary, fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.btnClose),
        ),
      ],
    );
  }
}
