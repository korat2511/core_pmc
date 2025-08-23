import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/utils/responsive_utils.dart';
import '../core/utils/navigation_utils.dart';
import '../core/utils/snackbar_utils.dart';
import '../models/site_model.dart';
import '../models/meeting_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/custom_search_bar.dart';
import 'meeting_detail_screen.dart';

class MeetingScreen extends StatefulWidget {
  final SiteModel site;

  const MeetingScreen({
    super.key,
    required this.site,
  });

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen> {
  List<MeetingModel> _meetings = [];
  List<MeetingModel> _filteredMeetings = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetings() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getMeetingList(
          apiToken: token,
          siteId: widget.site.id,
        );
        
        if (response != null && response.status == 1) {
          setState(() {
            _meetings = response.meetingList;
            _filteredMeetings = response.meetingList;
          });
        } else {
          SnackBarUtils.showError(context, message: 'Failed to load meetings');
        }
      }
    } catch (e) {
      SnackBarUtils.showError(context, message: 'Error loading meetings: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshMeetings() async {
    setState(() {
      _isRefreshing = true;
    });

    await _loadMeetings();

    setState(() {
      _isRefreshing = false;
    });
  }

  void _filterMeetings(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredMeetings = _meetings;
        } else {
          _filteredMeetings = _meetings.where((meeting) {
            return meeting.architectCompany.toLowerCase().contains(query.toLowerCase()) ||
                   meeting.clients.any((client) => client.toLowerCase().contains(query.toLowerCase())) ||
                   meeting.architects.any((architect) => architect.toLowerCase().contains(query.toLowerCase())) ||
                   meeting.pmcMembers.any((member) => member.toLowerCase().contains(query.toLowerCase())) ||
                   meeting.meetingDiscussions.any((discussion) => 
                       discussion.discussionAction.toLowerCase().contains(query.toLowerCase()));
          }).toList();
        }
      });
    }
  }

  void _createMeeting() {
    // TODO: Implement create meeting functionality
    SnackBarUtils.showInfo(context, message: 'Create meeting functionality coming soon');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Meetings',
        showDrawer: false,
        showBackButton: true,
      ),

      body: GestureDetector(
        onTap: () {
          // Close keyboard when tapping outside
          FocusScope.of(context).unfocus();
        },
        child: Column(
          children: [
            // Search Bar
            SizedBox(height: 8),
            Padding(
              padding: ResponsiveUtils.horizontalPadding(context),
              child: CustomSearchBar(
                hintText: 'Search meetings...',
                onChanged: _filterMeetings,
                controller: _searchController,
              ),
            ),

            // Meetings List
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : _filteredMeetings.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _refreshMeetings,
                          child: ListView.builder(
                            padding: ResponsiveUtils.responsivePadding(context),
                            itemCount: _filteredMeetings.length,
                            itemBuilder: (context, index) {
                              final meeting = _filteredMeetings[index];
                              return _buildMeetingCard(meeting);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createMeeting,
        backgroundColor: AppColors.primaryColor,
        foregroundColor: Colors.white,
        icon: Icon(Icons.add),
        label: Text('Create Meeting'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.meeting_room_outlined,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 64,
              tablet: 80,
              desktop: 96,
            ),
            color: AppColors.textSecondary,
          ),
          SizedBox(
            height: ResponsiveUtils.responsiveSpacing(
              context,
              mobile: 16,
              tablet: 20,
              desktop: 24,
            ),
          ),
          Text(
            'No meetings found',
            style: AppTypography.titleMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Create your first meeting to get started',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createMeeting,
            icon: Icon(Icons.add),
            label: Text('Create Meeting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMeetingCard(MeetingModel meeting) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          NavigationUtils.push(
            context,
            MeetingDetailScreen(meetingId: meeting.id),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with date and time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meeting #${meeting.id}',
                          style: AppTypography.titleSmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text(
                              meeting.formattedDate,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                            SizedBox(width: 8),
                            Text(
                              meeting.formattedTime,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (meeting.pdfReportUrl.isNotEmpty)
                    IconButton(
                      onPressed: () {
                        // TODO: Open PDF report
                        SnackBarUtils.showInfo(context, message: 'PDF report opening coming soon');
                      },
                      icon: Icon(Icons.picture_as_pdf, color: AppColors.errorColor),
                      tooltip: 'View PDF Report',
                    ),
                ],
              ),

              SizedBox(height: 12),
              Divider(height: 1),

              SizedBox(height: 12),

              // Architect Company
              Row(
                children: [
                  Icon(Icons.business, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meeting.architectCompany,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Participants
              Row(
                children: [
                  Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meeting.participantsSummary,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Meeting Place (if available)
              if (meeting.meetingPlace != null && meeting.meetingPlace!.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meeting.meetingPlace!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

              SizedBox(height: 12),

              // Discussions count
              Row(
                children: [
                  Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.textSecondary),
                  SizedBox(width: 8),
                  Text(
                    '${meeting.meetingDiscussions.length} discussion${meeting.meetingDiscussions.length != 1 ? 's' : ''}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Tap to view details',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primaryColor,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
