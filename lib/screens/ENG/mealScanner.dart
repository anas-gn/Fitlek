import 'dart:async';
import '../../components/meal_diary_actions.dart';
import '../../components/meal_live_camera.dart';
import '../../components/meal_scan_limit_dialog.dart';
import '../../components/meal_visuals.dart';
import '../../components/meal_scanner_view.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/media_picker_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/food_nutrition_service.dart';
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
  final _searchCtrl = TextEditingController();
  final _gramsCtrl = TextEditingController(text: '100');
  late final TextEditingController _nameCtrl;
  late final List<TextEditingController> _macrosCtrl;

  FoodItem? _selectedFood;
  List<FoodItem> _searchResults = [];
  bool _searchingOnline = false;
  String _selectedCategory = 'all';
  String _unit = 'g'; // 'g' or 'kg'
  bool _manualOverride = false;
  Timer? _debounceTimer;
  String _lastSearchedOnlineQuery = '';

  bool get _isEditMode => widget.ingredient != null;

  double get _currentGrams {
    final val = double.tryParse(_gramsCtrl.text.replaceAll(',', '.')) ?? 0.0;
    return _unit == 'kg' ? val * 1000.0 : val;
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.ingredient?.name ?? '');
    _macrosCtrl = List.generate(
      4,
      (index) => TextEditingController(
        text: widget.ingredient != null
            ? '${widget.ingredient!.toJson()[nutritionKeys[index]]}'
            : '0.0',
      ),
    );

    if (widget.ingredient != null) {
      final grams = widget.ingredient!.grams;
      _gramsCtrl.text = grams > 0 ? grams.toStringAsFixed(0) : '100';
      // Attempt to link to known food item
      _initExistingFood();
    } else {
      _loadInitialFoods();
    }

    _gramsCtrl.addListener(_onWeightChanged);
  }

  void _onWeightChanged() {
    if (_selectedFood != null && !_manualOverride) {
      _recalcMacros();
    }
  }

  Future<void> _initExistingFood() async {
    await FoodNutritionService.instance.init();
    if (!mounted) return;
    final name = widget.ingredient?.name ?? '';
    final results = FoodNutritionService.instance.searchLocal(name, limit: 5);
    if (results.isNotEmpty) {
      setState(() => _selectedFood = results.first);
    }
  }

  Future<void> _loadInitialFoods() async {
    await FoodNutritionService.instance.init();
    if (!mounted) return;
    setState(() {
      _searchResults = FoodNutritionService.instance
          .searchLocal('', category: _selectedCategory, limit: 12);
    });
  }

  void _onSearch(String query) {
    _debounceTimer?.cancel();
    final q = query.trim();
    final local = FoodNutritionService.instance
        .searchLocal(q, category: _selectedCategory, limit: 15);
    setState(() {
      _searchResults = local;
    });

    // Auto-search online if query has >= 2 characters and local has few matches (< 2)
    if (q.length >= 2 && local.length < 2) {
      if (q.toLowerCase() != _lastSearchedOnlineQuery.toLowerCase()) {
        _debounceTimer = Timer(const Duration(milliseconds: 500), () {
          _searchOnline(auto: true);
        });
      }
    }
  }

  Future<void> _searchOnline({bool auto = false, bool force = false}) async {
    _debounceTimer?.cancel();
    final q = _searchCtrl.text.trim();
    if (q.length < 2 || _searchingOnline) return;
    if (!force &&
        q.toLowerCase() == _lastSearchedOnlineQuery.toLowerCase() &&
        _searchResults.any((e) => e.isOnline)) {
      return;
    }
    _lastSearchedOnlineQuery = q;
    setState(() => _searchingOnline = true);
    try {
      final online =
          await FoodNutritionService.instance.searchOnline(q, limit: 12);
      if (!mounted) return;
      setState(() {
        final existingNames =
            _searchResults.map((e) => e.name.toLowerCase().trim()).toSet();
        for (final item in online) {
          if (!existingNames.contains(item.name.toLowerCase().trim())) {
            _searchResults.add(item);
          }
        }
      });
    } catch (e) {
      debugPrint('Online food search error: $e');
    } finally {
      if (mounted) setState(() => _searchingOnline = false);
    }
  }

  void _selectFood(FoodItem food) {
    setState(() {
      _selectedFood = food;
      _nameCtrl.text = food.name;
      _manualOverride = false;
      _recalcMacros();
    });
  }

  void _recalcMacros() {
    if (_selectedFood == null) return;
    final factor = _currentGrams / 100.0;
    _macrosCtrl[0].text =
        (_selectedFood!.calories * factor).toStringAsFixed(1);
    _macrosCtrl[1].text =
        (_selectedFood!.protein * factor).toStringAsFixed(1);
    _macrosCtrl[2].text =
        (_selectedFood!.carbs * factor).toStringAsFixed(1);
    _macrosCtrl[3].text =
        (_selectedFood!.fat * factor).toStringAsFixed(1);
    setState(() {});
  }

  void _setWeight(double grams) {
    if (_unit == 'kg') {
      _gramsCtrl.text = (grams / 1000.0).toStringAsFixed(2);
    } else {
      _gramsCtrl.text = grams.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchCtrl.dispose();
    _gramsCtrl.removeListener(_onWeightChanged);
    _gramsCtrl.dispose();
    _nameCtrl.dispose();
    for (final c in _macrosCtrl) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _foodThumbnail(FoodItem food, {double size = 44}) {
    if (food.localImage != null && food.localImage!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.asset(
          'assets/ingredients/${food.localImage}',
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) =>
              _categoryPlaceholder(food.category, size: size),
        ),
      );
    }
    if (food.remoteImageUrl != null && food.remoteImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: CachedNetworkImage(
          imageUrl: food.remoteImageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) =>
              _categoryPlaceholder(food.category, size: size),
          errorWidget: (_, __, ___) =>
              _categoryPlaceholder(food.category, size: size),
        ),
      );
    }
    if (food.emoji != null && food.emoji!.isNotEmpty) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: const Color(0xFF1B3B36),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(food.emoji!, style: TextStyle(fontSize: size * 0.55)),
      );
    }
    return _categoryPlaceholder(food.category, size: size);
  }

  Widget _categoryPlaceholder(String category, {double size = 44}) {
    IconData icon;
    switch (category.toLowerCase()) {
      case 'meat':
        icon = Icons.kebab_dining_rounded;
        break;
      case 'produce':
        icon = Icons.eco_rounded;
        break;
      case 'dairy':
        icon = Icons.local_drink_rounded;
        break;
      case 'bakery':
      case 'grains':
        icon = Icons.bakery_dining_rounded;
        break;
      case 'seafood':
        icon = Icons.set_meal_rounded;
        break;
      case 'nuts':
      case 'legumes':
        icon = Icons.grain_rounded;
        break;
      case 'beverage':
        icon = Icons.local_cafe_rounded;
        break;
      case 'snacks':
        icon = Icons.cookie_rounded;
        break;
      case 'dishes':
        icon = Icons.dinner_dining_rounded;
        break;
      default:
        icon = Icons.restaurant_rounded;
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF1B3B36),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: _cream, size: size * 0.55),
    );
  }

  Widget _buildSearchSection() {
    final categories = [
      ('all', 'All'),
      ('meat', 'Meat'),
      ('produce', 'Produce'),
      ('dairy', 'Dairy'),
      ('grains', 'Grains'),
      ('seafood', 'Fish'),
      ('nuts', 'Nuts'),
      ('dishes', 'Meals'),
      ('snacks', 'Snacks'),
      ('beverage', 'Drinks'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search Input
        TextField(
          controller: _searchCtrl,
          onChanged: _onSearch,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _searchOnline(force: true),
          decoration: InputDecoration(
            hintText: 'Search food (e.g. Chicken, Apple, Rice)...',
            prefixIcon: const Icon(Icons.search_rounded, color: _muted),
            suffixIcon: _searchingOnline
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _cream),
                    ),
                  )
                : _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _debounceTimer?.cancel();
                          _searchCtrl.clear();
                          _onSearch('');
                        },
                      )
                    : null,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        const SizedBox(height: 10),

        // Category Filter Chips
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, index) {
              final cat = categories[index];
              final isSelected = _selectedCategory == cat.$1;
              return FilterChip(
                label: Text(cat.$2,
                    style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? _background : _cream)),
                selected: isSelected,
                selectedColor: _cream,
                backgroundColor: _card,
                showCheckmark: false,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: isSelected ? _cream : _muted.withValues(alpha: 0.3),
                  ),
                ),
                onSelected: (_) {
                  setState(() => _selectedCategory = cat.$1);
                  _onSearch(_searchCtrl.text);
                },
              );
            },
          ),
        ),
        const SizedBox(height: 12),

        // Online search progress banner
        if (_searchingOnline && _searchResults.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.lightBlueAccent,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Searching Open Food Facts online...',
                  style: TextStyle(
                    color: Colors.lightBlueAccent.withValues(alpha: 0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

        // Search Results List
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: _searchResults.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_searchingOnline) ...[
                          const SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: _cream),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Searching Open Food Facts for "${_searchCtrl.text}"...',
                            style: const TextStyle(
                                color: _cream,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Querying Open Food Facts global database',
                            style: TextStyle(color: _muted, fontSize: 11),
                          ),
                        ] else ...[
                          const Icon(Icons.search_off_rounded,
                              color: _muted, size: 36),
                          const SizedBox(height: 8),
                          Text('No foods found for "${_searchCtrl.text}"',
                              style:
                                  const TextStyle(color: _muted, fontSize: 13)),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () => _searchOnline(force: true),
                            icon: const Icon(Icons.travel_explore_rounded,
                                size: 16),
                            label: const Text('Search Open Food Facts'),
                          ),
                        ],
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: _searchResults.length + 1,
                  separatorBuilder: (_, __) =>
                      Divider(color: _muted.withValues(alpha: 0.12), height: 1),
                  itemBuilder: (_, idx) {
                    if (idx == _searchResults.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextButton.icon(
                          onPressed: _searchingOnline
                              ? null
                              : () => _searchOnline(force: true),
                          icon: _searchingOnline
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2))
                              : const Icon(Icons.travel_explore_rounded,
                                  size: 18),
                          label: Text(_searchingOnline
                              ? 'Searching Open Food Facts...'
                              : 'Search more online (Open Food Facts)'),
                        ),
                      );
                    }
                    final food = _searchResults[idx];
                    return ListTile(
                      dense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: _foodThumbnail(food, size: 40),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              food.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600, fontSize: 14),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (food.isOnline)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Online',
                                  style: TextStyle(
                                      color: Colors.lightBlueAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        '${food.calories.round()} kcal · ${food.protein}g P · ${food.carbs}g C · ${food.fat}g F (per 100g)',
                        style: const TextStyle(color: _muted, fontSize: 11),
                      ),
                      trailing: const Icon(Icons.add_circle_outline_rounded,
                          color: _cream, size: 22),
                      onTap: () => _selectFood(food),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSelectedFoodCard() {
    final food = _selectedFood!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cream.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _foodThumbnail(food, size: 52),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Base: ${food.calories.round()} kcal · ${food.protein}g P · ${food.carbs}g C · ${food.fat}g F / 100g',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          if (!_isEditMode)
            IconButton(
              icon: const Icon(Icons.swap_horiz_rounded, color: _cream),
              tooltip: 'Choose different food',
              onPressed: () => setState(() => _selectedFood = null),
            ),
        ],
      ),
    );
  }

  Widget _buildMacroChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          children: [
            Text(label,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedFood = _selectedFood != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEditMode ? 'Adjust portion' : 'Add food item',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Step 1: If no food selected and not editing, show 2-tier search
              if (!hasSelectedFood && !_isEditMode) ...[
                _buildSearchSection(),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _selectedFood = const FoodItem(
                          id: 'custom',
                          name: 'Custom food',
                          calories: 0,
                          protein: 0,
                          carbs: 0,
                          fat: 0);
                      _manualOverride = true;
                    }),
                    child: const Text('Or enter custom macros manually',
                        style: TextStyle(color: _muted, fontSize: 12)),
                  ),
                ),
              ],

              // Step 2: Food is selected -> Quantity & Auto-Calculated Nutrition
              if (hasSelectedFood || _isEditMode) ...[
                if (hasSelectedFood) _buildSelectedFoodCard(),
                const SizedBox(height: 16),

                // Weight input + Unit Switcher
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _gramsCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Quantity ($_unit)',
                          prefixIcon: const Icon(Icons.scale_rounded, size: 20),
                        ),
                        validator: (value) {
                          final n = double.tryParse(
                              (value ?? '').replaceAll(',', '.'));
                          return n == null || !n.isFinite || n <= 0 || n > 50000
                              ? 'Enter a valid weight'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Unit selector (g / kg)
                    Container(
                      height: 56,
                      decoration: BoxDecoration(
                        color: _card,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: _muted.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ChoiceChip(
                            label: const Text('g'),
                            selected: _unit == 'g',
                            onSelected: (_) => setState(() {
                              final current = _currentGrams;
                              _unit = 'g';
                              _setWeight(current);
                            }),
                            showCheckmark: false,
                            selectedColor: _cream,
                            labelStyle: TextStyle(
                              color: _unit == 'g' ? _background : _cream,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          ChoiceChip(
                            label: const Text('kg'),
                            selected: _unit == 'kg',
                            onSelected: (_) => setState(() {
                              final current = _currentGrams;
                              _unit = 'kg';
                              _setWeight(current);
                            }),
                            showCheckmark: false,
                            selectedColor: _cream,
                            labelStyle: TextStyle(
                              color: _unit == 'kg' ? _background : _cream,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Quick weight presets
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [50.0, 100.0, 150.0, 200.0, 300.0]
                        .map((grams) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text('${grams.round()}g',
                                    style: const TextStyle(fontSize: 12)),
                                backgroundColor: _card,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: BorderSide(
                                      color: _muted.withValues(alpha: 0.25)),
                                ),
                                onPressed: () {
                                  setState(() => _setWeight(grams));
                                },
                              ),
                            ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 16),

                // Real-time Calculated Nutrition Cards
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A221E),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _cream.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Calculated Nutrition',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _muted),
                          ),
                          Row(
                            children: [
                              Text(
                                '${_macrosCtrl[0].text} kcal',
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _cream),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildMacroChip('Protein', '${_macrosCtrl[1].text}g',
                              const Color(0xFF64B5F6)),
                          const SizedBox(width: 8),
                          _buildMacroChip('Carbs', '${_macrosCtrl[2].text}g',
                              const Color(0xFFFFB74D)),
                          const SizedBox(width: 8),
                          _buildMacroChip('Fat', '${_macrosCtrl[3].text}g',
                              const Color(0xFFE57373)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Manual Override Expander
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _manualOverride
                          ? 'Manual values active'
                          : 'Values auto-calculated',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _manualOverride = !_manualOverride;
                          if (!_manualOverride && _selectedFood != null) {
                            _recalcMacros();
                          }
                        });
                      },
                      child: Text(
                        _manualOverride
                            ? 'Reset to Auto'
                            : 'Edit macros manually',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),

                if (_manualOverride) ...[
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Custom Food Name'),
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Enter a food name'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: TextFormField(
                              controller: _macrosCtrl[0],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Calories (kcal)'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: TextFormField(
                              controller: _macrosCtrl[1],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Protein (g)'))),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                          child: TextFormField(
                              controller: _macrosCtrl[2],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Carbs (g)'))),
                      const SizedBox(width: 8),
                      Expanded(
                          child: TextFormField(
                              controller: _macrosCtrl[3],
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                  labelText: 'Fat (g)'))),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Apply Button
                _primary(_isEditMode ? 'Save changes' : 'Add to meal', () {
                  if (!_form.currentState!.validate()) return;
                  final grams = _currentGrams;

                  MealIngredient result;
                  if (_selectedFood != null && !_manualOverride) {
                    result = _selectedFood!.toIngredient(grams: grams);
                  } else if (widget.ingredient != null && !_manualOverride) {
                    result = widget.ingredient!.withGrams(grams);
                  } else {
                    result = MealIngredient(
                      name: _nameCtrl.text.trim().isEmpty
                          ? (_selectedFood?.name ?? 'Custom item')
                          : _nameCtrl.text.trim(),
                      grams: grams,
                      quantity: '${grams.round()} g',
                      calories: double.tryParse(_macrosCtrl[0].text) ?? 0.0,
                      protein: double.tryParse(_macrosCtrl[1].text) ?? 0.0,
                      carbs: double.tryParse(_macrosCtrl[2].text) ?? 0.0,
                      fat: double.tryParse(_macrosCtrl[3].text) ?? 0.0,
                      imageKey: _selectedFood?.localImage != null
                          ? _selectedFood!.localImage!.replaceAll('.webp', '')
                          : 'generic',
                      imageUrl: _selectedFood?.remoteImageUrl ?? '',
                    );
                  }

                  Navigator.pop(context, result);
                }),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class MealHistoryScreen extends StatelessWidget {
  final int clientID;
  final String token;
  const MealHistoryScreen({super.key, required this.clientID, this.token = ''});
  @override
  Widget build(BuildContext context) =>
      NutritionTrackerScreen(clientID: clientID, token: token);
}
