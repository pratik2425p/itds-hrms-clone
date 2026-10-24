import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/ticket_models.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';
import 'create_ticket_dialog.dart';
import 'ticket_detail_dialog.dart';

class TicketingScreen extends StatefulWidget {
  final String? currentUserCode;

  const TicketingScreen({
    super.key,
    this.currentUserCode,
  });

  @override
  State<TicketingScreen> createState() => _TicketingScreenState();
}

class _TicketingScreenState extends State<TicketingScreen> {
  bool _isLoading = true;
  List<ClientTicket> _allTickets = [];

  // Active Navigation Tab: 0 = Dashboard, 1 = All Cases, 2 = Case Dashboard, 3 = Developer Case
  int _activeTabIndex = 1;

  // Filter & Search states
  String _searchQuery = '';
  bool _showOnlyPriority = false;
  bool _showOnlyUnassigned = false;
  int _rowsPerPage = 50;

  // Top Bar Case Track Controller
  final TextEditingController _caseTrackController = TextEditingController();
  final ScrollController _tableHorizontalController = ScrollController();

  // Live Timer for Ongoing Case
  Timer? _liveTimer;
  Duration _activeCaseElapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadTickets();
    _liveTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _caseTrackController.dispose();
    _tableHorizontalController.dispose();
    super.dispose();
  }

  void _tick() {
    final active = _activeOngoingTicket;
    if (active != null && active.activeTimerStartTime != null) {
      final diff = DateTime.now().difference(active.activeTimerStartTime!);
      if (mounted) {
        setState(() {
          _activeCaseElapsed = diff.isNegative ? Duration.zero : diff;
        });
      }
    }
  }

  ClientTicket? get _activeOngoingTicket {
    try {
      return _allTickets.firstWhere((t) => t.isTimerRunning);
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadTickets() async {
    setState(() => _isLoading = true);
    final serverList = await ServerpodService().getTickets();

    // Default Seeded Tickets matching existing ITDS production system
    final sampleItdsTickets = _getSampleItdsTickets();

    // Merge: Serverpod tickets first, then ITDS tickets that are not duplicated
    final existingNumbers = serverList.map((t) => t.ticketNumber).toSet();
    final combined = <ClientTicket>[...serverList];
    for (final itds in sampleItdsTickets) {
      if (!existingNumbers.contains(itds.ticketNumber)) {
        combined.add(itds);
      }
    }

    if (mounted) {
      setState(() {
        _allTickets = combined;
        _isLoading = false;
      });
      _tick();
    }
  }

  List<ClientTicket> get _currentDisplayTickets {
    var list = List<ClientTicket>.from(_allTickets);

    // Tab 3: Developer Case filter (assigned to current developer or SUDIPSURVE / pratiknikam)
    if (_activeTabIndex == 3) {
      list = list.where((t) {
        final dev = (t.developerName.isNotEmpty ? t.developerName : t.currentOwnerName).toLowerCase();
        final code = t.developerCode.toLowerCase();
        final myCode = (widget.currentUserCode ?? 'ITD001').toLowerCase();
        return dev.contains('pratik') || dev.contains('sudip') || code == myCode || dev.contains('kkot');
      }).toList();
    }

    // Priority filter
    if (_showOnlyPriority) {
      list = list.where((t) => t.priority == 'HIGH' || t.priority == 'CRITICAL' || t.isCritical).toList();
    }

    // Unassigned filter
    if (_showOnlyUnassigned) {
      list = list.where((t) => t.status == 'CREATED' || t.developerName.isEmpty).toList();
    }

    // Search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) {
        return t.ticketNumber.toLowerCase().contains(q) ||
            t.title.toLowerCase().contains(q) ||
            t.clientName.toLowerCase().contains(q) ||
            t.ticketType.toLowerCase().contains(q) ||
            t.ticketSubType.toLowerCase().contains(q) ||
            t.status.toLowerCase().contains(q) ||
            t.developerName.toLowerCase().contains(q);
      }).toList();
    }

    return list;
  }

  void _openTicketDetail(int ticketId) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TicketDetailDialog(
        ticketId: ticketId,
        onTicketUpdated: _loadTickets,
      ),
    );
  }

  void _openCreateTicketDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => CreateTicketDialog(
        onTicketCreated: _loadTickets,
      ),
    );
  }

  void _trackCase() {
    final query = _caseTrackController.text.trim();
    if (query.isEmpty) return;

    final match = _allTickets.firstWhere(
      (t) => t.ticketNumber.toLowerCase() == query.toLowerCase() || t.ticketNumber.contains(query),
      orElse: () => _allTickets.first,
    );

    _openTicketDetail(match.id);
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(d.inHours);
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final activeTicket = _activeOngoingTicket;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      body: Column(
        children: [
          // 1. TOP GLOBAL ITDS BAR (Clean & Minimal)
          _buildTopGlobalBar(),

          // 2. MINIMAL STATUS BANNER (Light Rose / Light Emerald)
          _buildOngoingCaseBanner(activeTicket),

          // 3. MINIMAL SUB NAVIGATION PILL TABS
          _buildSubNavTabs(),

          // 4. MAIN CONTENT VIEW
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: _buildTabContent(),
                  ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 1. TOP GLOBAL BAR (Clean, Minimal, LogiLead Style)
  // ==============================================================
  Widget _buildTopGlobalBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Authentic ITD Brand Logo Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: const Color(0xFF0F3460), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'ITD',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF0F3460),
                      letterSpacing: 2.2,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 1.5),
                  Text(
                    'INTELLIGENT TECHNOLOGY DEVELOPMENT',
                    style: GoogleFonts.poppins(
                      fontSize: 5.0,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFB91C1C),
                      letterSpacing: 0.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Quick Navigation Links
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                foregroundColor: AppColors.textBody,
              ),
              child: Text(
                'Masters',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                foregroundColor: AppColors.textBody,
              ),
              child: Text(
                'Leave Application',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),

            // CASE TRACK Search Box (Minimal Pill)
            Container(
              width: 140,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorder),
              ),
              child: TextField(
                controller: _caseTrackController,
                onSubmitted: (_) => _trackCase(),
                style: GoogleFonts.poppins(fontSize: 11.5),
                decoration: InputDecoration(
                  hintText: 'Case Track...',
                  hintStyle: GoogleFonts.poppins(fontSize: 11, color: AppColors.textLight),
                  prefixIcon: const Icon(Icons.search, size: 14, color: AppColors.textMuted),
                  contentPadding: const EdgeInsets.symmetric(vertical: 7),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),

            // User Productivity Pill (Soft Slate)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFF10B981),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Pratik Nikam (Productivity)',
                    style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Minimal Pastel Badges: HOLD QUEUE & UNASSIGNED
            _buildPastelBadge('Hold Queue: 5', const Color(0xFFFEF3C7), const Color(0xFFB45309)),
            const SizedBox(width: 6),
            _buildPastelBadge('Unassigned: 1', const Color(0xFFE0F2FE), const Color(0xFF0369A1)),
            const SizedBox(width: 8),

            // Updates Button
            OutlinedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All ticket pipelines operating in normal SLA.')),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                minimumSize: const Size(0, 30),
                side: const BorderSide(color: AppColors.cardBorder),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                'Updates',
                style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textBody),
              ),
            ),
            const SizedBox(width: 6),

            // New Ticket Button
            ElevatedButton.icon(
              onPressed: _openCreateTicketDialog,
              icon: const Icon(Icons.add, size: 13),
              label: Text('New Ticket', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                minimumSize: const Size(0, 30),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPastelBadge(String label, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w600, color: textColor),
      ),
    );
  }

  // ==============================================================
  // 2. ONGOING CASE BANNER (Minimal Soft Surface)
  // ==============================================================
  Widget _buildOngoingCaseBanner(ClientTicket? activeTicket) {
    if (activeTicket != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
        decoration: const BoxDecoration(
          color: Color(0xFFECFDF5),
          border: Border(bottom: BorderSide(color: Color(0xFFA7F3D0))),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF10B981),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Active Ticket Timer: #${activeTicket.ticketNumber} — ${activeTicket.title}',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF065F46),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '⏱ ${_formatDuration(_activeCaseElapsed)}',
                style: GoogleFonts.poppins(fontSize: 11.5, fontWeight: FontWeight.w700, color: const Color(0xFF047857)),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () => _openTicketDetail(activeTicket.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF047857),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                elevation: 0,
                minimumSize: const Size(0, 28),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
              child: Text('Open Ticket', style: GoogleFonts.poppins(fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF94A3B8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'No ongoing active ticket session. Select a case from the list below to begin work.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================================================
  // 3. SUB NAVIGATION PILL TABS
  // ==============================================================
  Widget _buildSubNavTabs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.cardBorder)),
      ),
      child: Row(
        children: [
          _buildNavPill(0, 'Dashboard', Icons.grid_view_rounded),
          const SizedBox(width: 8),
          _buildNavPill(1, 'All Cases', Icons.list_alt_rounded),
          const SizedBox(width: 8),
          _buildNavPill(2, 'Case Dashboard', Icons.speed_rounded),
          const SizedBox(width: 8),
          _buildNavPill(3, 'Developer Case', Icons.code_rounded),
        ],
      ),
    );
  }

  Widget _buildNavPill(int index, String label, IconData icon) {
    final isSelected = _activeTabIndex == index;
    return InkWell(
      onTap: () => setState(() => _activeTabIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppColors.primary : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // 4. MAIN TAB CONTENT ROUTING
  // ==============================================================
  Widget _buildTabContent() {
    switch (_activeTabIndex) {
      case 0:
        return _buildGeneralDashboardView();
      case 1:
        return _buildCasesTableView(isDevOnly: false);
      case 2:
        return _buildCaseDashboardView();
      case 3:
        return _buildCasesTableView(isDevOnly: true);
      default:
        return _buildCasesTableView(isDevOnly: false);
    }
  }

  // ==============================================================
  // TAB 1 & 3: CASES TABLE VIEW (All Cases & Developer Case)
  // ==============================================================
  Widget _buildCasesTableView({required bool isDevOnly}) {
    final tickets = _currentDisplayTickets;
    final totalOpen = _allTickets.where((t) => t.status != 'CLOSED_RESOLVED').length;
    final unassignedCount = _allTickets.where((t) => t.status == 'CREATED' || t.developerName.isEmpty).length;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter Badges & Buttons Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (!isDevOnly) ...[
                  // Stat Pill: Open Case Count
                  _buildFilterStatChip('Open Cases', '$totalOpen', AppColors.primary),
                  const SizedBox(width: 8),
                  _buildFilterStatChip('Unassigned', '$unassignedCount', const Color(0xFFF59E0B)),
                  const SizedBox(width: 14),
                ],

                // SHOW PRIORITY CASE Button (Minimal Outlined / Filled Pill)
                _buildFilterToggleButton(
                  label: 'Priority Cases',
                  isActive: _showOnlyPriority,
                  activeColor: const Color(0xFFDC2626),
                  onTap: () => setState(() => _showOnlyPriority = !_showOnlyPriority),
                ),
                const SizedBox(width: 8),

                if (!isDevOnly) ...[
                  // OPEN UNASSIGNED CASE Button
                  _buildFilterToggleButton(
                    label: 'Unassigned Cases',
                    isActive: _showOnlyUnassigned,
                    activeColor: AppColors.primary,
                    onTap: () => setState(() => _showOnlyUnassigned = !_showOnlyUnassigned),
                  ),
                  const SizedBox(width: 8),
                ],

                // EXPORT Button
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Exporting report as CSV/Excel...')),
                    );
                  },
                  icon: const Icon(Icons.download, size: 15, color: AppColors.textBody),
                  label: Text(
                    'Export',
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textBody),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.cardBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Search and Show Entries Row
          Row(
            children: [
              // Entries dropdown
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _rowsPerPage,
                    style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textDark, fontWeight: FontWeight.w600),
                    items: const [
                      DropdownMenuItem(value: 10, child: Text('10 rows')),
                      DropdownMenuItem(value: 25, child: Text('25 rows')),
                      DropdownMenuItem(value: 50, child: Text('50 rows')),
                      DropdownMenuItem(value: 100, child: Text('100 rows')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _rowsPerPage = v);
                    },
                  ),
                ),
              ),
              const Spacer(),

              // Search Box
              Container(
                width: 280,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.poppins(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Search by Case No, Title, Client...',
                    hintStyle: GoogleFonts.poppins(fontSize: 12, color: AppColors.textLight),
                    prefixIcon: const Icon(Icons.search, size: 16, color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Minimalist Clean Data Table with Scrollbar
          Scrollbar(
            controller: _tableHorizontalController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _tableHorizontalController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 1480),
                child: Table(
                  border: const TableBorder(
                    horizontalInside: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                    bottom: BorderSide(color: AppColors.cardBorder, width: 1),
                  ),
                  columnWidths: isDevOnly
                      ? const {
                          0: FixedColumnWidth(95),  // CASE NO
                          1: FixedColumnWidth(270), // TITLE
                          2: FixedColumnWidth(55),  // DTD
                          3: FixedColumnWidth(125), // TKT TYPE
                          4: FixedColumnWidth(125), // TKT SUB TYPE
                          5: FixedColumnWidth(145), // CREATED DATE
                          6: FixedColumnWidth(150), // CLIENT
                          7: FixedColumnWidth(150), // STATUS
                          8: FixedColumnWidth(95),  // TOUGHNESS
                          9: FixedColumnWidth(120), // ALLOCATED TO
                        }
                      : const {
                          0: FixedColumnWidth(95),  // CASE NO
                          1: FixedColumnWidth(270), // TITLE
                          2: FixedColumnWidth(55),  // DTD
                          3: FixedColumnWidth(125), // TKT TYPE
                          4: FixedColumnWidth(125), // TKT SUB TYPE
                          5: FixedColumnWidth(145), // CREATED DATE
                          6: FixedColumnWidth(150), // CLIENT
                          7: FixedColumnWidth(150), // STATUS
                          8: FixedColumnWidth(110), // ASSIGNED TO
                          9: FixedColumnWidth(95),  // ADMIN ASSIGNED
                          10: FixedColumnWidth(95), // TESTER ASSIGNED
                          11: FixedColumnWidth(95), // CREATED BY
                        },
                  children: [
                    // Minimal Table Header Row (Light Slate Background)
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Color(0xFFF8FAFC),
                        border: Border(bottom: BorderSide(color: AppColors.cardBorder, width: 1.5)),
                      ),
                      children: isDevOnly
                          ? [
                              _buildTableHeaderCell('CASE NO.'),
                              _buildTableHeaderCell('TITLE', align: TextAlign.left),
                              _buildTableHeaderCell('DTD'),
                              _buildTableHeaderCell('TKT TYPE', align: TextAlign.left),
                              _buildTableHeaderCell('SUB TYPE', align: TextAlign.left),
                              _buildTableHeaderCell('CREATED DATE'),
                              _buildTableHeaderCell('CLIENT', align: TextAlign.left),
                              _buildTableHeaderCell('STATUS'),
                              _buildTableHeaderCell('TOUGHNESS'),
                              _buildTableHeaderCell('ALLOCATED'),
                            ]
                          : [
                              _buildTableHeaderCell('CASE NO.'),
                              _buildTableHeaderCell('TITLE', align: TextAlign.left),
                              _buildTableHeaderCell('DTD'),
                              _buildTableHeaderCell('TKT TYPE', align: TextAlign.left),
                              _buildTableHeaderCell('SUB TYPE', align: TextAlign.left),
                              _buildTableHeaderCell('CREATED DATE'),
                              _buildTableHeaderCell('CLIENT', align: TextAlign.left),
                              _buildTableHeaderCell('STATUS'),
                              _buildTableHeaderCell('ASSIGNED TO'),
                              _buildTableHeaderCell('ADMIN'),
                              _buildTableHeaderCell('TESTER'),
                              _buildTableHeaderCell('CREATED BY'),
                            ],
                    ),

                    // Data Rows (Clean White Background)
                    ...tickets.take(_rowsPerPage).map((t) {
                      return TableRow(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                        ),
                        children: isDevOnly
                            ? [
                                _buildCaseNoCell(t),
                                _buildTitleCell(t),
                                _buildTableCell('${t.dtd}', align: TextAlign.center),
                                _buildTableCell(t.ticketType),
                                _buildTableCell(t.ticketSubType),
                                _buildTableCell(_formatCreatedDate(t.createdAt)),
                                _buildTableCell(t.clientName),
                                _buildStatusPillCell(t),
                                _buildTableCell(t.toughness.isEmpty ? '-' : t.toughness, align: TextAlign.center),
                                _buildTableCell(t.developerName.isNotEmpty ? t.developerName : 'SudipSurve'),
                              ]
                            : [
                                _buildCaseNoCell(t),
                                _buildTitleCell(t),
                                _buildTableCell('${t.dtd}', align: TextAlign.center),
                                _buildTableCell(t.ticketType),
                                _buildTableCell(t.ticketSubType),
                                _buildTableCell(_formatCreatedDate(t.createdAt)),
                                _buildTableCell(t.clientName),
                                _buildStatusPillCell(t),
                                _buildTableCell(t.developerName.isNotEmpty ? t.developerName : 'Unassigned'),
                                _buildTableCell(t.adminAssigned),
                                _buildTableCell(t.testerName.isNotEmpty ? t.testerName : 'Rahul Patil'),
                                _buildTableCell(t.clientName),
                              ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Pagination Footer Text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing 1 to ${tickets.length < _rowsPerPage ? tickets.length : _rowsPerPage} of ${tickets.length} entries',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
              ),
              Text(
                'Total Pipeline: ${_allTickets.length} active tickets',
                style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textLight),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterStatChip(String label, String count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark),
          ),
          Text(
            count,
            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterToggleButton({
    required String label,
    required bool isActive,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive ? activeColor : AppColors.cardBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: isActive ? activeColor : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // TAB 2: CASE DASHBOARD VIEW (Minimal Profile & Stats)
  // ==============================================================
  Widget _buildCaseDashboardView() {
    return Column(
      children: [
        // User Profile Card
        Container(
          width: 800,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Developer Workload & Attendance Profile',
                style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Current active engineer session, hold timers, and productivity metrics.',
                style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 20),
              _buildCaseDashRow('Name', 'pratiknikam', isDropdown: true),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildCaseDashRow('Role', 'DEVELOPER'),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildCaseDashRow('Login Time', '24/10/2026 02:22 PM'),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildCaseDashRow('Hold Queue Time', '00:00:00'),
              const Divider(height: 24, color: Color(0xFFF1F5F9)),
              _buildCaseDashRow('Total Aux', '00:00:00'),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Ticket Status Breakdown Table
        Container(
          width: 800,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ticket Status Workload Summary',
                      style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download, size: 14, color: AppColors.textBody),
                      label: Text('Export Summary', style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textBody)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.cardBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                    ),
                  ],
                ),
              ),
              Table(
                border: const TableBorder(
                  horizontalInside: BorderSide(color: Color(0xFFF1F5F9), width: 1),
                  top: BorderSide(color: AppColors.cardBorder, width: 1),
                ),
                children: [
                  TableRow(
                    decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                    children: [
                      _buildTableHeaderCell('TICKET STATUS', align: TextAlign.left),
                      _buildTableHeaderCell('NORMAL'),
                      _buildTableHeaderCell('PRIORITY'),
                      _buildTableHeaderCell('TOTAL CASES'),
                    ],
                  ),
                  _buildSummaryTableRow('DEVELOPMENT IN PROGRESS', '2', '1', '3'),
                  _buildSummaryTableRow('HOLD', '4', '2', '6'),
                  _buildSummaryTableRow('DEVELOPMENT', '2', '0', '2'),
                  _buildSummaryTableRow('PULL REQUEST RAISED', '1', '1', '2'),
                  _buildSummaryTableRow('TEST FAILED', '1', '0', '1'),
                  _buildSummaryTableRow('TOTAL', '10', '4', '14', isBold: true),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCaseDashRow(String label, String value, {bool isDropdown = false}) {
    return Row(
      children: [
        SizedBox(
          width: 180,
          child: Text(
            label,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textMuted),
          ),
        ),
        Expanded(
          child: isDropdown
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    border: Border.all(color: AppColors.cardBorder),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(value, style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark)),
                      const Icon(Icons.arrow_drop_down, size: 20, color: AppColors.textMuted),
                    ],
                  ),
                )
              : Text(
                  value,
                  style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textDark),
                ),
        ),
      ],
    );
  }

  TableRow _buildSummaryTableRow(String status, String normal, String priority, String total, {bool isBold = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isBold ? const Color(0xFFF8FAFC) : Colors.white,
      ),
      children: [
        _buildTableCell(status, isBold: isBold),
        _buildTableCell(normal, align: TextAlign.center, isBold: isBold),
        _buildTableCell(priority, align: TextAlign.center, isBold: isBold),
        _buildTableCell(total, align: TextAlign.center, isBold: isBold),
      ],
    );
  }

  // ==============================================================
  // TAB 0: GENERAL OVERVIEW DASHBOARD
  // ==============================================================
  Widget _buildGeneralDashboardView() {
    final devCount = _allTickets.where((t) => t.status.contains('DEV')).length;
    final holdCount = _allTickets.where((t) => t.status.contains('HOLD')).length;
    final qaCount = _allTickets.where((t) => t.status.contains('TEST')).length;
    final resolvedCount = _allTickets.where((t) => t.status.contains('RESOLVED') || t.status.contains('CLOSED')).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildStatCard('All Open Cases', '${_allTickets.length}', AppColors.primary, Icons.assignment_outlined),
            const SizedBox(width: 14),
            _buildStatCard('Dev In Progress', '$devCount', const Color(0xFFDC2626), Icons.code_rounded),
            const SizedBox(width: 14),
            _buildStatCard('Hold Queue', '$holdCount', const Color(0xFFD97706), Icons.pause_circle_outline),
            const SizedBox(width: 14),
            _buildStatCard('QA Testing Queue', '$qaCount', const Color(0xFF0284C7), Icons.bug_report_outlined),
            const SizedBox(width: 14),
            _buildStatCard('Closed / Resolved', '$resolvedCount', const Color(0xFF10B981), Icons.check_circle_outline),
          ],
        ),
        const SizedBox(height: 20),
        _buildCasesTableView(isDevOnly: false),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  Text(label, style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==============================================================
  // TABLE CELLS & FORMATTERS (Minimal & Modern)
  // ==============================================================
  Widget _buildTableHeaderCell(String text, {TextAlign align = TextAlign.center}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        textAlign: align,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.textMuted,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildTableCell(String text, {TextAlign align = TextAlign.left, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Text(
        text,
        textAlign: align,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          color: AppColors.textDark,
        ),
      ),
    );
  }

  Widget _buildCaseNoCell(ClientTicket t) {
    return InkWell(
      onTap: () => _openTicketDetail(t.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Text(
          t.ticketNumber,
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1D4ED8),
            decoration: TextDecoration.underline,
            decorationColor: const Color(0xFF93C5FD),
          ),
        ),
      ),
    );
  }

  Widget _buildTitleCell(ClientTicket t) {
    return InkWell(
      onTap: () => _openTicketDetail(t.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: t.isCritical ? FontWeight.w700 : FontWeight.w500,
                color: t.isCritical ? const Color(0xFFB91C1C) : AppColors.textDark,
                height: 1.35,
              ),
            ),
            if (t.isCritical) ...[
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(3),
                  border: Border.all(color: const Color(0xFFFCA5A5), width: 0.5),
                ),
                child: Text(
                  'CRITICAL SLA',
                  style: GoogleFonts.poppins(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFDC2626),
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusPillCell(ClientTicket t) {
    final statusText = t.itdsStatus;
    final color = t.statusColor;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Text(
          statusText,
          textAlign: TextAlign.center,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  String _formatCreatedDate(DateTime dt) {
    final local = dt.toLocal();
    final months = ['01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'];
    final hour = local.hour > 12 ? local.hour - 12 : (local.hour == 0 ? 12 : local.hour);
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final minuteStr = local.minute.toString().padLeft(2, '0');
    final dayStr = local.day.toString().padLeft(2, '0');
    return '$dayStr-${months[local.month - 1]}-${local.year} $hour:$minuteStr $ampm';
  }

  // ==============================================================
  // SAMPLE SEEDED ITDS TICKETS (Directly from User Screenshots)
  // ==============================================================
  List<ClientTicket> _getSampleItdsTickets() {
    return [
      ClientTicket(
        id: 147361,
        ticketNumber: '147361',
        title: 'Fix open APIs and add authentication (weight machine ,open an account)',
        description: 'Fix open APIs and add authentication (weight machine ,open an account). Ensure tenant API key + Site key validation.',
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
        criticalComment: 'High security impact - API authentication check required immediately.',
      ),
      ClientTicket(
        id: 151280,
        ticketNumber: '151280',
        title: 'Custmer portal PRermission UI - kk ....',
        description: 'Customer portal user role and permission access management module UI fix.',
        priority: 'HIGH',
        category: 'CUTOMER PORTAL',
        clientName: 'NEX_NAVALAI_COURIER',
        clientEmail: 'ops@navalai.com',
        status: 'DEVELOPMENT IN PROGRESS',
        managerCode: 'MGR001',
        managerName: 'Ashish',
        csPersonCode: 'CS001',
        csPersonName: 'Sneha Kulkarni',
        developerCode: 'ITD001',
        developerName: 'pratiknikam',
        testerCode: 'QA001',
        testerName: 'Rahul Patil',
        currentOwnerCode: 'ITD001',
        currentOwnerName: 'pratiknikam',
        currentStageName: 'DEVELOPMENT IN PROGRESS',
        totalDevMinutes: 90,
        totalTestingMinutes: 0,
        createdAt: DateTime(2026, 10, 23, 17, 3),
        updatedAt: DateTime(2026, 10, 24, 11, 0),
        dtd: 2,
        ticketType: 'CUTOMER PORTAL',
        ticketSubType: 'PERMISSIONS',
        toughness: 'MEDIUM',
        adminAssigned: 'KKOTIAN',
        tags: 'SOFTWARE ISSUE / BUG',
      ),
      ClientTicket(
        id: 151076,
        ticketNumber: '151076',
        title: 'Annexure Formate',
        description: 'Manifest annexure export formatting update for bulk bookings.',
        priority: 'MEDIUM',
        category: 'SOFTWARE USERS',
        clientName: 'RM_EXPRESS',
        clientEmail: 'billing@rmexpress.in',
        status: 'DEVELOPMENT IN PROGRESS',
        managerCode: 'MGR001',
        managerName: 'Ashish',
        csPersonCode: 'CS001',
        csPersonName: 'Sneha',
        developerCode: 'ITD002',
        developerName: 'tushar',
        testerCode: '',
        testerName: '',
        currentOwnerCode: 'ITD002',
        currentOwnerName: 'tushar',
        currentStageName: 'DEVELOPMENT IN PROGRESS',
        totalDevMinutes: 45,
        totalTestingMinutes: 0,
        createdAt: DateTime(2026, 10, 19, 14, 30),
        updatedAt: DateTime(2026, 10, 20, 16, 0),
        dtd: 1,
        ticketType: 'SOFTWARE USERS',
        ticketSubType: 'USER CREATION',
        adminAssigned: 'KKOTIAN',
      ),
      ClientTicket(
        id: 138330,
        ticketNumber: '138330',
        title: 'Get all billing and unwanted data at the time of creation ....',
        description: 'Auto-populate billing fields and prevent unwanted default cache data during client AWB generation.',
        priority: 'HIGH',
        category: 'AWB ENTRY',
        clientName: 'ITD_OPTIMIZATION',
        clientEmail: 'info@itdoptimization.com',
        status: 'HOLD',
        managerCode: 'MGR001',
        managerName: 'Ashish',
        csPersonCode: 'CS001',
        csPersonName: 'Sneha',
        developerCode: 'ITD001',
        developerName: 'VIRAGDOSHI',
        testerCode: '',
        testerName: '',
        currentOwnerCode: 'ITD001',
        currentOwnerName: 'VIRAGDOSHI',
        currentStageName: 'HOLD',
        totalDevMinutes: 120,
        totalTestingMinutes: 0,
        createdAt: DateTime(2026, 3, 3, 15, 58),
        updatedAt: DateTime(2026, 3, 4, 12, 0),
        dtd: 235,
        ticketType: 'AWB ENTRY',
        ticketSubType: 'AWB ENTRY ERROR',
        adminAssigned: 'VIRAGDOSHI',
      ),
      ClientTicket(
        id: 142125,
        ticketNumber: '142125',
        title: 'Issue Analyzer Engine',
        description: 'Automated ML/Regex rule engine for scanning AWB entry anomalies.',
        priority: 'MEDIUM',
        category: 'AWB ENTRY',
        clientName: 'ITD_OPTIMIZATION',
        clientEmail: 'support@itdsoftware.in',
        status: 'DEVELOPMENT',
        managerCode: 'MGR001',
        managerName: 'Ashish',
        csPersonCode: 'CS001',
        csPersonName: 'Sneha',
        developerCode: 'ITD001',
        developerName: 'VIRAGDOSHI',
        testerCode: 'QA001',
        testerName: 'Rahul',
        currentOwnerCode: 'ITD001',
        currentOwnerName: 'VIRAGDOSHI',
        currentStageName: 'DEVELOPMENT',
        totalDevMinutes: 200,
        totalTestingMinutes: 0,
        createdAt: DateTime(2026, 5, 6, 18, 24),
        updatedAt: DateTime(2026, 5, 7, 10, 0),
        dtd: 171,
        ticketType: 'AWB ENTRY',
        ticketSubType: 'AWB ENTRY ERROR',
        adminAssigned: 'VIRAGDOSHI',
      ),
      ClientTicket(
        id: 150145,
        ticketNumber: '150145',
        title: 'new UI for the customer portal ....',
        description: 'Customer portal modernized look and feel matching latest LogiLead design system.',
        priority: 'MEDIUM',
        category: 'AWB ENTRY',
        clientName: 'Stelcore360',
        clientEmail: 'support@stelcore360.com',
        status: 'PULL REQUEST RAISED',
        managerCode: 'MGR001',
        managerName: 'Ashish',
        csPersonCode: 'CS001',
        csPersonName: 'Sneha',
        developerCode: 'ITD001',
        developerName: 'VIRAGDOSHI',
        testerCode: 'QA001',
        testerName: 'Rahul Patil',
        currentOwnerCode: 'ITD001',
        currentOwnerName: 'VIRAGDOSHI',
        currentStageName: 'PULL REQUEST RAISED',
        totalDevMinutes: 240,
        totalTestingMinutes: 30,
        createdAt: DateTime(2026, 9, 29, 20, 45),
        updatedAt: DateTime(2026, 10, 1, 14, 0),
        dtd: 20,
        ticketType: 'AWB ENTRY',
        ticketSubType: 'AWB ENTRY ERROR',
        adminAssigned: 'VIRAGDOSHI',
      ),
      ClientTicket(
        id: 149260,
        ticketNumber: '149260',
        title: 'AFTER BOOKING IN NEW QUICK SCAN AWN ENTRY IT IS NOT CAPTURIN ....',
        description: 'Quick scan barcode reader timeout resulting in uncaptured AWB weight fields.',
        priority: 'HIGH',
        category: 'AWB ENTRY',
        clientName: 'HILIFT_EXP',
        clientEmail: 'dispatch@hiliftexp.in',
        status: 'TEST FAILED',
        managerCode: 'MGR001',
        managerName: 'Ashish',
        csPersonCode: 'CS001',
        csPersonName: 'Sneha',
        developerCode: 'ITD001',
        developerName: 'SUDIPSURVE',
        testerCode: 'QA001',
        testerName: 'Rahul Patil',
        currentOwnerCode: 'ITD001',
        currentOwnerName: 'SUDIPSURVE',
        currentStageName: 'TEST FAILED',
        totalDevMinutes: 180,
        totalTestingMinutes: 60,
        createdAt: DateTime(2026, 9, 15, 17, 22),
        updatedAt: DateTime(2026, 9, 18, 11, 0),
        dtd: 12,
        ticketType: 'AWB ENTRY',
        ticketSubType: 'AWB ENTRY ERROR',
        adminAssigned: 'KKOTIAN',
      ),
    ];
  }
}
