import 'package:flutter/material.dart';
import '../../services/apiService.dart';

class PremiumProgressScreen extends StatefulWidget {
  const PremiumProgressScreen({super.key});

  @override
  State<PremiumProgressScreen> createState() => _PremiumProgressScreenState();
}

class _PremiumProgressScreenState extends State<PremiumProgressScreen> {
  bool _loading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _weights = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      ApiService.get('/premium/workouts/stats'),
      ApiService.get('/premium/workouts/body-weight'),
    ]);
    if (!mounted) return;
    setState(() {
      _stats = results[0]['ok'] == true ? Map<String, dynamic>.from(results[0]) : {};
      _weights = results[1]['ok'] == true && results[1]['data'] is List ? results[1]['data'] as List : [];
      _loading = false;
    });
  }

  Future<void> _addWeight() async {
    final controller = TextEditingController();
    final value = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record body weight'),
        content: TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Weight in kg')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, double.tryParse(controller.text)), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    final result = await ApiService.post('/premium/workouts/body-weight', {'weight': value, 'unit': 'kg'});
    if (!mounted) return;
    if (result['ok'] != true) {
      ApiService.showError(context, result['message']?.toString() ?? 'Unable to save weight.');
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Row(children: [
                  Expanded(child: _StatCard(label: 'Workouts', value: '${_stats['workoutCount'] ?? 0}')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Sets', value: '${_stats['setCount'] ?? 0}')),
                ]),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: _StatCard(label: 'Volume', value: '${_stats['totalVolume'] ?? 0} kg')),
                  const SizedBox(width: 10),
                  Expanded(child: _StatCard(label: 'Heaviest', value: '${_stats['heaviestSet'] ?? 0} kg')),
                ]),
                const SizedBox(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Body weight', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    IconButton(onPressed: _addWeight, icon: const Icon(Icons.add_rounded)),
                  ],
                ),
                if (_weights.isEmpty)
                  const Text('No body-weight entries yet.')
                else
                  ..._weights.take(20).map((entry) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.monitor_weight_outlined),
                    title: Text('${entry['weight']} ${entry['unit']}'),
                    subtitle: Text('${entry['recordedAt'] ?? ''}'),
                  )),
              ],
            ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label),
        ]),
      ),
    );
  }
}
