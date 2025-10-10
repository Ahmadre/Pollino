import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pollino/bloc/poll.dart';
import 'package:pollino/bloc/poll_bloc.dart';
import 'package:pollino/env.dart' show Environment;
import 'package:pollino/services/supabase_service.dart';
import 'package:pollino/core/widgets/responsive_wrapper.dart';
import 'package:pollino/core/localization/i18n_service.dart';
import 'package:routemaster/routemaster.dart';

class AdminScreen extends StatefulWidget {
  final String pollId;
  final String adminToken;

  const AdminScreen({
    super.key,
    required this.pollId,
    required this.adminToken,
  });

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  Poll? _poll;
  bool _isLoading = true;
  bool _isValidToken = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _validateAndLoadPoll();
  }

  Future<void> _validateAndLoadPoll() async {
    try {
      // Erstmal die Poll laden
      final poll = await SupabaseService.fetchPoll(widget.pollId);

      // Admin-Token validieren (über eine neue Supabase-Funktion)
      final isValid = await SupabaseService.validateAdminToken(widget.pollId, widget.adminToken);

      if (isValid) {
        setState(() {
          _poll = poll;
          _isValidToken = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = I18nService.instance.translate('admin.error.invalidToken');
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deletePoll() async {
    if (_poll == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(I18nService.instance.translate('admin.delete.title')),
        content: Text(
          I18nService.instance.translate('admin.delete.confirmation', params: {
            'title': _poll!.title,
          }),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(I18nService.instance.translate('actions.cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(I18nService.instance.translate('actions.delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await SupabaseService.deletePoll(widget.pollId);

        if (mounted) {
          context.read<PollBloc>().add(const PollEvent.refreshPolls());

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(I18nService.instance.translate('admin.delete.success')),
              backgroundColor: Colors.green,
            ),
          );

          Routemaster.of(context).replace('/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(I18nService.instance.translate('admin.delete.error')),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _copyAdminUrl() {
    final path = '/admin/${widget.pollId}/${widget.adminToken}';
    final adminUrl = Uri.base.origin.isNotEmpty ? '${Uri.base.origin}$path' : '${Environment.webAppUrl}$path';

    Clipboard.setData(ClipboardData(text: adminUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(I18nService.instance.translate('admin.url.copied')),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _sharePollUrl() {
    final path = '/poll/${widget.pollId}';
    final pollUrl = Uri.base.origin.isNotEmpty ? '${Uri.base.origin}$path' : '${Environment.webAppUrl}$path';

    Clipboard.setData(ClipboardData(text: pollUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(I18nService.instance.translate('admin.poll.linkCopied')),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(I18nService.instance.translate('admin.title')),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Routemaster.of(context).replace('/'),
          icon: const Icon(Icons.home),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? _buildErrorView()
                : _isValidToken && _poll != null
                    ? _buildAdminView()
                    : _buildErrorView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return ResponsiveContainer(
      type: ResponsiveContainerType.form,
      centerContent: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            I18nService.instance.translate('admin.error.title'),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? I18nService.instance.translate('admin.error.generic'),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => Routemaster.of(context).replace('/'),
            child: Text(I18nService.instance.translate('admin.error.goHome')),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminView() {
    final poll = _poll!;

    return ResponsiveContainer(
      padding: const EdgeInsets.all(16).copyWith(bottom: 0, top: 0),
      type: ResponsiveContainerType.reading,
      child: ListView(
        children: [
          const SizedBox(height: 16),
          // Poll Info Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE9ECEF)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.poll, color: Color(0xFF4F46E5), size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        poll.title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (poll.description != null && poll.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    poll.description!,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    _InfoChip(
                      icon: Icons.how_to_vote,
                      label:
                          '${poll.options.fold<int>(0, (sum, opt) => sum + opt.votes)} ${I18nService.instance.translate('poll.votes')}',
                    ),
                    _InfoChip(
                      icon: Icons.list,
                      label: '${poll.options.length} ${I18nService.instance.translate('poll.options')}',
                    ),
                    if (poll.allowsMultipleVotes)
                      _InfoChip(
                        icon: Icons.checklist,
                        label: I18nService.instance.translate('poll.multipleChoice'),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Admin Actions
          Text(
            I18nService.instance.translate('admin.actions.title'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          // Share Poll Link
          _AdminActionCard(
            icon: Icons.share,
            title: I18nService.instance.translate('admin.actions.sharePoll'),
            subtitle: I18nService.instance.translate('admin.actions.sharePollDesc'),
            color: Colors.blue,
            onTap: _sharePollUrl,
          ),

          const SizedBox(height: 12),

          // Copy Admin Link
          _AdminActionCard(
            icon: Icons.link,
            title: I18nService.instance.translate('admin.actions.copyAdminUrl'),
            subtitle: I18nService.instance.translate('admin.actions.copyAdminUrlDesc'),
            color: const Color(0xFF4F46E5),
            onTap: _copyAdminUrl,
          ),

          const SizedBox(height: 12),

          // Edit Poll
          _AdminActionCard(
            icon: Icons.edit,
            title: I18nService.instance.translate('admin.actions.editPoll'),
            subtitle: I18nService.instance.translate('admin.actions.editPollDesc'),
            color: Colors.orange,
            onTap: () {
              Routemaster.of(context).push('edit');
            },
          ),

          const SizedBox(height: 24),

          // Danger Zone
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFEF4444)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.warning, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      I18nService.instance.translate('admin.danger.title'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  I18nService.instance.translate('admin.danger.description'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFFEF4444),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _deletePoll,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(I18nService.instance.translate('admin.actions.deletePoll')),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE9ECEF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF6B7280)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE9ECEF)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
