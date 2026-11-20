import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:fitlek1/l10n/app_localizations.dart';
import 'meal_visuals.dart';

class MealScannerView extends StatelessWidget {
  final String? photoPath;
  final Uint8List? photoBytes;
  final bool busy, picking;
  final double portion;
  final TextEditingController notes;
  final VoidCallback onCamera, onGallery, onHistory, onAnalyze;
  final ValueChanged<double> onPortion;
  final Widget frameOverlay;
  final Widget? cameraPreview;
  const MealScannerView(
      {super.key,
      this.photoPath,
      this.photoBytes,
      this.cameraPreview,
      required this.busy,
      required this.picking,
      required this.portion,
      required this.notes,
      required this.onCamera,
      required this.onGallery,
      required this.onHistory,
      required this.onAnalyze,
      required this.onPortion,
      required this.frameOverlay});
  bool get disabled => busy || picking;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: mealInk,
      appBar: AppBar(
          backgroundColor: mealInk,
          surfaceTintColor: Colors.transparent,
          title: Text(l10n.mealScannerTitle,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          actions: [
            IconButton(
                tooltip: l10n.mealScannerSavedMealsTooltip,
                onPressed: busy ? null : onHistory,
                icon: const Icon(Icons.history_rounded))
          ]),
      bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: FilledButton(
                        onPressed:
                            disabled || photoPath == null ? null : onAnalyze,
                        style: FilledButton.styleFrom(
                            backgroundColor: mealCream,
                            foregroundColor: mealInk,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18))),
                        child: busy
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: mealInk, strokeWidth: 2))
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                    const Icon(Icons.auto_awesome_rounded,
                                        size: 18),
                                    const SizedBox(width: 10),
                                    Flexible(
                                        child: Text(
                                            l10n.mealScannerDiscoverButton,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700))),
                                    const SizedBox(width: 12),
                                    const Icon(Icons.arrow_forward, size: 18)
                                  ]))),
                const SizedBox(height: 8),
                Text(l10n.mealScannerFooterDisclaimer,
                    style: const TextStyle(color: mealMuted, fontSize: 10)),
              ]))),
      body: SafeArea(
          bottom: false,
          child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
              children: [
                MealChip(l10n.mealScannerMeetYourMealChip,
                    icon: Icons.spa_outlined),
                const SizedBox(height: 15),
                Text(l10n.mealScannerHeading,
                    style: const TextStyle(
                        color: mealCream,
                        fontSize: 34,
                        height: 1.08,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.3)),
                const SizedBox(height: 10),
                Text(l10n.mealScannerSubheading,
                    style: const TextStyle(
                        color: mealMuted, fontSize: 13, height: 1.6)),
                const SizedBox(height: 20),
                Row(children: [
                  _step('01', l10n.mealScannerStepCapture, photoPath == null),
                  _step('02', l10n.mealScannerStepReview,
                      photoPath != null && !busy),
                  _step('03', l10n.mealScannerStepDiscover, busy)
                ]),
                const SizedBox(height: 16),
                AspectRatio(
                    aspectRatio: 1.06,
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                                color: mealLime.withValues(alpha: .2))),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(27),
                            child: Stack(fit: StackFit.expand, children: [
                              if (photoPath != null)
                                MealPhoto(path: photoPath!, bytes: photoBytes)
                              else if (cameraPreview != null)
                                cameraPreview!
                              else
                                Container(
                                    decoration: const BoxDecoration(
                                        gradient: RadialGradient(colors: [
                                      Color(0xFF2B513B),
                                      Color(0xFF102B23)
                                    ], radius: .85)),
                                    child: Center(
                                        child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                          Container(
                                              width: 108,
                                              height: 108,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                      color: mealLime
                                                          .withValues(
                                                              alpha: .15),
                                                      width: 2)),
                                              child: Center(
                                                  child: Container(
                                                      width: 76,
                                                      height: 76,
                                                      decoration: BoxDecoration(
                                                          shape:
                                                              BoxShape.circle,
                                                          color: mealLime
                                                              .withValues(
                                                                  alpha: .09)),
                                                      child: const Icon(
                                                          Icons
                                                              .camera_alt_outlined,
                                                          size: 33,
                                                          color: mealLime)))),
                                          const SizedBox(height: 16),
                                          Text(l10n.mealScannerLetsTakeALook,
                                              style: const TextStyle(
                                                  color: mealCream,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 7),
                                          Text(l10n.mealScannerGoodLightHint,
                                              style: const TextStyle(
                                                  color: mealMuted,
                                                  fontSize: 11)),
                                        ]))),
                              IgnorePointer(child: frameOverlay),
                              Positioned(
                                  bottom: 15,
                                  left: 15,
                                  right: 15,
                                  child: Center(
                                      child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 8),
                                          decoration: BoxDecoration(
                                              color: mealInk.withValues(
                                                  alpha: .85),
                                              borderRadius:
                                                  BorderRadius.circular(30)),
                                          child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                    photoPath == null
                                                        ? Icons
                                                            .center_focus_strong
                                                        : Icons
                                                            .check_circle_outline,
                                                    color: mealLime,
                                                    size: 14),
                                                const SizedBox(width: 7),
                                                Flexible(
                                                    child: Text(
                                                        photoPath == null
                                                            ? l10n
                                                                .mealScannerKeepWholePlate
                                                            : l10n
                                                                .mealScannerPhotoReady,
                                                        style: const TextStyle(
                                                            color: mealCream,
                                                            fontSize: 11)))
                                              ])))),
                              if (busy)
                                Container(
                                    color: mealInk.withValues(alpha: .87),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          const CircularProgressIndicator(
                                              color: mealLime, strokeWidth: 2),
                                          const SizedBox(height: 22),
                                          Text(l10n.mealScannerAnalyzingTitle,
                                              style: const TextStyle(
                                                  color: mealCream,
                                                  fontSize: 19,
                                                  fontWeight: FontWeight.w600)),
                                          const SizedBox(height: 9),
                                          Text(
                                              l10n.mealScannerAnalyzingSubtitle,
                                              style: const TextStyle(
                                                  color: mealMuted,
                                                  fontSize: 12)),
                                        ])),
                            ])))),
                const SizedBox(height: 18),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(
                      child: Column(children: [
                    const SizedBox(height: 15),
                    IconButton.filledTonal(
                      tooltip: l10n.mealScannerFromGalleryTooltip,
                      onPressed: disabled ? null : onGallery,
                      style: IconButton.styleFrom(
                        backgroundColor: mealSurface,
                        foregroundColor: mealCream,
                        fixedSize: const Size(54, 54),
                        side:
                            BorderSide(color: mealCream.withValues(alpha: .15)),
                      ),
                      icon: const Icon(Icons.photo_library_outlined, size: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(l10n.mealScannerGalleryLabel,
                        style: const TextStyle(color: mealMuted, fontSize: 11)),
                  ])),
                  Expanded(
                      child: Column(children: [
                    Tooltip(
                        message: photoPath != null
                            ? l10n.mealScannerRetakePhoto
                            : l10n.mealScannerCapturePhoto,
                        child: Container(
                          width: 84,
                          height: 84,
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white
                                    .withValues(alpha: disabled ? .35 : 1),
                                width: 2),
                          ),
                          child: Material(
                            color: disabled
                                ? const Color(0xFF8C9B96)
                                : Colors.white,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              key: const ValueKey('meal-capture-button'),
                              customBorder: const CircleBorder(),
                              onTap: disabled ? null : onCamera,
                              child: picking
                                  ? const Center(
                                      child: SizedBox(
                                          width: 26,
                                          height: 26,
                                          child: CircularProgressIndicator(
                                              color: mealInk, strokeWidth: 2)))
                                  : const Icon(Icons.camera_alt_rounded,
                                      color: mealInk, size: 32),
                            ),
                          ),
                        )),
                    const SizedBox(height: 9),
                    Text(
                        photoPath != null
                            ? l10n.mealScannerRetakePhoto
                            : l10n.mealScannerCapturePhoto,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: mealCream,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ])),
                  const Expanded(child: SizedBox()),
                ]),
                const SizedBox(height: 23),
                Text(l10n.mealScannerPortionQuestion,
                    style: const TextStyle(
                        color: mealCream,
                        fontSize: 17,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 5),
                Text(l10n.mealScannerPortionSubtitle,
                    style: const TextStyle(color: mealMuted, fontSize: 11)),
                const SizedBox(height: 12),
                Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                        color: const Color(0xFF102B23),
                        borderRadius: BorderRadius.circular(17)),
                    child: Row(children: [
                      for (final value in [0.5, 1.0, 1.5, 2.0])
                        Expanded(
                            child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 2),
                                child: Material(
                                    color: portion == value
                                        ? mealCream
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                        onTap: disabled
                                            ? null
                                            : () => onPortion(value),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                        child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            child: Text(
                                                switch (value) {
                                                  0.5 =>
                                                    l10n.mealScannerPortionHalf,
                                                  1.0 =>
                                                    l10n.mealScannerPortionOne,
                                                  1.5 => l10n
                                                      .mealScannerPortionOneHalf,
                                                  _ =>
                                                    l10n.mealScannerPortionTwo,
                                                },
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    color: portion == value
                                                        ? mealInk
                                                        : mealMuted,
                                                    fontSize: 11,
                                                    fontWeight:
                                                        FontWeight.w600)))))))
                    ])),
                const SizedBox(height: 21),
                TextField(
                    controller: notes,
                    enabled: !busy,
                    maxLength: 600,
                    minLines: 1,
                    maxLines: 3,
                    style: const TextStyle(color: mealCream, fontSize: 13),
                    decoration: InputDecoration(
                        labelText: l10n.mealScannerNotesLabel,
                        hintText: l10n.mealScannerNotesHint,
                        counterText: '',
                        labelStyle:
                            const TextStyle(color: mealMuted, fontSize: 13),
                        hintStyle:
                            const TextStyle(color: mealMuted, fontSize: 12),
                        prefixIcon: const Icon(Icons.edit_note_outlined,
                            color: mealLime),
                        filled: true,
                        fillColor: const Color(0xFF102B23),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: BorderSide(
                                color: mealCream.withValues(alpha: .1))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(17),
                            borderSide: const BorderSide(color: mealLime)))),
              ])),
    );
  }
  Widget _step(String number, String label, bool active) => Expanded(
          child: Row(children: [
        Container(
            width: 23,
            height: 23,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: active ? mealLime : mealSurface, shape: BoxShape.circle),
            child: Text(number,
                style: TextStyle(
                    color: active ? mealInk : mealMuted,
                    fontSize: 9,
                    fontWeight: FontWeight.w700))),
        const SizedBox(width: 7),
        Flexible(
            child: Text(label,
                style: TextStyle(
                    color: active ? mealCream : mealMuted,
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400))),
      ]));
}
