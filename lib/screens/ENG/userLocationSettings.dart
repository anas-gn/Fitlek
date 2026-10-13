import 'package:geolocator/geolocator.dart';
import '../../services/background_location_service.dart';
import 'package:flutter/material.dart';
import '../../components/location_picker.dart';
import '../../services/apiService.dart';
import '../../services/user_location_service.dart';

class UserLocationSettings extends StatefulWidget {
  final bool forSignup;
  const UserLocationSettings({super.key, this.forSignup = false});
  @override
  State<UserLocationSettings> createState() => _UserLocationSettingsState();
}

class _UserLocationSettingsState extends State<UserLocationSettings> {
  late final Future<Map<String, dynamic>> _initial;
  Map<String, dynamic>? _location;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _initial = widget.forSignup
        ? Future.value({'ok': true})
        : ApiService.get('/locations/me');
  }

  Future<void> _save() async {
    if (_location == null) return;
    if ('${_location!['city'] ?? ''}'.trim().isEmpty || _location!['latitude'] == null || _location!['longitude'] == null) {
      setState(() => _error = 'Press Use my current location to detect and fill your location.');
      return;
    }
    if (widget.forSignup) {
      Navigator.pop(context, _location);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final city = await UserLocationService.save(_location!);
      if (mounted) Navigator.pop(context, city);
    } catch (error) {
      if (mounted)
        setState(() => _error = '$error'.replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('My location')),
      body: FutureBuilder<Map<String, dynamic>>(
          future: _initial,
          builder: (context, snapshot) {
            if (!snapshot.hasData)
              return const Center(child: CircularProgressIndicator());
            if (snapshot.data?['ok'] != true)
              return const Center(
                  child: Text(
                      'Could not load your location. Please reopen this screen.'));
            _location ??= Map<String, dynamic>.from(snapshot.data!);
            return Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 540),
                    child:
                        ListView(padding: const EdgeInsets.all(24), children: [
                      LocationPicker(
                          initial: _location,
                          onChanged: (value) =>
                              setState(() => _location = value)),
                      if (!widget.forSignup && BackgroundLocationService.supported)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.location_on_outlined),
                          title: const Text('Allow background updates'),
                          subtitle: const Text('To update distances while the app is closed, choose Always allow in your phone location settings. Updates target every 15 minutes; your phone may delay them. Keep location updates switched on, then save.'),
                          onTap: () async { await Geolocator.openAppSettings(); },
                        ),
                      if (_error != null)
                        Text(_error!,
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.error)),
                      const SizedBox(height: 20),
                      FilledButton(
                          onPressed: _saving ? null : _save,
                          child: Text(_saving
                              ? 'Saving…'
                              : widget.forSignup
                                  ? 'Continue'
                                  : 'Save location')),
                    ])));
          }));
}
