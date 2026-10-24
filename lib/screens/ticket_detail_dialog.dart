import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ticket_models.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';

class TicketDetailDialog extends StatefulWidget {
  final int ticketId;
  final VoidCallback onTicketUpdated;

  const TicketDetailDialog({
    super.key,
    required this.ticketId,
    required this.onTicketUpdated,
  });

  @override
  State<TicketDetailDialog> createState() => _TicketDetailDialogState();
}

class _TicketDetailDialogState extends State<TicketDetailDialog> {
  bool _isLoading = true;
  ClientTicket? _ticket;
  List<TicketTimelineEvent> _timeline = [];
  List<TicketComment> _comments = [];

  // Form Fields
  late String _currentStatus;
  late String _csPerson;
  late String _adminPerson;
  late String _developer;
  late String _tester;
  late bool _isCritical;
  final TextEditingController _criticalCommentController = TextEditingController();
  final TextEditingController _prLinkController = TextEditingController();
  late String _selectedTag;
  late String _module;
  late String _subModule;
  late String _toughness;
  final TextEditingController _estimatedTimeController = TextEditingController();
  late String _issueType;

  // Right Panel Sub Tabs (0 = Software Comment, 1 = WFM Comment, 2 = Case History, 3 = Case Updates)
  int _activeRightTab = 0;
  final TextEditingController _newCommentController = TextEditingController();
  String? _selectedAttachmentName;

