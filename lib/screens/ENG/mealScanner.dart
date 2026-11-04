import '../../components/meal_diary_actions.dart';
import '../../components/meal_live_camera.dart';
import '../../components/meal_scan_limit_dialog.dart';
import '../../components/meal_visuals.dart';
import '../../components/meal_scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/media_picker_service.dart';
import '../../services/meal_scan_service.dart';
import '../../services/nutrition_diary_service.dart';
import 'nutritionTracker.dart';

const _background = Color(0xFF031713);
const _card = Color(0xFF102E2A);
const _cream = Color(0xFFF2EFDF);
const _muted = Color(0xFFAAC4BF);

ThemeData _mealTheme() => ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _background,
      colorScheme: const ColorScheme.dark(
          primary: _cream, surface: _card, onSurface: _cream),
      appBarTheme: const AppBarTheme(
          backgroundColor: _background,
          foregroundColor: _cream,
          centerTitle: true),
      inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(), filled: true, fillColor: _card),
      snackBarTheme: const SnackBarThemeData(
          backgroundColor: _card, contentTextStyle: TextStyle(color: _cream)),
    );

Widget _primary(String text, VoidCallback? onPressed, {bool busy = false}) =>
    SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
                backgroundColor: _cream, foregroundColor: _background),
            child: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(text,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    const Icon(Icons.arrow_forward)
                  ])));

void _error(BuildContext context, Object error) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error.toString().replaceFirst('Exception: ', ''))));

class MealScannerScreen extends StatefulWidget {
  final int clientID;
  final String token;
  final DateTime? diaryDate;
  const MealScannerScreen(
      {super.key, required this.clientID, required this.token, this.diaryDate});
  @override
  State<MealScannerScreen> createState() => _MealScannerScreenState();
}

class _MealScannerScreenState extends State<MealScannerScreen> {
  XFile? _photo;
  double _portion = 1;
  bool _busy = false, _picking = false;
  final _notes = TextEditingController();
  final _camera = GlobalKey<MealLiveCameraState>();

  void _captureOrRetake() {
    if (_busy || _picking) return;
    if (_photo != null) {
      setState(() => _photo = null);
    } else {
      _camera.currentState?.capture();
    }
  }

  Future<void> _pick(ImageSource source) async {
    if (_picking || _busy) return;
    setState(() => _picking = true);
    try {
      final photo = await AppMediaPicker(context).pickImage(
          source: source, maxWidth: 1280, maxHeight: 1280, imageQuality: 80);
      if (mounted && photo != null) setState(() => _photo = photo);
    } catch (e) {
      if (mounted) _error(context, e);
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _analyze() async {
    if (_photo == null || _busy) return;
    setState(() => _busy = true);
    try {
      final meal = await MealScanService.analyze(
          _photo!, widget.token, _portion, _notes.text.trim());
      if (widget.diaryDate != null) {
        meal.mealDate = ScannedMeal.dayKey(widget.diaryDate!);
      }
      final hour = DateTime.now().hour;
      meal.mealType = hour < 11
          ? 'breakfast'
          : hour < 16
              ? 'lunch'
              : hour < 22
                  ? 'dinner'
                  : 'snack';
      if (!mounted) return;
      await Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => MealResultScreen(
                  meal: meal,
                  clientID: widget.clientID,
                  token: widget.token,
                  initiallySaved: false)));
    } on MealScanLimitException catch (e) {
      if (!mounted) return;
      await showDialog<void>(
          context: context,
          builder: (_) => Theme(
              data: _mealTheme(),
              child: MealScanLimitDialog(
                  dailyLimit: e.dailyLimit, used: e.used, bonus: e.bonus)));
    } catch (e) {
      if (mounted) _error(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Theme(
      data: _mealTheme(),
      child: FutureBuilder(
        future: _photo?.readAsBytes(),
        builder: (context, snapshot) => MealScannerView(
          photoPath: _photo?.path,
          photoBytes: snapshot.data,
          busy: _busy,
          picking: _picking,
          portion: _portion,
          notes: _notes,
          cameraPreview: _photo == null
              ? MealLiveCamera(
                  key: _camera,
                  onCaptured: (photo) => setState(() => _photo = photo),
                  onCapturing: (value) => setState(() => _picking = value))
              : null,
          onCamera: _captureOrRetake,
          onGallery: () => _pick(ImageSource.gallery),
          onAnalyze: _analyze,
          onPortion: (value) => setState(() => _portion = value),
          onHistory: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => MealHistoryScreen(
                      clientID: widget.clientID, token: widget.token))),
          frameOverlay: const CustomPaint(painter: _ScanCorners()),
        ),
      ));
}

class _ScanCorners extends CustomPainter {
  const _ScanCorners();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _cream
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    const inset = 22.0, length = 24.0;
    for (final point in [
      const Offset(inset, inset),
      Offset(size.width - inset, inset),
      Offset(inset, size.height - inset),
      Offset(size.width - inset, size.height - inset)
    ]) {
      final dx = point.dx < size.width / 2 ? length : -length;
      final dy = point.dy < size.height / 2 ? length : -length;
      canvas.drawPath(
          Path()
            ..moveTo(point.dx + dx, point.dy)
            ..lineTo(point.dx, point.dy)
            ..lineTo(point.dx, point.dy + dy),
          paint);
    }
  }

