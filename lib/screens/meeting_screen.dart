import 'dart:async';
import 'dart:developer';

import 'package:fl_downloader/fl_downloader.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'create_meeting_screen.dart';

class MeetingScreen extends StatefulWidget {
  final SiteModel site;

  const MeetingScreen({super.key, required this.site});

  @override
  State<MeetingScreen> createState() => _MeetingScreenState();
}

class _MeetingScreenState extends State<MeetingScreen>
    with TickerProviderStateMixin {
  List<MeetingModel> _meetings = [];
  List<MeetingModel> _filteredMeetings = [];
  List<Map<String, dynamic>> _discussionSearchResults = [];
  bool _isLoading = false;
  bool _isSearchingDiscussions = false;
  final _searchController = TextEditingController();

  int progress = 0;
  dynamic downloadId;
  String? status;
  late StreamSubscription progressStream;
  bool _showProgressOverlay = false;
  late AnimationController _overlayAnimationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isAnimating = false;

  @override
  void initState() {
    // Initialize animation controller
    _overlayAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Initialize animations
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _overlayAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    // Add status listener to handle animation completion
    _overlayAnimationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _isAnimating = false;
        });
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _isAnimating = false;
        });
      }
    });

    FlDownloader.initialize();
    progressStream = FlDownloader.progressStream.listen((event) {
      setState(() {
        progress = event.progress;
        downloadId = event.downloadId;
        status = event.status.name;
      });

      if (event.status == DownloadStatus.successful) {
        debugPrint('event.progress: ${event.progress}');
        _hideProgressOverlaySmoothly();
        // This is a way of auto-opening downloaded file right after a download is completed
        FlDownloader.openFile(filePath: event.filePath);
        SnackBarUtils.showSuccess(context, message: 'PDF opened successfully!');
      } else if (event.status == DownloadStatus.running) {
        debugPrint('event.progress: ${event.progress}');
        _showProgressOverlaySmoothly();

        // Close overlay when progress reaches 100%
        if (event.progress >= 100) {
          debugPrint('Progress reached 100%, closing overlay');
          // Add a small delay to ensure smooth transition
          Future.delayed(Duration(milliseconds: 500), () {
            if (mounted) {
              _hideProgressOverlaySmoothly();
            }
          });
        }
      } else if (event.status == DownloadStatus.failed) {
        debugPrint('event: $event');
        _hideProgressOverlaySmoothly();
        SnackBarUtils.showError(
          context,
          message: 'Failed to download PDF. Please try again.',
        );
      } else if (event.status == DownloadStatus.paused) {
        debugPrint('Download paused');
        Future.delayed(
          const Duration(milliseconds: 250),
          () => FlDownloader.attachDownloadProgress(event.downloadId),
        );
      } else if (event.status == DownloadStatus.pending) {
        debugPrint('Download pending');
        _showProgressOverlaySmoothly();
      }
    });
    super.initState();
    _loadMeetings();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
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
    await _loadMeetings();
  }

  void _filterMeetings(String query) {
    if (mounted) {
      setState(() {
        if (query.isEmpty) {
          _filteredMeetings = _meetings;
          _discussionSearchResults = [];
          _isSearchingDiscussions = false;
        } else {
          // First, try to find discussions that match the query
          _discussionSearchResults = [];

          for (final meeting in _meetings) {
            for (final discussion in meeting.meetingDiscussions) {
              if (discussion.discussionAction.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  discussion.actionBy.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  discussion.remarks.toLowerCase().contains(
                    query.toLowerCase(),
                  )) {
                _discussionSearchResults.add({
                  'meeting': meeting,
                  'discussion': discussion,
                });
              }
            }
          }

          // If we found discussions, show them; otherwise show regular meeting search
          if (_discussionSearchResults.isNotEmpty) {
            _isSearchingDiscussions = true;
            _filteredMeetings = []; // Clear regular meetings
          } else {
            _isSearchingDiscussions = false;
            _filteredMeetings = _meetings.where((meeting) {
              return meeting.architectCompany.toLowerCase().contains(
                    query.toLowerCase(),
                  ) ||
                  meeting.clients.any(
                    (client) =>
                        client.toLowerCase().contains(query.toLowerCase()),
                  ) ||
                  meeting.architects.any(
                    (architect) =>
                        architect.toLowerCase().contains(query.toLowerCase()),
                  ) ||
                  meeting.pmcMembers.any(
                    (member) =>
                        member.toLowerCase().contains(query.toLowerCase()),
                  );
            }).toList();
          }
        }
      });
    }
  }

  void _createMeeting() async {
    _dismissKeyboard();
    final result = await NavigationUtils.push(
      context,
      CreateMeetingScreen(site: widget.site),
    );
    // If meeting was created successfully, refresh the list
    if (result == true) {
      await _loadMeetings();
    }
  }

  Future<void> _updateMeetingInList(int meetingId) async {
    try {
      final token = await AuthService.currentToken;
      if (token != null) {
        final response = await ApiService.getMeetingDetail(
          apiToken: token,
          meetingId: meetingId,
        );

        if (response != null && response.status == 1) {
          setState(() {
            // Update the specific meeting in the list
            final index = _meetings.indexWhere((m) => m.id == meetingId);
            if (index != -1) {
              _meetings[index] = response.meetingDetail;
            }

            // Also update in filtered list
            final filteredIndex = _filteredMeetings.indexWhere(
              (m) => m.id == meetingId,
            );
            if (filteredIndex != -1) {
              _filteredMeetings[filteredIndex] = response.meetingDetail;
            }
          });
        }
      }
    } catch (e) {
      // Silent fail - don't show error for background updates
      print('Error updating meeting in list: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _dismissKeyboard();
        return true;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Meetings',
          showDrawer: false,
          showBackButton: true,
        ),

        body: GestureDetector(
          onTap: _dismissKeyboard,
          child: Column(
            children: [
              // Search Bar
              SizedBox(height: 8),
              Padding(
                padding: ResponsiveUtils.horizontalPadding(context),
                child: CustomSearchBar(
                  hintText: _isSearchingDiscussions
                      ? 'Search discussions...'
                      : 'Search meetings and discussions...',
                  onChanged: _filterMeetings,
                  controller: _searchController,
                ),
              ),

              // Search Results Header (when searching discussions)
              if (_isSearchingDiscussions &&
                  _discussionSearchResults.isNotEmpty) ...[
                Padding(
                  padding: ResponsiveUtils.horizontalPadding(context),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '${_discussionSearchResults.length} discussion${_discussionSearchResults.length != 1 ? 's' : ''} found',
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 8),
              ],

              // Meetings List or Discussion Search Results
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      )
                    : _isSearchingDiscussions
                    ? _discussionSearchResults.isEmpty
                          ? _buildEmptyState()
                          : _buildDiscussionSearchResults()
                    : _filteredMeetings.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _refreshMeetings,
                        color: Theme.of(context).colorScheme.primary,
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
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          icon: Icon(Icons.add),
          label: Text('Create Meeting'),
        ),
      ),
    );
  }

  Widget _buildDiscussionSearchResults() {
    return RefreshIndicator(
      onRefresh: _refreshMeetings,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: ResponsiveUtils.responsivePadding(context),
        itemCount: _discussionSearchResults.length,
        itemBuilder: (context, index) {
          final result = _discussionSearchResults[index];
          final meeting = result['meeting'] as MeetingModel;
          final discussion = result['discussion'] as MeetingDiscussionModel;
          return _buildDiscussionCard(meeting, discussion);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _isSearchingDiscussions
                ? Icons.search_off
                : Icons.meeting_room_outlined,
            size: ResponsiveUtils.responsiveFontSize(
              context,
              mobile: 64,
              tablet: 80,
              desktop: 96,
            ),
            color: Theme.of(context).colorScheme.onSurfaceVariant,
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
            _isSearchingDiscussions
                ? 'No discussions found'
                : 'No meetings found',
            style: AppTypography.titleMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 18,
                tablet: 20,
                desktop: 22,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            _isSearchingDiscussions
                ? 'Try searching for different keywords'
                : 'Create your first meeting to get started',
            style: AppTypography.bodyMedium.copyWith(
              fontSize: ResponsiveUtils.responsiveFontSize(
                context,
                mobile: 14,
                tablet: 16,
                desktop: 18,
              ),
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (!_isSearchingDiscussions) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _createMeeting,
              icon: Icon(Icons.add),
              label: Text('Create Meeting'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDiscussionCard(
    MeetingModel meeting,
    MeetingDiscussionModel discussion,
  ) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          _dismissKeyboard();
          final result = await NavigationUtils.push(
            context,
            MeetingDetailScreen(meetingId: meeting.id),
          );
          // If meeting was updated, refresh the specific meeting data
          if (result == true) {
            _updateMeetingInList(meeting.id);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Meeting number
              Row(
                children: [
                  Icon(
                    Icons.meeting_room,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Meeting #${meeting.id}',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 12),

              // Discussion action
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.topic,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      discussion.discussionAction,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
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

  Widget _buildMeetingCard(MeetingModel meeting) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          _dismissKeyboard();
          final result = await NavigationUtils.push(
            context,
            MeetingDetailScreen(meetingId: meeting.id),
          );

          if (result == true) {
            _updateMeetingInList(meeting.id);
          }
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
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 8),
                            Text(
                              meeting.formattedDate,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            SizedBox(width: 16),
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurfaceVariant,
                            ),
                            SizedBox(width: 8),
                            Text(
                              meeting.formattedTime,
                              style: AppTypography.bodyMedium.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (meeting.pdfReportUrl.isNotEmpty)
                    IconButton(
                      onPressed: () async{
                        final pdfUrl = meeting.pdfReportUrl;
                        final pdfName = "${widget.site.name.replaceAll(' ', '_')}_meeting_${meeting.id}";

                        log("pdfUrl = $pdfUrl");
                        log("pdfName = $pdfName");

                        print('PDF URL: $pdfUrl');
                        print('PDF Name: $pdfName');

                        // Show success message and start download
                        SnackBarUtils.showSuccess(
                          context,
                          message: 'Meeting report generated successfully! Starting download...',
                        );

                        final permission = await FlDownloader.requestPermission();
                        if (permission == StoragePermissionStatus.granted) {
                          var success = await FlDownloader.download(
                            pdfUrl,
                            fileName: "$pdfName.pdf",
                          );

                          if (!success) {
                            _hideProgressOverlaySmoothly();
                            SnackBarUtils.showError(
                              context,
                              message: 'Failed to start download. Please try again.',
                            );
                          }
                        } else {
                          _hideProgressOverlaySmoothly();
                          SnackBarUtils.showError(
                            context,
                            message: 'Storage permission denied. Cannot download PDF.',
                          );
                        }

                      },
                      icon: Icon(
                        Icons.picture_as_pdf,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      tooltip: 'View PDF Report',
                    ),
                ],
              ),

              SizedBox(height: 12),

              Divider(height: 1, color: Theme.of(context).colorScheme.outline),

              SizedBox(height: 12),

              // Architect Company
              Row(
                children: [
                  Icon(
                    Icons.business,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meeting.architectCompany,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Participants
              Row(
                children: [
                  Icon(
                    Icons.people,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meeting.participantsSummary,
                      style: AppTypography.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              SizedBox(height: 8),

              // Meeting Place (if available)
              if (meeting.meetingPlace != null &&
                  meeting.meetingPlace!.isNotEmpty)
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        meeting.meetingPlace!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 8),
                  Text(
                    '${meeting.meetingDiscussions.length} discussion${meeting.meetingDiscussions.length != 1 ? 's' : ''}',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Spacer(),
                  Text(
                    'Tap to view details',
                    style: AppTypography.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
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

  void _showProgressOverlaySmoothly() {
    if (!_isAnimating && !_showProgressOverlay) {
      setState(() {
        _showProgressOverlay = true;
        _isAnimating = true;
      });
      // Small delay to ensure smooth appearance
      Future.delayed(const Duration(milliseconds: 50), () {
        if (mounted) {
          _overlayAnimationController.forward();
        }
      });
    }
  }

  void _hideProgressOverlaySmoothly() {
    if (!_isAnimating && _showProgressOverlay) {
      setState(() {
        _isAnimating = true;
      });
      _overlayAnimationController.reverse().then((_) {
        if (mounted) {
          setState(() {
            _showProgressOverlay = false;
          });
        }
      });
    }
  }
}
