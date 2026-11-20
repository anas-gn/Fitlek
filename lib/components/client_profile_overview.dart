import 'package:flutter/material.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import '../models/client_profile_completion.dart';
import 'profile_completed_badge.dart';
import '../theme/fitlek_theme_extension.dart';

class ClientProfileIdentityCard extends StatelessWidget {
  final Map<String, dynamic> profile;
  final VoidCallback onAvatar, onChangePhoto;
  final bool uploading;
  const ClientProfileIdentityCard(
      {super.key,
      required this.profile,
      required this.onAvatar,
      required this.onChangePhoto,
      this.uploading = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.fitlek, scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final name =
        '${profile['firstName'] ?? ''} ${profile['lastName'] ?? ''}'.trim();
    final avatar = '${profile['avatarUrl'] ?? ''}';
    final city = '${profile['ville'] ?? ''}'.trim();
    final premium = profile['isPremium'] == true || profile['isPremium'] == 1;
    final initials = name
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s.characters.first)
        .join()
        .toUpperCase();
    final placeholder = Center(
        child: Text(initials.isEmpty ? 'S' : initials,
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: scheme.primary)));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.card2, colors.card]),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Stack(clipBehavior: Clip.none, children: [
            Semantics(
                label: l10n.clientProfileViewPhotoLabel,
                button: true,
                child: InkWell(
                    onTap: uploading ? null : onAvatar,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                        width: 86,
                        height: 96,
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: colors.border)),
                        child: uploading
                            ? const Center(
                                child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2)))
                            : avatar.isEmpty
                                ? placeholder
                                : Image.network(avatar,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.center,
                                    errorBuilder: (_, __, ___) =>
                                        placeholder)))),
            Positioned(
                right: -5,
                bottom: -5,
                child: IconButton.filled(
                    tooltip: l10n.clientProfileChangePhotoTooltip,
                    onPressed: uploading ? null : onChangePhoto,
                    style: IconButton.styleFrom(
                        foregroundColor: scheme.onPrimary,
                        backgroundColor: scheme.primary,
                        minimumSize: const Size(32, 32),
                        maximumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        side: BorderSide(color: colors.card, width: 2)),
                    icon: const Icon(Icons.camera_alt_outlined, size: 16))),
          ]),
          const SizedBox(width: 18),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(
                    premium
                        ? l10n.clientProfilePremiumBadge
                        : l10n.clientProfileJourneyBadge,
                    style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.3,
                        fontWeight: FontWeight.w800,
                        color: colors.textMuted)),
                const SizedBox(height: 8),
                Text(name.isEmpty ? l10n.clientProfileWelcomeTitle : name,
                    style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 22,
                        height: 1.15,
                        letterSpacing: -.6,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text('${profile['email'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(color: colors.textSecondary, fontSize: 12)),
                const SizedBox(height: 9),
                Row(children: [
                  Icon(Icons.location_on_outlined,
                      size: 15, color: colors.textMuted),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(
                          city.isEmpty ? l10n.clientProfileSetCity : city,
                          style:
                              TextStyle(color: colors.textMuted, fontSize: 12)))
                ]),
              ])),
        ]),
        const SizedBox(height: 22),
        Container(height: 1, color: colors.border.withValues(alpha: .7)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.lock_outline_rounded, size: 14, color: colors.textMuted),
          const SizedBox(width: 8),
          Expanded(
              child: Text(l10n.clientProfilePersonalSpaceNote,
                  style: TextStyle(
                      color: colors.textMuted, fontSize: 11, height: 1.5)))
        ]),
      ]),
    );
  }
}

class ClientProfileCompletionCard extends StatelessWidget {
  final ClientProfileCompletion completion;
  final ValueChanged<String> onComplete;
  const ClientProfileCompletionCard(
      {super.key, required this.completion, required this.onComplete});

  String _stepLabel(AppLocalizations l10n, ClientProfileStep step) {
    switch (step.section) {
      case 'photo':
        return l10n.clientProfileStepPhoto;
      case 'email':
        return l10n.clientProfileStepEmail;
      case 'phone':
        return l10n.clientProfileStepPhone;
      case 'location':
        return l10n.clientProfileStepCity;
      case 'interests':
        return l10n.clientProfileStepInterests;
      case 'details':
        if (step.label.contains('first')) return l10n.clientProfileStepFirstName;
        if (step.label.contains('last')) return l10n.clientProfileStepLastName;
        if (step.label.contains('height')) return l10n.clientProfileStepHeight;
        return step.label;
      default:
        return step.label;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.fitlek, scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    if (completion.isComplete) {
      return const Align(
          alignment: Alignment.centerLeft, child: ProfileCompletedBadge());
    }
    return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colors.border)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(l10n.clientProfileCompletionTitle,
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface))),
            Text('${completion.percent}%',
                style: TextStyle(
                    color: colors.success,
                    fontSize: 22,
                    fontWeight: FontWeight.w800))
          ]),
          const SizedBox(height: 6),
          Text(
              l10n.clientProfileCompletionDetailsAdded(
                  completion.completed, completion.steps.length),
              style: TextStyle(color: colors.textMuted, fontSize: 12)),
          const SizedBox(height: 15),
          TweenAnimationBuilder<double>(
              tween: Tween(end: completion.fraction),
              duration: const Duration(milliseconds: 450),
              builder: (_, value, __) => LinearProgressIndicator(
                  value: value,
                  minHeight: 7,
                  borderRadius: BorderRadius.circular(10),
                  backgroundColor: colors.border,
                  color: colors.success,
                  semanticsLabel: l10n.clientProfileCompletionSemantic,
                  semanticsValue: '${completion.percent}%')),
          const SizedBox(height: 15),
          InkWell(
              onTap: () => onComplete(completion.next!.section),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: scheme.primary.withValues(alpha: .08),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.auto_awesome_outlined,
                            size: 17, color: scheme.primary)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_stepLabel(l10n, completion.next!),
                            style: TextStyle(
                                color: scheme.onSurface,
                                fontSize: 12,
                                fontWeight: FontWeight.w600))),
                    Icon(Icons.arrow_forward_rounded,
                        size: 18, color: scheme.primary)
                  ]))),
        ]));
  }
}
