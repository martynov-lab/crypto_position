import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ui_kit/ui_kit.dart';

class ResultTile extends StatelessWidget {
  final ValueListenable listenable;
  final String title;

  const ResultTile({super.key, required this.listenable, required this.title});

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(title),
    trailing: ValueListenableBuilder(
      valueListenable: listenable,
      builder: (context, value, child) {
        final result = value == null ? '-' : value.toStringAsFixed(2);

        return Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 20,
          children: [
            Text(result),
            IconButton(
              icon: const Icon(AppIcons.copy_outlined_24),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: result));
              },
            ),
          ],
        );
      },
    ),
  );
}
