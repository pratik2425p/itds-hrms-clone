import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/serverpod_service.dart';
import '../theme/app_colors.dart';
import '../models/hrms_models.dart';
import '../widgets/add_employee_dialog.dart';

class EmployeeDirectoryScreen extends StatefulWidget {
  final ValueChanged<Employee> onSelectEmployeeForProfile;

  const EmployeeDirectoryScreen({
    super.key,
    required this.onSelectEmployeeForProfile,
  });

  @override
  State<EmployeeDirectoryScreen> createState() => _EmployeeDirectoryScreenState();
}

class _EmployeeDirectoryScreenState extends State<EmployeeDirectoryScreen> {
  final List<Employee> _employees = [];
  Employee? _selectedEmployee;
  String _searchQuery = '';
  String _selectedLetter = 'All';
  String _selectedDepartment = 'All';
  bool _isLoading = false;

  final List<String> _alphabet = [
    'All', 'A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I',
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R', 'S',
    'T', 'U', 'V', 'W', 'X', 'Y', 'Z'
  ];

  final List<String> _departments = [
    'All',
    'Engineering',
    'Human Resources',
    'Quality Assurance',
    'Design',
    'Product',
    'Sales',
  ];

  @override
  void initState() {
    super.initState();
    _fetchEmployees();
  }

  Color _getAvatarColor(String code) {
    final colors = [
      AppColors.primaryOrange,
      const Color(0xFF6366F1),
      const Color(0xFF0284C7),
      const Color(0xFF10B981),
      const Color(0xFFEC4899),
      const Color(0xFF8B5CF6),
      const Color(0xFFF59E0B),
      const Color(0xFF14B8A6),
    ];
    final hash = code.hashCode.abs();
    return colors[hash % colors.length];
  }

  Future<void> _fetchEmployees() async {
    setState(() => _isLoading = true);
    try {
      final records = await ServerpodService().getEmployees();
      if (!mounted) return;
      setState(() {
        _employees.clear();
        for (final rec in records) {
          _employees.add(Employee(
            id: rec.id?.toString() ?? rec.code,
            code: rec.code,
            name: rec.name,
            initials: rec.initials.isNotEmpty ? rec.initials : (rec.name.isNotEmpty ? rec.name[0] : 'E'),
            avatarColor: _getAvatarColor(rec.code),
            role: rec.role,
            department: rec.department,
            joinedOn: rec.joinedOn ?? '01-Jan-2023',
            mobile: rec.mobile ?? '+91 98000 00000',
            branchLocation: rec.branchLocation ?? 'Mumbai HQ',
            email: rec.email,
            position: rec.position,
          ));
        }

        // Auto select first employee if none selected
        if (_selectedEmployee == null && _employees.isNotEmpty) {
          _selectedEmployee = _employees.first;
        } else if (_selectedEmployee != null) {
          final matched = _employees.where((e) => e.code == _selectedEmployee!.code).firstOrNull;
          if (matched != null) _selectedEmployee = matched;
        }
      });
    } catch (e) {
      debugPrint('Error fetching employees from backend: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddEmployeeDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddEmployeeDialog(
        onEmployeeAdded: _fetchEmployees,
      ),
    );
  }

  List<Employee> get _filteredEmployees {
    return _employees.where((emp) {
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          emp.name.toLowerCase().contains(query) ||
          emp.code.toLowerCase().contains(query) ||
          emp.role.toLowerCase().contains(query) ||
          emp.department.toLowerCase().contains(query);

      final matchesLetter = _selectedLetter == 'All' ||
          emp.name.toUpperCase().startsWith(_selectedLetter);

      final matchesDept = _selectedDepartment == 'All' ||
          emp.department.toLowerCase() == _selectedDepartment.toLowerCase();

      return matchesSearch && matchesLetter && matchesDept;
    }).toList();
  }

