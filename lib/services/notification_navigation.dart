import '../screens/ENG/coachInviteClients.dart';
import 'campaign_service.dart';
import 'package:flutter/material.dart';
import 'apiService.dart';
import '../models/anas/reservation.dart';
import '../models/coachConversation.dart';
import '../screens/ENG/coachCalendar.dart';
import '../screens/ENG/coachChat.dart';
import '../screens/ENG/coachInvitations.dart';
import '../screens/ENG/coachProfile.dart';
import '../screens/ENG/clientCoachReviews.dart';
import '../screens/ENG/clientConversation.dart';
import '../screens/ENG/clientConversationList.dart';
import '../screens/ENG/clientSessionDetail.dart';

class NotificationNavigation {
  static Future<void> open(
      BuildContext context, Map<String, dynamic> item) async {
    final role = await ApiService.getRole();
    final user = await ApiService.getUserData();
    final token = await ApiService.getToken();
    if (!context.mounted || user == null || token == null) return;
    final coach = role == 'coach';
    final type = '${item['type'] ?? ''}';
    final id = '${item['relatedEntityID'] ?? ''}';
    if (type == 'app_campaign') {
      await CampaignService.openNotification(context, id);
      return;
    }
    Widget? screen;
    if (type == 'new_message' && int.tryParse(id) != null) {
      screen = coach
          ? CoachChat(
              conversation: CoachConversation(
                  id: id,
                  clientId: '',
                  clientName: '${item['actorName'] ?? 'Client'}',
                  clientPhotoUrl: '${item['actorAvatar'] ?? ''}',
                  lastMessage: '',
                  lastMessageTime: DateTime.now(),
                  unreadCount: 0))
          : ClientConversationScreen(
              conversationID: int.parse(id),
              clientID: int.parse('${user['id']}'),
              token: token,
              coachName: item['actorName']?.toString(),
              coachAvatar: item['actorAvatar']?.toString());
    } else if (type.startsWith('price_') ||
        type.startsWith('reservation_') ||
        type == 'new_reservation' ||
        type == 'upcoming_session') {
      if (coach) {
        screen = CoachCalendar(reservationId: id);
      } else {
        final result = await ApiService.get('/reservations/$id/details');
        if (!context.mounted) return;
        if (result['ok'] == true) {
          screen = SessionDetailScreen(
              session: ReservationModel.fromJson(result),
              clientID: int.parse('${user['id']}'),
              token: token);
        }
      }
    } else if (coach && type == 'referral_signup') {
      screen = const CoachInviteClients();
    } else if (type.contains('invitation') || type == 'new_client') {
      if (coach) {
        screen = const CoachInvitations();
      } else {
        final result =
            await ApiService.get('/reservations/invitations/$id/details');
        if (!context.mounted) return;
        final conversationID = int.tryParse('${result['conversationID']}');
        if (result['ok'] == true && conversationID != null) {
          screen = ClientConversationScreen(
              conversationID: conversationID,
              clientID: int.parse('${user['id']}'),
              token: token,
              coachName: item['actorName']?.toString());
        } else {
          screen = ClientConversationsListScreen(
              clientID: int.parse('${user['id']}'), token: token);
        }
      }
    } else if (coach && type == 'new_review') {
      screen = ClientCoachReviewsScreen(
          coachID: int.parse('${user['id']}'),
          coachName: '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}',
          clientID: 0,
          token: token,
          coachView: true);
    } else if (coach && (type.contains('verif') || type.contains('approv'))) {
      screen = CoachProfile(
          coachID: int.parse('${user['id']}'),
          firstName: '${user['firstName'] ?? ''}',
          lastName: '${user['lastName'] ?? ''}',
          token: token);
    }
    if (!context.mounted) return;
    if (screen == null) {
      await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
                title: Text('${item['title'] ?? 'Notification'}'),
                content: Text(
                    '${item['body'] ?? 'This item is no longer available.'}'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Close'))
                ],
              ));
      return;
    }
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => screen!));
  }
}
