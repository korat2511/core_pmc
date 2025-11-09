import 'dart:developer';

import '../models/invitation_model.dart';
import 'api_service.dart';
import 'auth_service.dart';

class InvitationService {
  List<InvitationModel> invitations = [];
  bool hasMore = true;
  int _currentPage = 1;
  String errorMessage = '';

  Future<bool> loadInvitations({
    int? companyId,
    String? status,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _currentPage = 1;
        hasMore = true;
        invitations = [];
      } else if (!hasMore) {
        return true;
      }

      final token = AuthService.currentToken;
      if (token == null) {
        errorMessage = 'Authentication token not found.';
        return false;
      }

      final response = await ApiService.getInvitations(
        apiToken: token,
        companyId: companyId,
        status: status,
        page: _currentPage,
      );

      if (response['status'] != 1) {
        errorMessage = response['message'] ?? 'Failed to load invitations';
        return false;
      }

      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final List<dynamic> items = data['data'] ?? [];
        final List<InvitationModel> fetched = items
            .map((item) => InvitationModel.fromJson(item as Map<String, dynamic>))
            .toList();

        if (refresh) {
          invitations = fetched;
        } else {
          invitations.addAll(fetched);
        }

        final int currentPage = data['current_page'] ?? _currentPage;
        final int lastPage = data['last_page'] ?? currentPage;
        hasMore = currentPage < lastPage;
        _currentPage = currentPage + 1;
      }

      return true;
    } catch (e, stackTrace) {
      log('InvitationService.loadInvitations error: $e\n$stackTrace');
      errorMessage = 'Failed to load invitations';
      return false;
    }
  }

  Future<Map<String, dynamic>> sendInvitation({
    required int designationId,
    int? companyId,
    String? fullName,
    String? email,
    String? mobile,
    List<String>? channels,
    String? notes,
    int? expiresInMinutes,
  }) async {
    final token = AuthService.currentToken;
    if (token == null) {
      return {'status': 0, 'message': 'Authentication token missing'};
    }

    return ApiService.sendInvitation(
      apiToken: token,
      designationId: designationId,
      companyId: companyId,
      fullName: fullName,
      email: email,
      mobile: mobile,
      channels: channels,
      notes: notes,
      expiresInMinutes: expiresInMinutes,
    );
  }

  Future<Map<String, dynamic>> resendInvitation({
    required int invitationId,
    List<String>? channels,
  }) async {
    final token = AuthService.currentToken;
    if (token == null) {
      return {'status': 0, 'message': 'Authentication token missing'};
    }

    return ApiService.resendInvitation(
      apiToken: token,
      invitationId: invitationId,
      channels: channels,
    );
  }

  Future<Map<String, dynamic>> revokeInvitation({
    required int invitationId,
  }) async {
    final token = AuthService.currentToken;
    if (token == null) {
      return {'status': 0, 'message': 'Authentication token missing'};
    }

    return ApiService.revokeInvitation(
      apiToken: token,
      invitationId: invitationId,
    );
  }

  Future<Map<String, dynamic>> getShareLinks() async {
    final token = AuthService.currentToken;
    if (token == null) {
      return {'status': 0, 'message': 'Authentication token missing'};
    }

    return ApiService.shareAppLinks(apiToken: token);
  }

  void reset() {
    invitations = [];
    hasMore = true;
    _currentPage = 1;
    errorMessage = '';
  }
}


