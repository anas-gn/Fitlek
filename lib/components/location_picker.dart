import 'package:flutter/material.dart';
import '../services/user_location_service.dart';

class LocationPicker extends StatefulWidget {
  final Map<String, dynamic>? initial;
  final ValueChanged<Map<String, dynamic>> onChanged;
  const LocationPicker({super.key, this.initial, required this.onChanged});
  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class _LocationPickerState extends State<LocationPicker> {
  late final TextEditingController _city;
  late final TextEditingController _address;
  bool _busy = false;
  bool _auto = false;
  Map<String, dynamic>? _gps;
  String? _error;
  @override
  void initState() {
    super.initState();
    _city = TextEditingController(text: '${widget.initial?['city'] ?? ''}');
    _address =
        TextEditingController(text: '${widget.initial?['fullAddress'] ?? ''}');
    _gps = widget.initial;
    _auto = widget.initial?['autoRefresh'] == true ||
        widget.initial?['autoRefresh'] == 1;
  }

  @override
  void dispose() {
    _city.dispose();
    _address.dispose();
    super.dispose();
  }

  void _emit() {
    widget.onChanged({
      ...?_gps,
      'city': _city.text.trim(),
      'fullAddress': _address.text.trim(),
      'autoRefresh': _auto
    });
  }

  Future<void> _detect() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final location = await UserLocationService.detect();
      if (!mounted) return;
      setState(() {
        _gps = location;
        _city.text = '${location['city']}';
        _address.text = '${location['fullAddress']}';
        _auto = true;
      });
      _emit();
    } catch (error) {
      if (mounted)
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        OutlinedButton.icon(
            onPressed: _busy ? null : _detect,
            icon: const Icon(Icons.my_location),
            label:
                Text(_busy ? 'Finding your city…' : 'Use my current location')),
        const SizedBox(height: 10),
        TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: 'City'),
            readOnly: true,
            enableInteractiveSelection: false),
        const SizedBox(height: 10),
        TextField(
            controller: _address,
            decoration:
                const InputDecoration(labelText: 'Detected address (private)'),
            readOnly: true,
            enableInteractiveSelection: false),
        const SizedBox(height: 8),
        const Text(
            'Use the location button to fill these fields automatically. Only your city appears to other users. Your detailed address and coordinates stay private.'),
        if (_gps?['latitude'] != null)
          SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keep my location updated'),
              subtitle:
                  const Text('Refresh every 15 minutes. Background updates require Always allow permission.'),
              value: _auto,
              onChanged: (value) {
                setState(() => _auto = value);
                _emit();
              }),
        if (_error != null)
          Text(_error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
      ]);
}
