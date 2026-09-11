import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../theme/fitlek_theme_extension.dart';
import 'package:fitlek1/constants/urls.dart' as urls;

class ApiConfig {
  static const String baseUrl = urls.baseUrl;
}

class BlockedUsersList extends StatefulWidget {
  final String token;

  const BlockedUsersList({super.key, required this.token});

  @override
  State<BlockedUsersList> createState() => _BlockedUsersListState();
}

class _BlockedUsersListState extends State<BlockedUsersList> {
  bool _loading = true;
  String? _error;
  List<dynamic> _blockedUsers = [];

  @override
  void initState() {
    super.initState();
    _fetchBlockedUsers();
  }

  Future<void> _fetchBlockedUsers() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/ugc/blocked'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _blockedUsers = jsonDecode(res.body) as List<dynamic>;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load blocked users';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
        _loading = false;
      });
    }
  }

  Future<void> _unblockUser(int blockedID, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.fitlek.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Unblock $name?', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
        content: Text(
          'They will be able to see your profile and send you messages again.',
          style: TextStyle(color: context.fitlek.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: context.fitlek.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Unblock', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/ugc/unblock'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'blockedID': blockedID}),
      );

      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$name has been unblocked'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
        _fetchBlockedUsers(); // Refresh the list
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to unblock user'),
              backgroundColor: context.fitlek.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: $e'),
            backgroundColor: context.fitlek.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final f = context.fitlek;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Blocked Users',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: cs.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, color: f.error, size: 48),
                      const SizedBox(height: 16),
                      Text(_error!, style: TextStyle(color: f.textMuted)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchBlockedUsers,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
                          foregroundColor: cs.onPrimary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _blockedUsers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.block_rounded, color: f.border, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'No blocked users',
                            style: TextStyle(color: cs.onSurface, fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'When you block someone, they will appear here.',
                            style: TextStyle(color: f.textMuted, fontSize: 14),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      itemCount: _blockedUsers.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final user = _blockedUsers[index];
                        final name = '${user['firstName']} ${user['lastName']}';
                        final avatarUrl = user['avatarUrl'];

                        return Container(
                          decoration: BoxDecoration(
                            color: f.card,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: f.border),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: f.card2,
                              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                              child: avatarUrl == null ? Icon(Icons.person, color: f.textMuted) : null,
                            ),
                            title: Text(
                              name,
                              style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                            subtitle: Text(
                              'Blocked',
                              style: TextStyle(color: f.error, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            trailing: TextButton(
                              onPressed: () => _unblockUser(user['id'], name),
                              style: TextButton.styleFrom(
                                foregroundColor: cs.onSurface,
                                backgroundColor: f.card2,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('Unblock', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
}
