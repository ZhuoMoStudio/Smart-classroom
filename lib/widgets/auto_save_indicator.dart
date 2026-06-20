import 'package:flutter/material.dart';

class AutoSaveIndicator extends StatelessWidget {
  final bool isDirty, isSaving;
  const AutoSaveIndicator({super.key, this.isDirty = false, this.isSaving = false});

  @override
  Widget build(BuildContext ctx) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle,
        color: isSaving ? Colors.orange : isDirty ? Colors.yellowAccent : Colors.green)),
    const SizedBox(width: 4),
    Text(isSaving ? '保存中...' : (isDirty ? '未保存' : '已保存'), style: Theme.of(ctx).textTheme.bodySmall),
  ]);
}
