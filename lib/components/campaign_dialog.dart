import 'package:flutter/material.dart';
import '../theme/fitlek_theme_extension.dart';
import 'sirvya_logo.dart';

class CampaignDialog extends StatelessWidget {
  final Map<String, dynamic> item;
  final ImageProvider? imageProvider;
  const CampaignDialog({super.key, required this.item, this.imageProvider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final destination = '${item['destination'] ?? ''}'.trim().isNotEmpty;
    final imageUrl = '${item['imageUrl'] ?? ''}'.trim();
    final hasImage = imageProvider != null || imageUrl.isNotEmpty;
    final button = '${item['buttonLabel'] ?? ''}'.trim();
    final action =
        destination ? (button.isEmpty ? 'Explore now' : button) : 'Got it';
    return Dialog(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 420,
                maxHeight: MediaQuery.sizeOf(context).height * .85),
            child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: dark
                            ? [const Color(0xFF173C35), const Color(0xFF09251F)]
                            : [Colors.white, f.card2]),
                    borderRadius: BorderRadius.circular(28),
                    border:
                        Border.all(color: cs.primary.withValues(alpha: .18)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: .25),
                          blurRadius: 48,
                          offset: const Offset(0, 24))
                    ]),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Stack(children: [
                        SizedBox(
                            width: double.infinity,
                            height: hasImage ? 190 : 116,
                            child: hasImage
                                ? Image(
                                    image:
                                        imageProvider ?? NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _artwork(context))
                                : _artwork(context)),
                        if (hasImage)
                          Positioned.fill(
                              child: IgnorePointer(
                                  child: DecoratedBox(
                                      decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                              begin: Alignment.topCenter,
                                              end: Alignment.bottomCenter,
                                              colors: [
                                Colors.black.withValues(alpha: .1),
                                Colors.transparent,
                                const Color(0xFF09251F).withValues(alpha: .85)
                              ]))))),
                        Positioned(
                            left: 20,
                            bottom: 18,
                            child: Row(children: [
                              const SirvyaLogo(
                                  variant: SirvyaLogoVariant.mark,
                                  height: 22,
                                  color: Color(0xFFF2EFDF)),
                              const SizedBox(width: 9),
                              Text('SIRVYA  /  INSIDE',
                                  style: TextStyle(
                                      color: const Color(0xFFF2EFDF),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 2)),
                            ])),
                        Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                                decoration: BoxDecoration(
                                    color: const Color(0xFF031713)
                                        .withValues(alpha: .65),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: .22))),
                                child: IconButton(
                                    tooltip: 'Close announcement',
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    icon: const Icon(Icons.close_rounded,
                                        color: Color(0xFFF2EFDF), size: 20)))),
                      ]),
                      Flexible(
                          child: SingleChildScrollView(
                              padding:
                                  const EdgeInsets.fromLTRB(24, 24, 24, 22),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(children: [
                                      Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                              color: dark
                                                  ? const Color(0xFFBDDC9B)
                                                  : f.success,
                                              shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text('SELECTED FOR YOU',
                                          style: TextStyle(
                                              color: dark
                                                  ? const Color(0xFFBDDC9B)
                                                  : f.success,
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: 1.8)),
                                    ]),
                                    const SizedBox(height: 13),
                                    Text(
                                        '${item['title'] ?? 'Something new at Sirvya'}',
                                        style: TextStyle(
                                            color: cs.onSurface,
                                            fontSize: 27,
                                            height: 1.12,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -.8)),
                                    if ('${item['body'] ?? ''}'
                                        .trim()
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 13),
                                      Text('${item['body']}',
                                          style: TextStyle(
                                              color: f.textSecondary,
                                              fontSize: 14,
                                              height: 1.65)),
                                    ],
                                  ]))),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Divider(
                              height: 1,
                              color: cs.primary.withValues(alpha: .12))),
                      Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 16),
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, destination),
                                    style: FilledButton.styleFrom(
                                        backgroundColor: cs.primary,
                                        foregroundColor: cs.onPrimary,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 18, vertical: 14),
                                        shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(17))),
                                    child: Row(children: [
                                      Expanded(
                                          child: Text(action,
                                              style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight:
                                                      FontWeight.w700))),
                                      const SizedBox(width: 12),
                                      Container(
                                          padding: const EdgeInsets.all(5),
                                          decoration: BoxDecoration(
                                              color: cs.onPrimary
                                                  .withValues(alpha: .08),
                                              shape: BoxShape.circle),
                                          child: Icon(
                                              destination
                                                  ? Icons.arrow_forward_rounded
                                                  : Icons.check_rounded,
                                              size: 18)),
                                    ]))),
                            if (destination)
                              TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  style: TextButton.styleFrom(
                                      foregroundColor: f.textMuted),
                                  child: const Text('Maybe later',
                                      style: TextStyle(fontSize: 12))),
                          ])),
                    ]))));
  }

  Widget _artwork(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E6351), Color(0xFF0A2D25)])),
        child: Stack(children: [
          Positioned(
              right: -25,
              top: -70,
              child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: .08),
                          width: 35)))),
          Positioned(
              right: 35,
              top: 28,
              child: Icon(Icons.auto_awesome_rounded,
                  size: 32, color: cs.primary.withValues(alpha: .55))),
        ]));
  }
}