  Map<String, List<Employee>> get _groupedEmployees {
    final Map<String, List<Employee>> groups = {};
    for (final emp in _filteredEmployees) {
      final firstLetter = emp.name.isNotEmpty ? emp.name[0].toUpperCase() : '#';
      if (!groups.containsKey(firstLetter)) {
        groups[firstLetter] = [];
      }
      groups[firstLetter]!.add(emp);
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groupedEmployees;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top Filter Bar: Department Chips, Search & Add Employee button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Row(
              children: [
                // Department Chips (Horizontally scrollable)
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _departments.map((dept) {
                        final isSelected = _selectedDepartment == dept;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(dept),
                            selected: isSelected,
                            onSelected: (val) {
                              setState(() => _selectedDepartment = dept);
                            },
                            selectedColor: AppColors.primaryOrange.withValues(alpha: 0.15),
                            labelStyle: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primaryOrange : AppColors.textDark,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primaryOrange : AppColors.borderLight,
                            ),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Search Input
                Container(
                  width: 240,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Search Name, Code, Role...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textLight),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: InputBorder.none,
                      isDense: true,
                      prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.textMuted),
                    ),
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDark),
                  ),
                ),
                const SizedBox(width: 10),

                // Refresh Button
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20, color: AppColors.textMuted),
                  tooltip: 'Refresh Directory',
                  onPressed: _fetchEmployees,
                ),
                const SizedBox(width: 6),

                // Add Employee Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryOrange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _showAddEmployeeDialog,
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: Text(
                    'Add Employee',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Main Directory Content
          Expanded(
            child: Row(
              children: [
                // Left & Center: Employee Cards List
                Expanded(
                  flex: 7,
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange))
                      : groups.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.people_outline, size: 54, color: AppColors.textMuted),
                                  const SizedBox(height: 14),
                                  Text(
                                    _searchQuery.isEmpty && _selectedLetter == 'All' && _selectedDepartment == 'All'
                                        ? 'No Employees In Directory'
                                        : 'No employees match your search criteria',
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Click "Add Employee" above to add new staff members.',
                                    style: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                              children: [
                                for (final entry in groups.entries) ...[
                                  _buildLetterGroup(entry.key, entry.value),
                                  const SizedBox(height: 20),
                                ],
                              ],
                            ),
                ),

                // Alphabet Navigation Strip
                Container(
                  width: 32,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    itemCount: _alphabet.length,
                    itemBuilder: (context, index) {
                      final letter = _alphabet[index];
                      final isSelected = _selectedLetter == letter;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedLetter = letter;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            letter,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? AppColors.primaryOrange : AppColors.textMuted,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const VerticalDivider(width: 1, color: AppColors.border),

                // Right Pane: Employee Details Panel
                Expanded(
                  flex: 4,
                  child: _buildDetailsPanel(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterGroup(String letter, List<Employee> emps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primaryOrange,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 1,
                color: const Color(0xFFF1F5F9),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: emps.map((emp) => _buildEmployeeCard(emp)).toList(),
        ),
      ],
    );
  }

  Widget _buildEmployeeCard(Employee emp) {
    final isSelected = _selectedEmployee?.id == emp.id;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedEmployee = emp;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primaryOrange : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: AppColors.primaryOrange.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: emp.avatarColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  emp.initials,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    emp.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    emp.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primaryOrange,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${emp.department} • ${emp.code}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      color: AppColors.textMuted,
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

  Widget _buildDetailsPanel() {
    if (_selectedEmployee == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Employee Details',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const Spacer(),
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: Color(0xFF94A3B8)),
                    Positioned(
                      bottom: 24,
                      right: 24,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primaryOrange,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.touch_app, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select employee from the list to get employee details.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
            const Spacer(),
          ],
        ),
      );
    }

    final emp = _selectedEmployee!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Employee Details',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                onPressed: () {
                  setState(() {
                    _selectedEmployee = null;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: emp.avatarColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: emp.avatarColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  emp.initials,
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              emp.name,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
              ),
            ),
          ),
          Center(
            child: Text(
              '${emp.position} • ${emp.code}',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 16),

          _buildDetailRow(Icons.business, 'Department', emp.department),
          _buildDetailRow(Icons.email_outlined, 'Email', emp.email),
          _buildDetailRow(Icons.phone_outlined, 'Mobile', emp.mobile),
          _buildDetailRow(Icons.calendar_today_outlined, 'Joined On', emp.joinedOn),
          _buildDetailRow(Icons.location_on_outlined, 'Location', emp.branchLocation),

          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => widget.onSelectEmployeeForProfile(emp),
              icon: const Icon(Icons.person, size: 16),
              label: Text(
                'View & Edit Full Profile',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryOrange),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