  @override
  bool shouldRepaint(_ScanCorners oldDelegate) => false;
}

class MealResultScreen extends StatefulWidget {
  final ScannedMeal meal;
  final int clientID;
  final String token;
  final bool initiallySaved;
  final NutritionDiaryService? service;
  const MealResultScreen(
      {super.key,
      required this.meal,
      required this.clientID,
      this.token = '',
      this.initiallySaved = false,
      this.service});
  @override
  State<MealResultScreen> createState() => _MealResultScreenState();
}

class _MealResultScreenState extends State<MealResultScreen> {
  bool _saving = false, _choosing = false;
  bool _saved = false;
  bool _pending = false;
  late final NutritionDiaryService _service;
  bool get _busy => _saving || _choosing;
  @override
  void initState() {
    super.initState();
    _saved = widget.initiallySaved;
    _service =
        widget.service ?? NutritionDiaryService(widget.clientID, widget.token);
  }

  @override
  void dispose() {
    if (widget.service == null) _service.close();
    super.dispose();
  }

  ScannedMeal get meal => widget.meal;
  Future<void> _edit(int? index) async {
    final original = index == null ? null : meal.ingredients[index];
    final ingredient = await showModalBottomSheet<MealIngredient>(
        context: context,
        backgroundColor: _background,
        isScrollControlled: true,
        builder: (_) => Theme(
            data: _mealTheme(),
            child: _IngredientEditor(ingredient: original)));
    if (ingredient != null && mounted) {
      setState(() {
        if (index == null) {
          meal.ingredients.add(ingredient);
        } else {
          meal.ingredients[index] = ingredient;
        }
      });
    }
  }

  Future<void> _save({bool moving = false}) async {
    if (_busy) return;
    setState(() => _choosing = true);
    final type = await chooseMealCategory(context,
        initialType: meal.mealType, moving: moving);
    if (!mounted) return;
    setState(() => _choosing = false);
    if (type == null) return;
    setState(() {
      meal.mealType = type;
      _saving = true;
      _pending = true;
    });
    try {
      await _service.save(meal);
      if (mounted) {
        setState(() {
          _saved = true;
          _pending = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                '${moving ? 'Meal moved' : 'Meal saved'} to ${mealTypeLabel(type)}.')));
      }
    } catch (e) {
      if (mounted) _error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_busy || !await confirmMealDeletion(context, meal.name) || !mounted) {
      return;
    }
    setState(() => _saving = true);
    try {
      await _service.delete(meal);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _error(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
      data: _mealTheme(),
      child: MealResultView(
        meal: meal,
        saving: _saving,
        saved: _saved,
        onSave: () => _save(),
        onEdit: _edit,
        diaryControls: Column(children: [
          if (_saved)
            Row(children: [
              Expanded(
                  child: Text(
                      '${_pending ? 'Not synced ·' : 'Saved in'} ${mealTypeLabel(meal.mealType)}',
                      style: const TextStyle(
                          color: _cream, fontWeight: FontWeight.w700))),
              TextButton.icon(
                  onPressed: _busy ? null : () => _save(moving: true),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: const Text('Move meal')),
            ])
          else
            const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                    'Choose Breakfast, Lunch, Dinner or Snack when you save.',
                    style: TextStyle(color: _muted, fontSize: 12))),
          const SizedBox(height: 8),
          if (_pending && !_saving)
            const Text('Changes have not synced. Save again to retry.',
                style: TextStyle(color: _muted, fontSize: 12)),
          TextButton.icon(
              onPressed: _busy
                  ? null
                  : () async {
                      final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.parse(meal.mealDate),
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now());
                      if (date != null && mounted) {
                        setState(
                            () => meal.mealDate = ScannedMeal.dayKey(date));
                      }
                    },
              icon: const Icon(Icons.calendar_today_outlined, size: 16),
              label: Text('Meal date · ${meal.mealDate}')),
          if (_saved)
            OutlinedButton.icon(
                onPressed: _busy ? null : _delete,
                icon: const Icon(Icons.delete_outline_rounded),
                label: const Text('Delete meal')),
        ]),
        onRemove: (index) => setState(() => meal.ingredients.removeAt(index)),
      ));
}