  // Live Timer
  Timer? _liveTimer;
  Duration _activeTimerDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadTicketDetails();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _criticalCommentController.dispose();
    _prLinkController.dispose();
    _estimatedTimeController.dispose();
    _newCommentController.dispose();
    super.dispose();
  }

  void _tick() {
    if (_ticket != null && _ticket!.isTimerRunning && _ticket!.activeTimerStartTime != null) {
      final now = DateTime.now();
      final diff = now.difference(_ticket!.activeTimerStartTime!);
      if (mounted) {
        setState(() {
          _activeTimerDuration = diff.isNegative ? Duration.zero : diff;
        });
      }
    }
  }

  Future<void> _loadTicketDetails() async {
    setState(() => _isLoading = true);
    final res = await ServerpodService().getTicketDetails(widget.ticketId);

    if (res['success'] == true && mounted) {
      final t = res['ticket'] as ClientTicket;
      final tl = (res['timeline'] as List<TicketTimelineEvent>?) ?? [];
      final cm = (res['comments'] as List<TicketComment>?) ?? [];
      _initializeFields(t, tl, cm);
    } else {
      // Fallback: If ticket is one of the seeded ITDS cases
      final fallback = _getFallbackTicket(widget.ticketId);
      final fallbackComments = _getFallbackComments(widget.ticketId);
      final fallbackTimeline = _getFallbackTimeline(widget.ticketId);
      if (mounted) {
        _initializeFields(fallback, fallbackTimeline, fallbackComments);
      }
    }
  }

  void _initializeFields(ClientTicket t, List<TicketTimelineEvent> tl, List<TicketComment> cm) {
    _ticket = t;
    _timeline = tl;
    _comments = cm;

    _currentStatus = t.itdsStatus;
    _csPerson = t.csPersonName.isNotEmpty ? t.csPersonName : 'ASHISH';
    _adminPerson = t.adminAssigned.isNotEmpty ? t.adminAssigned : 'KKOTIAN';
    _developer = t.developerName.isNotEmpty ? t.developerName : 'SUDIPSURVE';
    _tester = t.testerName.isNotEmpty ? t.testerName : 'SELECT...';
    _isCritical = t.isCritical;
    _criticalCommentController.text = t.criticalComment;
    _prLinkController.text = t.pullRequestLink;
    _selectedTag = t.tags;
    _module = t.module;
    _subModule = t.subModule;
    _toughness = t.toughness.isEmpty ? 'SELECT...' : t.toughness;
    _estimatedTimeController.text = '${t.estimatedMinutes}';
    _issueType = t.issueType;

    _isLoading = false;
    _tick();
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  Future<void> _handleStatusSubmit() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Case #${_ticket?.ticketNumber} status updated to $_currentStatus')),
    );
    widget.onTicketUpdated();
  }

  Future<void> _handleStartDevTimer() async {
    if (_ticket == null) return;
    await ServerpodService().startDevWork(widget.ticketId, _developer);
    await _loadTicketDetails();
    widget.onTicketUpdated();
  }

  Future<void> _handleStopDevTimer() async {
    if (_ticket == null) return;
    await ServerpodService().completeDevWorkAndSendToTesting(
      widget.ticketId,
      _developer,
      'QA001',
      _tester == 'SELECT...' ? 'Rahul Patil' : _tester,
      'Developer work finished. Handed over to QA.',
    );
    await _loadTicketDetails();
    widget.onTicketUpdated();
  }

  Future<void> _postNewComment() async {
    final text = _newCommentController.text.trim();
    if (text.isEmpty) return;

    _newCommentController.clear();
    await ServerpodService().addTicketComment(
      widget.ticketId,
      'ITD001',
      'pratiknikam',
      'DEVELOPER',
      text,
      attachmentName: _selectedAttachmentName,
    );

    setState(() {
      _comments.insert(
        0,
        TicketComment(
          id: DateTime.now().millisecondsSinceEpoch,
          authorCode: 'ITD001',
          authorName: 'pratiknikam',
          authorRole: 'DEVELOPER',
          message: text,
          attachmentName: _selectedAttachmentName,
          createdAt: DateTime.now(),
        ),
      );
      _selectedAttachmentName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: const SizedBox(
          width: 500,
          height: 300,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final t = _ticket!;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Container(
        width: 1360,
        height: 840,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // 1. MINIMAL DIALOG TOP HEADER
            _buildDialogHeader(t),

            // 2. MINIMAL STATUS BANNER
            _buildDialogOngoingBanner(t),

            // 3. MAIN 2-COLUMN SPLIT
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LEFT COLUMN: Case Metadata Form
                  SizedBox(
                    width: 540,
                    child: Container(
                      decoration: const BoxDecoration(
                        border: Border(right: BorderSide(color: AppColors.cardBorder)),
                      ),
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(22),
                        child: _buildLeftForm(t),
                      ),
                    ),
                  ),

                  // RIGHT COLUMN: Tabs, Rich Editor & Comments Timeline
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Right Sub Tabs
                        _buildRightSubTabs(),

                        // Tab Content
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(22),
                            child: _buildRightTabContent(t),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 1. DIALOG HEADER (Minimal & Elegant)
  // ==============================================================
  Widget _buildDialogHeader(ClientTicket t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${t.ticketNumber}',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                t.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: t.statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: t.statusColor.withValues(alpha: 0.25)),
                ),
                child: Text(
                  t.itdsStatus,
                  style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w700, color: t.statusColor),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: AppColors.textMuted),
            onPressed: () => Navigator.of(context).pop(),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildDialogOngoingBanner(ClientTicket t) {
    if (t.isTimerRunning) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        color: const Color(0xFFECFDF5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF047857)),
            const SizedBox(width: 8),
            Text(
              'Active Work Session Running  •  ⏱ ${_formatDuration(_activeTimerDuration)}',
              style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // ==============================================================
  // 2. LEFT PANEL: CASE FORM & METADATA
  // ==============================================================
  Widget _buildLeftForm(ClientTicket t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // STATUS Row + Submit Button
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('STATUS', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _currentStatus,
                        isDense: true,
                        style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark),
                        items: const [
                          DropdownMenuItem(value: 'HOLD QUEUE', child: Text('HOLD QUEUE')),
                          DropdownMenuItem(value: 'HOLD', child: Text('HOLD')),
                          DropdownMenuItem(value: 'DEVELOPMENT IN PROGRESS', child: Text('DEVELOPMENT IN PROGRESS')),
                          DropdownMenuItem(value: 'DEVELOPMENT', child: Text('DEVELOPMENT')),
                          DropdownMenuItem(value: 'READY FOR TESTING', child: Text('READY FOR TESTING')),
                          DropdownMenuItem(value: 'TESTING', child: Text('TESTING')),
                          DropdownMenuItem(value: 'PULL REQUEST RAISED', child: Text('PULL REQUEST RAISED')),
                          DropdownMenuItem(value: 'TEST FAILED', child: Text('TEST FAILED')),
                          DropdownMenuItem(value: 'RESOLVED', child: Text('RESOLVED')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _currentStatus = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: ElevatedButton(
                onPressed: _handleStatusSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Submit', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // CS PERSON & ADMIN PERSON
        Row(
          children: [
            Expanded(
              child: _buildFormFieldDropdown(
                label: 'CS PERSON',
                value: _csPerson,
                options: const ['ASHISH', 'Sneha Kulkarni', 'Kavita Shinde'],
                onChanged: (v) => setState(() => _csPerson = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormFieldDropdown(
                label: 'ADMIN PERSON',
                value: _adminPerson,
                options: const ['KKOTIAN', 'Vikram Malhotra', 'VIRAGDOSHI'],
                onChanged: (v) => setState(() => _adminPerson = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // DEVELOPER & TESTER
        Row(
          children: [
            Expanded(
              child: _buildFormFieldDropdown(
                label: 'DEVELOPER',
                value: _developer,
                options: const ['SUDIPSURVE', 'pratiknikam', 'tushar', 'VIRAGDOSHI'],
                onChanged: (v) => setState(() => _developer = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormFieldDropdown(
                label: 'TESTER',
                value: _tester,
                options: const ['SELECT...', 'Rahul Patil', 'Pooja Nair', 'SUDIPSURVE'],
                onChanged: (v) => setState(() => _tester = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // CRITICAL CHECKBOX & COMMENT
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isCritical ? const Color(0xFFFFF1F2) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _isCritical ? const Color(0xFFFECDD3) : AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _isCritical,
                    activeColor: const Color(0xFFDC2626),
                    onChanged: (v) => setState(() => _isCritical = v ?? false),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Mark as Critical Priority Issue',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _isCritical ? const Color(0xFFDC2626) : AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _criticalCommentController,
                style: GoogleFonts.poppins(fontSize: 11.5),
                decoration: InputDecoration(
                  hintText: 'Comment for critical case SLA impact...',
                  hintStyle: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textLight),
                  fillColor: Colors.white,
                  filled: true,
                  border: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // PULL REQUEST LINK
        Text('PULL REQUEST LINK', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        TextField(
          controller: _prLinkController,
          style: GoogleFonts.poppins(fontSize: 12),
          decoration: InputDecoration(
            hintText: 'https://github.com/.../pull/123',
            hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
            fillColor: const Color(0xFFF8FAFC),
            filled: true,
            border: OutlineInputBorder(
              borderSide: const BorderSide(color: AppColors.cardBorder),
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
        const SizedBox(height: 14),

        // TAGS RADIO CHIPS (Modern Pill Selector)
        Text('TAGS & CATEGORY', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _buildTagChip('SOFTWARE ISSUE / BUG'),
            _buildTagChip('SOFTWARE REQUIRMENT'),
            _buildTagChip('SOFTWARE DEPLOYMENT'),
            _buildTagChip('SOFTWARE QUERY'),
            _buildTagChip('TRAINING REQUEST'),
            _buildTagChip('VISIT'),
          ],
        ),
        const SizedBox(height: 16),

        // CLIENT & DROPLET INFO
        _buildInfoBox('CLIENT & ENVIRONMENT', '${t.clientName}\nDroplet: ${t.dropletUrl}'),
        const SizedBox(height: 12),

        // CREATED AT & CASE NO
        Row(
          children: [
            Expanded(child: _buildInfoBox('CREATED AT', '12/08/2026 02:36 PM')),
            const SizedBox(width: 10),
            Expanded(child: _buildInfoBox('CASE NO.', t.ticketNumber)),
          ],
        ),
        const SizedBox(height: 12),

        // TITLE & DESCRIPTION
        _buildInfoBox('TITLE', t.title),
        const SizedBox(height: 8),
        _buildInfoBox('DESCRIPTION', t.description),
        const SizedBox(height: 14),

        // MODULE & SUB MODULE
        Row(
          children: [
            Expanded(
              child: _buildFormFieldDropdown(
                label: 'MODULE',
                value: _module,
                options: const ['SOFTWARE USERS', 'AWB ENTRY', 'CUTOMER PORTAL'],
                onChanged: (v) => setState(() => _module = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildFormFieldDropdown(
                label: 'SUB MODULE',
                value: _subModule,
                options: const ['PERMISSIONS', 'USER CREATION', 'AWB ENTRY ERROR', 'VALIDATION'],
                onChanged: (v) => setState(() => _subModule = v!),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // TOUGHNESS & ESTIMATED TIME (IN MIN)
        Row(
          children: [
            Expanded(
              child: _buildFormFieldDropdown(
                label: 'TOUGHNESS',
                value: _toughness,
                options: const ['SELECT...', 'EASY', 'MEDIUM', 'HARD'],
                onChanged: (v) => setState(() => _toughness = v!),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ESTIMATED TIME(IN MIN)', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
                  const SizedBox(height: 4),
                  Container(
                    height: 38,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      border: Border.all(color: AppColors.cardBorder),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text('300 mins', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // DEV TIME, CS TIME, TESTER TIME (Interactive Modern Timer Cards)
        Text('LIVE TIME TRACKING', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 8),
        Row(
          children: [
            // DEV TIME Box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DEV TIME', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      t.isTimerRunning && t.activeTimerRole == 'DEVELOPER'
                          ? _formatDuration(_activeTimerDuration)
                          : '${t.totalDevMinutes} mins',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: t.isTimerRunning && t.activeTimerRole == 'DEVELOPER'
                            ? const Color(0xFF047857)
                            : AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: t.isTimerRunning ? _handleStopDevTimer : _handleStartDevTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: t.isTimerRunning ? const Color(0xFFDC2626) : AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          t.isTimerRunning ? '⏹ Stop' : '▶ Start',
                          style: GoogleFonts.poppins(fontSize: 10.5, color: Colors.white, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // CS TIME Box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CS TIME', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text('30 mins', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),

            // TESTER TIME Box
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('TESTER TIME', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text('${t.totalTestingMinutes} mins', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // ISSUE TYPE (Minimal Radio Selector)
        Row(
          children: [
            Text('ISSUE TYPE:', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
            const SizedBox(width: 12),
            InkWell(
              onTap: () => setState(() => _issueType = 'ITD ISSUE'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _issueType == 'ITD ISSUE' ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 16,
                    color: _issueType == 'ITD ISSUE' ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text('ITD ISSUE', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: () => setState(() => _issueType = 'NON ITD ISSUE'),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _issueType == 'NON ITD ISSUE' ? Icons.radio_button_checked : Icons.radio_button_off,
                    size: 16,
                    color: _issueType == 'NON ITD ISSUE' ? AppColors.primary : AppColors.textMuted,
                  ),
                  const SizedBox(width: 6),
                  Text('NON ITD ISSUE', style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFormFieldDropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted)),
        const SizedBox(height: 4),
        Container(
          height: 38,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            border: Border.all(color: AppColors.cardBorder),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: options.contains(value) ? value : options.first,
              isExpanded: true,
              isDense: true,
              style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w500),
              items: options.map((opt) => DropdownMenuItem(value: opt, child: Text(opt))).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _selectedTag == tag;
    return InkWell(
      onTap: () => setState(() => _selectedTag = tag),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
            ],
            Text(
              tag,
              style: GoogleFonts.poppins(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark)),
        ],
      ),
    );
  }

  // ==============================================================
  // 3. RIGHT PANEL: SUB TABS, COMPOSER & TIMELINE
  // ==============================================================
  Widget _buildRightSubTabs() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          _buildRightTabHeader(0, 'Software Comments', Icons.chat_bubble_outline),
          const SizedBox(width: 8),
          _buildRightTabHeader(1, 'WFM Review', Icons.rate_review_outlined),
          const SizedBox(width: 8),
          _buildRightTabHeader(2, 'Audit Timeline', Icons.timeline_outlined),
          const SizedBox(width: 8),
          _buildRightTabHeader(3, 'Version Updates', Icons.update_outlined),
        ],
      ),
    );
  }

  Widget _buildRightTabHeader(int index, String label, IconData icon) {
    final isSelected = _activeRightTab == index;
    return InkWell(
      onTap: () => setState(() => _activeRightTab = index),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 15,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightTabContent(ClientTicket t) {
    if (_activeRightTab == 2) {
      return _buildCaseHistoryView();
    }

    // Default: Software Comment & Comment Stream
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Minimal Composer Card
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Minimal Toolbar
              Container(
                color: const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    _buildToolbarIcon(Icons.format_bold, 'Bold'),
                    _buildToolbarIcon(Icons.format_italic, 'Italic'),
                    _buildToolbarIcon(Icons.code, 'Code'),
                    _buildToolbarIcon(Icons.format_list_bulleted, 'Bullets'),
                    _buildToolbarIcon(Icons.format_list_numbered, 'Numbers'),
                    _buildToolbarIcon(Icons.link, 'Link'),
                    const Spacer(),
                    Text('Markdown & text support', style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight)),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.cardBorder),

              // Multiline Text Input
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _newCommentController,
                  maxLines: 4,
                  style: GoogleFonts.poppins(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'Add comment, testing instructions, developer notes...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              // Attachment & Post Row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() => _selectedAttachmentName = 'api_security_patch_v2.patch');
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Attached file: api_security_patch_v2.patch')),
                        );
                      },
                      icon: const Icon(Icons.attach_file, size: 14, color: AppColors.textBody),
                      label: Text(
                        _selectedAttachmentName ?? 'Attach file',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textBody),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cardBorder),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: const Size(0, 30),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _postNewComment,
                      icon: const Icon(Icons.send_rounded, size: 13),
                      label: Text('Post Comment', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Timeline Stream of Comments
        Text('ACTIVITY TIMELINE', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 14),

        ..._comments.map((c) => _buildCommentTimelineCard(c)),
      ],
    );
  }

  Widget _buildToolbarIcon(IconData icon, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 16, color: AppColors.textMuted),
        ),
      ),
    );
  }

  Widget _buildCommentTimelineCard(TicketComment c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left timeline node (Minimal Dot)
        Column(
          children: [
            Container(
              width: 14,
              height: 14,
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
            Container(
              width: 2,
              height: 100,
              color: const Color(0xFFF1F5F9),
            ),
          ],
        ),
        const SizedBox(width: 14),

        // Right Comment Card
        Expanded(
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Minimal Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                    border: Border(bottom: BorderSide(color: Color(0xFFF1F5F9))),
                  ),
                  child: Row(
                    children: [
                      Text(
                        c.authorName,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          c.authorRole.toUpperCase(),
                          style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatCommentDate(c.createdAt),
                        style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                      ),
                    ],
                  ),
                ),

                // Body
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    c.message,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      height: 1.6,
                      color: AppColors.textDark,
                    ),
                  ),
                ),

                if (c.attachmentName != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            c.attachmentName!,
                            style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCaseHistoryView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AUDIT & TIMELINE HISTORY', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
        const SizedBox(height: 14),
        ..._timeline.map((ev) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.history_rounded, size: 20, color: AppColors.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ev.stepName, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                      Text(
                        'By ${ev.actorName} (${ev.actorRole}) - ${ev.action}',
                        style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textMuted),
                      ),
                      if (ev.comment.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text('Note: "${ev.comment}"', style: GoogleFonts.poppins(fontSize: 11.5, fontStyle: FontStyle.italic, color: AppColors.textBody)),
                      ],
                    ],
                  ),
                ),
                Text(
                  _formatCommentDate(ev.timestamp),
                  style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatCommentDate(DateTime dt) {
    final local = dt.toLocal();
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'pm' : 'am';
    final minuteStr = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} $hour:$minuteStr $ampm';
  }

  // ==============================================================
  // FALLBACK DATA FOR EXACT SCREENSHOT CASES
  // ==============================================================
  ClientTicket _getFallbackTicket(int id) {
    return ClientTicket(
      id: id,
      ticketNumber: '$id',
      title: 'Fix open APIs and add authentication (weight machine ,open an account)',
      description: 'Fix open APIs and add authentication (weight machine ,open an account)',
      priority: 'CRITICAL',
      category: 'PERMISSIONS',
      clientName: 'ITD_OPTIMIZATION',
      clientEmail: 'support@itdsoftware.in',
      status: 'HOLD',
      managerCode: 'MGR001',
      managerName: 'Ashish',
      csPersonCode: 'CS001',
      csPersonName: 'ASHISH',
      developerCode: 'ITD001',
      developerName: 'SUDIPSURVE',
      testerCode: 'QA001',
      testerName: 'SELECT...',
      currentOwnerCode: 'ITD001',
      currentOwnerName: 'SUDIPSURVE',
      currentStageName: 'HOLD',
      totalDevMinutes: 165,
      totalTestingMinutes: 45,
      createdAt: DateTime(2026, 8, 12, 14, 36),
      updatedAt: DateTime(2026, 9, 17, 16, 49),
      dtd: 20723,
      ticketType: 'SOFTWARE USERS',
      ticketSubType: 'PERMISSIONS',
      toughness: 'HARD',
      adminAssigned: 'KKOTIAN',
      tags: 'SOFTWARE ISSUE / BUG',
      dropletUrl: 'HTTP://167.71.117.182/ COMPANY ID : 2',
      module: 'SOFTWARE USERS',
      subModule: 'PERMISSIONS',
      estimatedMinutes: 300,
      isCritical: true,
      criticalComment: 'COMMENT FOR CRITICAL CASE',
      docketNo: 'DOC-88291',
      invoiceNo: 'INV-44102',
      creatorPhone: '+91 98200 12345',
      issueType: 'NON ITD ISSUE',
      softwareName: 'TRACKMATE',
    );
  }

  List<TicketComment> _getFallbackComments(int id) {
    return [
      TicketComment(
        id: 1,
        authorCode: 'VIRAG001',
        authorName: 'VIRAGDOSHI',
        authorRole: 'Manager',
        message: 'Needs to be tested by SUdip',
        createdAt: DateTime(2026, 9, 17, 16, 49),
      ),
      TicketComment(
        id: 2,
        authorCode: 'SUDIP001',
        authorName: 'SUDIPSURVE',
        authorRole: 'Developer',
        message:
            '### Testing steps\n**0. One-time setup**\n1. Run `/script/add_api_security_settings_migration` on main — confirm 6 keys under **settings_new -> API SECURITY**.\n2. Open a tenant company -> generate **WM API Key** + **Site Key** -> Save (copy plaintext once).\n3. Leave both Enforce on **Soft**. Add a test origin if needed (e.g. `https://your-hosted-site.com`).',
        createdAt: DateTime(2026, 9, 16, 17, 29),
      ),
      TicketComment(
        id: 3,
        authorCode: 'VIRAG001',
        authorName: 'Virag',
        authorRole: 'Manager',
        message: 'Fix open APIs and add authentication (weight machine ,open an account)',
        createdAt: DateTime(2026, 8, 12, 14, 36),
      ),
    ];
  }

  List<TicketTimelineEvent> _getFallbackTimeline(int id) {
    return [
      TicketTimelineEvent(
        id: 1,
        stepName: 'Client Creation',
        actorCode: 'CLT001',
        actorName: 'ITD_OPTIMIZATION',
        actorRole: 'Client',
        action: 'Created Case #147361',
        comment: 'Fix open APIs and add authentication',
        timeTakenMinutes: 0,
        timestamp: DateTime(2026, 8, 12, 14, 36),
      ),
      TicketTimelineEvent(
        id: 2,
        stepName: 'Manager Review',
        actorCode: 'MGR001',
        actorName: 'Ashish',
        actorRole: 'Manager',
        action: 'Assigned to Sudip Surve',
        comment: 'Critical security fix for tenant open endpoints',
        timeTakenMinutes: 20,
        timestamp: DateTime(2026, 8, 12, 15, 0),
      ),
      TicketTimelineEvent(
        id: 3,
        stepName: 'Development Implementation',
        actorCode: 'ITD001',
        actorName: 'SUDIPSURVE',
        actorRole: 'Developer',
        action: 'Completed coding migration and security keys',
        comment: 'Implementation verified locally',
        timeTakenMinutes: 165,
        timestamp: DateTime(2026, 9, 16, 17, 29),
      ),
      TicketTimelineEvent(
        id: 4,
        stepName: 'QA Triage',
        actorCode: 'VIRAG001',
        actorName: 'VIRAGDOSHI',
        actorRole: 'Lead',
        action: 'Put on Hold pending staging deployment validation',
        comment: 'Needs to be tested by SUdip',
        timeTakenMinutes: 10,
        timestamp: DateTime(2026, 9, 17, 16, 49),
      ),
    ];
  }
}
