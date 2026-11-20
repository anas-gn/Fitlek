import 'package:flutter/material.dart';
import 'package:fitlek1/l10n/app_localizations.dart';

class ChatSelectionBar extends StatelessWidget implements PreferredSizeWidget {
  final int count;
  final VoidCallback onClose, onSelectAll, onDelete;
  const ChatSelectionBar(
      {super.key,
      required this.count,
      required this.onClose,
      required this.onSelectAll,
      required this.onDelete});
  @override
  Size get preferredSize => const Size.fromHeight(64);
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppBar(
        leading: IconButton(onPressed: onClose, icon: const Icon(Icons.close)),
        title: Text(l10n.chatSelectionSelectedCount(count)),
        actions: [
          IconButton(
              tooltip: l10n.chatSelectionSelectAllTooltip,
              onPressed: onSelectAll,
              icon: const Icon(Icons.select_all)),
          IconButton(
              tooltip: l10n.chatSelectionDeleteTooltip,
              onPressed: count == 0 ? null : onDelete,
              icon: const Icon(Icons.delete_outline))
        ]);
  }
}

class SelectableChatMessage extends StatelessWidget {
  final bool selecting, selected;
  final VoidCallback onToggle;
  final Widget child;
  const SelectableChatMessage(
      {super.key,
      required this.selecting,
      required this.selected,
      required this.onToggle,
      required this.child});
  @override
  Widget build(BuildContext context) => GestureDetector(
      behavior: HitTestBehavior.opaque,
      onLongPress: onToggle,
      onTap: selecting ? onToggle : null,
      child: Container(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: .12)
              : null,
          child: Row(children: [
            if (selecting)
              Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                      selected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: Theme.of(context).colorScheme.primary)),
            Expanded(child: IgnorePointer(ignoring: selecting, child: child))
          ])));
}