class _IngredientEditor extends StatefulWidget {
  final MealIngredient? ingredient;
  const _IngredientEditor({this.ingredient});
  @override
  State<_IngredientEditor> createState() => _IngredientEditorState();
}

class _IngredientEditorState extends State<_IngredientEditor> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name, _grams;
  late final List<TextEditingController> _macros;
  bool get _manual => widget.ingredient?.grams == 0;
  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.ingredient?.name ?? '');
    _grams = TextEditingController(
        text: widget.ingredient?.grams.toStringAsFixed(1) ?? '');
    _macros = List.generate(
        4,
        (index) => TextEditingController(
            text: _manual
                ? '${widget.ingredient!.toJson()[nutritionKeys[index]]}'
                : ''));
  }

  @override
  void dispose() {
    _name.dispose();
    _grams.dispose();
    for (final c in _macros) {
      c.dispose();
    }
    super.dispose();
  }

  double _value(TextEditingController c) =>
      double.parse(c.text.replaceAll(',', '.'));
  Widget _number(TextEditingController controller, String label,
          {bool positive = false}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextFormField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: label),
              validator: (value) {
                final n = double.tryParse((value ?? '').replaceAll(',', '.'));
                return n == null ||
                        !n.isFinite ||
                        n < 0 ||
                        (positive && n == 0) ||
                        n > 10000
                    ? 'Enter a valid ${positive ? 'positive ' : ''}number'
                    : null;
              }));
  @override
  Widget build(BuildContext context) => Padding(
      padding: EdgeInsets.fromLTRB(
          20, 24, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
      child: SingleChildScrollView(
          child: Form(
              key: _form,
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        widget.ingredient == null
                            ? 'Add ingredient'
                            : 'Adjust portion',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    TextFormField(
                        controller: _name,
                        readOnly: widget.ingredient != null && !_manual,
                        maxLength: 120,
                        decoration:
                            InputDecoration(labelText: 'Ingredient'),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Enter an ingredient name'
                            : null),
                    if (!_manual) _number(_grams, 'Weight (g)', positive: true),
                    if (widget.ingredient != null && !_manual)
                      const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: Text(
                              'Calories and macros scale with the weight.',
                              style: TextStyle(color: _muted)))
                    else ...[
                      const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text(
                              'Enter nutrition for this amount from a label or recipe.',
                              style: TextStyle(color: _muted))),
                      for (var i = 0; i < 4; i++)
                        _number(
                            _macros[i],
                            [
                              'Calories (kcal)',
                              'Protein (g)',
                              'Carbs (g)',
                              'Fat (g)'
                            ][i]),
                    ],
                    _primary('Apply', () {
                      if (!_form.currentState!.validate()) return;
                      final ingredient = (widget.ingredient != null && !_manual
                              ? widget.ingredient!.withGrams(_value(_grams))
                              : null) ??
                          MealIngredient(
                              name: _name.text.trim(),
                              grams: _manual ? 0 : _value(_grams),
                              quantity: _manual ? '1 serving' : '',
                              calories: _value(_macros[0]),
                              protein: _value(_macros[1]),
                              carbs: _value(_macros[2]),
                              fat: _value(_macros[3]));
                      Navigator.pop(context, ingredient);
                    }),
                  ]))));
}

class MealHistoryScreen extends StatelessWidget {
  final int clientID;
  final String token;
  const MealHistoryScreen({super.key, required this.clientID, this.token = ''});
  @override
  Widget build(BuildContext context) =>
      NutritionTrackerScreen(clientID: clientID, token: token);
}
