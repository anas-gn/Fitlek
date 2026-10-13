import 'package:flutter/material.dart';
import 'apiService.dart';
import 'campaign_service.dart';
import 'referral_link_service.dart';
import '../screens/ENG/clientQrScanner.dart';

class CoachQrNavigation {
  static Future<int?> resolveCoachId(String scanned,
      {Future<Map<String, dynamic>> Function(String)? get}) async {
    final code = ReferralLinkService.codeFromQr(scanned);
    if (code == null) return null;
    final result = await (get ?? ApiService.get)(
        '/coaches?invitationCode=${Uri.encodeQueryComponent(code)}&limit=1');
    if (result['ok'] != true) {
      throw Exception(
          result['message'] ?? 'Unable to find the coach. Please try again.');
    }
    final rows = result['data'];
    if (rows is! List || rows.isEmpty) return null;
    return int.tryParse('${rows.first['id']}');
  }

  static Future<void> scanAndOpen(BuildContext context) async {
    final scanned = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const ClientQrScannerScreen()));
    if (!context.mounted || scanned == null) return;
    try {
      final id = await resolveCoachId(scanned);
      if (!context.mounted) return;
      if (id == null || id <= 0) {
        ApiService.showError(
            context, 'No available coach found for this QR code.');
        return;
      }
      await CampaignService.openDestination(context, '/coaches/$id');
    } catch (_) {
      if (context.mounted) {
        ApiService.showError(context,
            'Unable to load the coach. Check your connection and try again.');
      }
    }
  }
}
