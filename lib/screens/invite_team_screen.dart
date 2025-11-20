import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/designation_model.dart';
import '../models/invitation_model.dart';
import '../services/auth_service.dart';
import '../services/designation_service.dart';
import '../services/invitation_service.dart';
import '../services/permission_service.dart';
import '../widgets/custom_app_bar.dart';

class InviteTeamScreen extends StatefulWidget {
  const InviteTeamScreen({super.key});

  @override
  State<InviteTeamScreen> createState() => _InviteTeamScreenState();
}

class _InviteTeamScreenState extends State<InviteTeamScreen> {
  final InvitationService _invitationService = InvitationService();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

  bool _isLoading = true;
  bool _isRefreshing = false;
  bool _isSending = false;

  List<DesignationModel> _designations = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadDesignations(),
      _loadInvitations(refresh: true),
    ]);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadDesignations() async {
    final currentUser = AuthService.currentUser;
    if (currentUser?.companyId == null) {
      _designations = [];
      return;
    }

    if (DesignationService.designations.isEmpty) {
      await DesignationService.loadDesignations(companyId: currentUser!.companyId!);
    }

    setState(() {
      _designations = DesignationService.designations;
    });
  }

  Future<void> _loadInvitations({bool refresh = false}) async {
    if (refresh) {
      setState(() => _isRefreshing = true);
    }

    final success = await _invitationService.loadInvitations(refresh: refresh);
    if (!success && mounted) {
      SnackBarUtils.showError(context, message: _invitationService.errorMessage);
    }

    if (refresh && mounted) {
      setState(() => _isRefreshing = false);
    } else if (mounted) {
      setState(() {});
    }
  }

  bool _canInvite() {
    return PermissionService.canInviteUser() || AuthService.currentUser?.isAdmin == true;
  }

  Future<void> _handleInviteMembers() async {
    if (!_canInvite()) {
      SnackBarUtils.showError(context, message: "You don't have permission to invite members.");
      return;
    }

    try {
      final granted = await FlutterContacts.requestPermission(readonly: true);
      if (!granted) {
        if (mounted) {
          SnackBarUtils.showInfo(
            context,
            message: 'Contact permission denied. Please allow access from settings.',
          );
        }
        return;
      }

      final contacts = await FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: false,
      );

      if (!mounted) return;

      if (contacts.isEmpty) {
        SnackBarUtils.showInfo(context, message: 'No contacts found on this device.');
        return;
      }

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (context) {
          return FractionallySizedBox(
            heightFactor: 0.9,
            child: _ContactPickerSheet(
              contacts: contacts,
              onSelect: (contact, phone) {
                Navigator.of(context).pop();
                _askDesignationAndSend(contact, phone);
              },
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      SnackBarUtils.showError(
        context,
        message: 'Unable to access contacts. ${e.toString()}',
      );
    }
  }

  Future<void> _askDesignationAndSend(Contact contact, String phone) async {
    if (_designations.isEmpty) {
      SnackBarUtils.showInfo(context, message: 'No designations available. Please add one first.');
      return;
    }

    final cleanedPhone = _cleanPhoneNumber(phone);
    if (cleanedPhone.isEmpty) {
      SnackBarUtils.showInfo(context, message: 'Selected contact does not have a valid number.');
      return;
    }

    final selectedDesignationId = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return _DesignationPickerSheet(
          designations: _designations,
        );
      },
    );

    if (selectedDesignationId == null) return;

    // Show channel selection dialog
    final selectedChannels = await showDialog<List<String>>(
      context: context,
      builder: (context) => _ChannelSelectionDialog(
        hasEmail: contact.emails.isNotEmpty,
        hasPhone: cleanedPhone.isNotEmpty,
      ),
    );

    if (selectedChannels == null || selectedChannels.isEmpty) {
      SnackBarUtils.showInfo(context, message: 'Please select at least one channel to send invitation.');
      return;
    }

    await _sendInvitation(
      name: contact.displayName,
      phone: cleanedPhone,
      email: contact.emails.isNotEmpty ? contact.emails.first.address : null,
      designationId: selectedDesignationId,
      channels: selectedChannels,
    );
  }

  Future<void> _sendInvitation({
    required String name,
    required String phone,
    String? email,
    required int designationId,
    required List<String> channels,
  }) async {
    setState(() => _isSending = true);

    final response = await _invitationService.sendInvitation(
      designationId: designationId,
      fullName: name.trim().isEmpty ? null : name.trim(),
      mobile: phone,
      email: email,
      channels: channels,
      notes: null,
      expiresInMinutes: null,
    );

    setState(() => _isSending = false);

    if (!mounted) return;

    if (response['status'] == 1) {
      SnackBarUtils.showSuccess(
        context,
        message: response['message'] ?? 'Invitation sent successfully.',
      );
      await _loadInvitations(refresh: true);
    } else {
      SnackBarUtils.showError(
        context,
        message: response['message'] ?? 'Failed to send invitation.',
      );
    }
  }

  String _cleanPhoneNumber(String input) {
    return input.replaceAll(RegExp(r'[^0-9+]'), '');
  }

  Future<void> _handleResend(InvitationModel invitation) async {
    // Show channel selection dialog for resend
    final hasEmail = invitation.email != null && invitation.email!.isNotEmpty;
    final hasPhone = invitation.mobile != null && invitation.mobile!.isNotEmpty;

    if (!hasEmail && !hasPhone) {
      SnackBarUtils.showError(context, message: 'Invitation has no email or mobile number.');
      return;
    }

    final selectedChannels = await showDialog<List<String>>(
      context: context,
      builder: (context) => _ChannelSelectionDialog(
        hasEmail: hasEmail,
        hasPhone: hasPhone,
      ),
    );

    if (selectedChannels == null || selectedChannels.isEmpty) {
      SnackBarUtils.showInfo(context, message: 'Please select at least one channel to resend invitation.');
      return;
    }

    final response = await _invitationService.resendInvitation(
      invitationId: invitation.id,
      channels: selectedChannels,
    );

    if (response['status'] == 1) {
      SnackBarUtils.showSuccess(context, message: response['message'] ?? 'Invitation resent.');
      await _loadInvitations(refresh: true);
    } else {
      SnackBarUtils.showError(context, message: response['message'] ?? 'Failed to resend invitation.');
    }
  }

  Future<void> _handleRevoke(InvitationModel invitation) async {
    final response = await _invitationService.revokeInvitation(invitationId: invitation.id);

    if (response['status'] == 1) {
      SnackBarUtils.showSuccess(context, message: response['message'] ?? 'Invitation revoked.');
      await _loadInvitations(refresh: true);
    } else {
      SnackBarUtils.showError(context, message: response['message'] ?? 'Failed to revoke invitation.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final invitations = _invitationService.invitations;

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Invite Members',
        showDrawer: false,
        showBackButton: true,
      ),
      floatingActionButton: _canInvite()
          ? FloatingActionButton.extended(
              onPressed: _isSending ? null : _handleInviteMembers,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Invite Members'),
            )
          : null,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_isSending) const LinearProgressIndicator(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => _loadInvitations(refresh: true),
                    child: invitations.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 140),
                              Icon(
                                Icons.mark_email_unread,
                                size: 64,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 24),
                                child: Text(
                                  'No invitations sent yet.\nTap “Invite Members” to add your team.',
                                  textAlign: TextAlign.center,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                            itemCount: invitations.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final invitation = invitations[index];
                              return _InvitationTile(
                                invitation: invitation,
                                dateFormat: _dateFormat,
                                onResend: () => _handleResend(invitation),
                                onRevoke: () => _handleRevoke(invitation),
                              );
                            },
                          ),
                  ),
                ),
                if (_isRefreshing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  final InvitationModel invitation;
  final DateFormat dateFormat;
  final VoidCallback? onResend;
  final VoidCallback? onRevoke;

  const _InvitationTile({
    required this.invitation,
    required this.dateFormat,
    this.onResend,
    this.onRevoke,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.surfaceVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  invitation.fullName?.isNotEmpty == true
                      ? invitation.fullName!
                      : invitation.mobile ?? 'Pending invite',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  invitation.statusDisplay,
                  style: AppTypography.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            invitation.designation?['name'] ?? 'Designation',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (invitation.mobile != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                invitation.mobile!,
                style: AppTypography.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: 8),
          Text(
            'Sent on ${dateFormat.format(invitation.createdAt)}',
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (invitation.expiresAt != null)
            Text(
              'Expires ${dateFormat.format(invitation.expiresAt!)}',
              style: AppTypography.bodySmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          if (invitation.isPending)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: onResend,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Resend'),
                  ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: onRevoke,
                    icon: const Icon(Icons.close),
                    label: const Text('Revoke'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    switch (invitation.status) {
      case 'accepted':
        return AppColors.successColor;
      case 'revoked':
      case 'expired':
        return Theme.of(context).colorScheme.error;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }
}

class _ContactPickerSheet extends StatefulWidget {
  final List<Contact> contacts;
  final void Function(Contact contact, String phone) onSelect;

  const _ContactPickerSheet({
    required this.contacts,
    required this.onSelect,
  });

  @override
  State<_ContactPickerSheet> createState() => _ContactPickerSheetState();
}

class _ContactPickerSheetState extends State<_ContactPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final filteredContacts = widget.contacts.where((contact) {
      final matchesQuery =
          contact.displayName.toLowerCase().contains(_query.toLowerCase());
      return matchesQuery && contact.phones.isNotEmpty;
    }).toList()
      ..sort((a, b) => a.displayName.compareTo(b.displayName));

    return SafeArea(
      child: Column(
        children: [
          Container(
            width: 60,
            height: 5,
            margin: const EdgeInsets.only(top: 12, bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search contacts',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filteredContacts.isEmpty
                ? Center(
                    child: Text(
                      'No contacts found',
                      style: AppTypography.bodyMedium.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredContacts.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final contact = filteredContacts[index];
                      final primaryPhone = contact.phones.first.number;
                      final cleanedPhone =
                          primaryPhone.replaceAll(RegExp(r'[^0-9+]'), '');

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                          child: Text(
                            contact.displayName.isNotEmpty
                                ? contact.displayName.characters.first.toUpperCase()
                                : '?',
                            style: AppTypography.bodyMedium.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        title: Text(
                          contact.displayName,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        subtitle: Text(
                          cleanedPhone,
                          style: AppTypography.bodySmall.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        onTap: () => widget.onSelect(contact, primaryPhone),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DesignationPickerSheet extends StatelessWidget {
  final List<DesignationModel> designations;

  const _DesignationPickerSheet({
    required this.designations,
  });

  @override
  Widget build(BuildContext context) {
    int? selectedId = designations.isNotEmpty ? designations.first.id : null;

    return StatefulBuilder(
      builder: (context, setState) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 5,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Select designation',
                    style: AppTypography.titleMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: designations.length,
                  itemBuilder: (context, index) {
                    final designation = designations[index];
                    return RadioListTile<int>(
                      value: designation.id,
                      groupValue: selectedId,
                      title: Text(designation.name),
                      onChanged: (value) {
                        setState(() => selectedId = value);
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: selectedId == null
                        ? null
                        : () => Navigator.of(context).pop(selectedId),
                    child: const Text('Invite'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ChannelSelectionDialog extends StatefulWidget {
  final bool hasEmail;
  final bool hasPhone;

  const _ChannelSelectionDialog({
    required this.hasEmail,
    required this.hasPhone,
  });

  @override
  State<_ChannelSelectionDialog> createState() => _ChannelSelectionDialogState();
}

class _ChannelSelectionDialogState extends State<_ChannelSelectionDialog> {
  final Set<String> _selectedChannels = {'sms'}; // Default to SMS

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Select Channels',
        style: AppTypography.titleMedium.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose how to send the invitation:',
            style: AppTypography.bodyMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (widget.hasEmail)
            CheckboxListTile(
              title: Row(
                children: [
                  Icon(
                    Icons.email_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Email'),
                ],
              ),
              value: _selectedChannels.contains('email'),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedChannels.add('email');
                  } else {
                    _selectedChannels.remove('email');
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          if (widget.hasPhone) ...[
            CheckboxListTile(
              title: Row(
                children: [
                  Icon(
                    Icons.sms_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('SMS'),
                ],
              ),
              value: _selectedChannels.contains('sms'),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedChannels.add('sms');
                  } else {
                    _selectedChannels.remove('sms');
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            CheckboxListTile(
              title: Row(
                children: [
                  Icon(
                    Icons.chat_outlined,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('WhatsApp'),
                ],
              ),
              value: _selectedChannels.contains('whatsapp'),
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedChannels.add('whatsapp');
                  } else {
                    _selectedChannels.remove('whatsapp');
                  }
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _selectedChannels.isEmpty
              ? null
              : () => Navigator.of(context).pop(_selectedChannels.toList()),
          child: const Text('Send'),
        ),
      ],
    );
  }
}


