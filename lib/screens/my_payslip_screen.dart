import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hrms_client/hrms_client.dart';
import '../services/auth_service.dart';
import '../services/serverpod_service.dart';
import '../models/salary_breakdown.dart';
import '../utils/web_file_downloader.dart';
import '../theme/app_colors.dart';

class MyPayslipScreen extends StatefulWidget {
  const MyPayslipScreen({super.key});

  @override
  State<MyPayslipScreen> createState() => _MyPayslipScreenState();
}

class _MyPayslipScreenState extends State<MyPayslipScreen> {
  bool _isLoading = true;
  String _selectedMonth = 'October 2026';
  EmployeeRecord? _employee;
  SalaryBreakdown? _salary;

  String _bankName = 'HDFC Bank Ltd';
  String _accountNumber = '•••• •••• 5678';
  String _panNumber = 'ABCDE1234F';

  @override
  void initState() {
    super.initState();
    _loadSalaryData();
  }

  Future<void> _loadSalaryData() async {
    setState(() => _isLoading = true);
    try {
      final code = AuthService().employeeCode;
      final emp = await ServerpodService().getEmployeeByCode(code);
      if (emp != null) {
        final gross = double.tryParse(emp.gender ?? '') ?? 68000.0;
        final sal = SalaryBreakdown.fromGross(gross);

        // Try decode bank details from bloodGroup if present
        if (emp.bloodGroup != null && emp.bloodGroup!.startsWith('{')) {
          try {
            final data = jsonDecode(emp.bloodGroup!) as Map<String, dynamic>;
            _bankName = data['bankName'] ?? _bankName;
            _accountNumber = data['accountNo'] ?? _accountNumber;
            _panNumber = data['pan'] ?? _panNumber;
          } catch (_) {}
        }

        if (mounted) {
          setState(() {
            _employee = emp;
            _salary = sal;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading salary data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _downloadPayslip() {
    if (_employee == null || _salary == null) return;

    final htmlContent = WebFileDownloader.generatePayslipHtml(
      employeeName: _employee!.name,
      employeeCode: _employee!.code,
      designation: _employee!.role,
      department: _employee!.department,
      location: _employee!.branchLocation ?? 'Mumbai HQ',
      joinedOn: _employee!.joinedOn ?? '24-10-2026',
      monthYear: _selectedMonth,
      salary: _salary!,
      bankName: _bankName,
      accountNumber: _accountNumber,
      panNumber: _panNumber,
    );

    final fileName = 'Payslip_${_employee!.code}_${_selectedMonth.replaceAll(' ', '_')}.html';
    WebFileDownloader.downloadString(
      content: htmlContent,
      filename: fileName,
      mimeType: 'text/html;charset=utf-8',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payslip for $_selectedMonth downloaded successfully ($fileName)!'),
        backgroundColor: AppColors.presentGreen,
        action: SnackBarAction(
          label: 'Print/Save',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primaryOrange));
    }

    final emp = _employee;
    final salary = _salary ?? SalaryBreakdown.fromGross(68000.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month Selector and Download Action Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.primaryOrange),
                    const SizedBox(width: 8),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMonth,
                        items: ['October 2026', 'September 2026', 'August 2026']
                            .map((m) => DropdownMenuItem(value: m, child: Text(m, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedMonth = val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _downloadPayslip,
                icon: const Icon(Icons.download_rounded, size: 18, color: Colors.white),
                label: Text('Download Official PDF', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryOrange,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // KPI Cards
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'MONTHLY GROSS CTC',
                  '₹ ${salary.gross.toStringAsFixed(0)}',
                  'Company Compensation Structure',
                  const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'NET TAKE-HOME PAY',
                  '₹ ${salary.netPay.toStringAsFixed(0)}',
                  'Disbursed directly to Bank Account',
                  AppColors.presentGreen,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildMetricCard(
                  'STATUTORY DEDUCTIONS',
                  '₹ ${salary.deductions.toStringAsFixed(0)}',
                  'PF, PT & TDS Contributions',
                  AppColors.absentRed,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Official Payslip Voucher Card
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Company Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('LOGILEAD TECHNOLOGIES PVT. LTD.', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
                          const SizedBox(height: 4),
                          Text('Express Cargo & Logistics Park, Andheri East, Mumbai 400069', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFBFDBFE)),
                            ),
                            child: Text('OFFICIAL SALARY VOUCHER', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: const Color(0xFF1E40AF))),
                          ),
                          const SizedBox(height: 6),
                          Text('PAYSLIP: ${_selectedMonth.toUpperCase()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 20),

                  // Employee Details Grid
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _infoPair('Employee Name', emp?.name ?? 'Pratik nikam'),
                            _infoPair('Employee Code', emp?.code ?? 'ITD001'),
                            _infoPair('Department', emp?.department ?? 'Engineering'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _infoPair('Designation', emp?.role ?? 'Flutter Developer'),
                            _infoPair('Joining Date', emp?.joinedOn ?? '24-10-2026'),
                            _infoPair('Work Location', emp?.branchLocation ?? 'Mumbai HQ'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _infoPair('Bank Name', _bankName),
                            _infoPair('Bank Account', _accountNumber),
                            _infoPair('PAN Number', _panNumber),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Earnings vs Deductions Table
                  Table(
                    border: TableBorder.all(color: AppColors.border),
                    columnWidths: const {
                      0: FlexColumnWidth(3),
                      1: FlexColumnWidth(2),
                      2: FlexColumnWidth(3),
                      3: FlexColumnWidth(2),
                    },
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF1F5F9)),
                        children: [
                          _cell('EARNINGS', isHeader: true),
                          _cell('AMOUNT (₹)', isHeader: true, alignRight: true),
                          _cell('DEDUCTIONS', isHeader: true),
                          _cell('AMOUNT (₹)', isHeader: true, alignRight: true),
                        ],
                      ),
                      TableRow(
                        children: [
                          _cell('Basic Salary (50%)'),
                          _cell('₹ ${salary.basic.toStringAsFixed(2)}', alignRight: true),
                          _cell('Provident Fund (PF)'),
                          _cell('₹ ${salary.pf.toStringAsFixed(2)}', alignRight: true),
                        ],
                      ),
                      TableRow(
                        children: [
                          _cell('House Rent Allowance (HRA 25%)'),
                          _cell('₹ ${salary.hra.toStringAsFixed(2)}', alignRight: true),
                          _cell('Professional Tax (PT)'),
                          _cell('₹ ${salary.pt.toStringAsFixed(2)}', alignRight: true),
                        ],
                      ),
                      TableRow(
                        children: [
                          _cell('Special Allowance (25%)'),
                          _cell('₹ ${salary.special.toStringAsFixed(2)}', alignRight: true),
                          _cell('Income Tax (TDS)'),
                          _cell('₹ ${salary.tds.toStringAsFixed(2)}', alignRight: true),
                        ],
                      ),
                      TableRow(
                        children: [
                          _cell('Transport / Other Allowances'),
                          _cell('₹ 0.00', alignRight: true),
                          _cell('Loss of Pay (LOP)'),
                          _cell('₹ 0.00', alignRight: true),
                        ],
                      ),
                      TableRow(
                        decoration: const BoxDecoration(color: Color(0xFFF8FAFC)),
                        children: [
                          _cell('Gross Earnings', isBold: true),
                          _cell('₹ ${salary.gross.toStringAsFixed(2)}', isBold: true, alignRight: true),
                          _cell('Total Deductions', isBold: true),
                          _cell('₹ ${salary.deductions.toStringAsFixed(2)}', isBold: true, alignRight: true),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Net Take-Home Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFECFDF5),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFA7F3D0)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('NET TAKE-HOME PAY', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: const Color(0xFF065F46))),
                            const SizedBox(height: 4),
                            Text('In Words: ${salary.inWords}', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF047857), fontStyle: FontStyle.italic)),
                          ],
                        ),
                        Text('₹ ${salary.netPay.toStringAsFixed(2)}', style: GoogleFonts.outfit(fontSize: 26, fontWeight: FontWeight.w800, color: const Color(0xFF065F46))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String val, String sub, Color accent) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted, letterSpacing: 0.5)),
          const SizedBox(height: 8),
          Text(val, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: accent)),
          const SizedBox(height: 4),
          Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _infoPair(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textDark)),
        ],
      ),
    );
  }

  Widget _cell(String text, {bool isHeader = false, bool isBold = false, bool alignRight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Text(
        text,
        textAlign: alignRight ? TextAlign.right : TextAlign.left,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: isHeader || isBold ? FontWeight.w700 : FontWeight.w500,
          color: isHeader ? AppColors.textDark : AppColors.textDark,
        ),
      ),
    );
  }
}
