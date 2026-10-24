// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/salary_breakdown.dart';

class WebFileDownloader {
  /// Download raw text/csv/html content as a file in the browser
  static void downloadString({
    required String content,
    required String filename,
    String mimeType = 'text/plain;charset=utf-8',
  }) {
    if (!kIsWeb) return;
    try {
      final bytes = utf8.encode(content);
      final blob = html.Blob([bytes], mimeType);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      debugPrint('Failed to download file in web: $e');
    }
  }

  /// Generate a formal printable HTML payslip document that can be printed or saved as PDF
  static String generatePayslipHtml({
    required String employeeName,
    required String employeeCode,
    required String designation,
    required String department,
    required String location,
    required String joinedOn,
    required String monthYear,
    required SalaryBreakdown salary,
    String bankName = 'HDFC Bank Ltd',
    String accountNumber = '•••• •••• 5678',
    String panNumber = 'ABCDE1234F',
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Payslip_${employeeCode}_${monthYear.replaceAll(' ', '_')}</title>
  <style>
    @page { size: A4; margin: 15mm; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      color: #1e293b;
      margin: 0;
      padding: 24px;
      background-color: #f8fafc;
    }
    .payslip-container {
      max-width: 800px;
      margin: 0 auto;
      background: #ffffff;
      border: 1px solid #cbd5e1;
      border-radius: 8px;
      padding: 32px;
      box-shadow: 0 4px 6px -1px rgba(0, 0, 0, 0.1);
    }
    .header-table { width: 100%; border-bottom: 2px solid #0f172a; padding-bottom: 16px; margin-bottom: 20px; }
    .company-name { font-size: 22px; font-weight: 800; color: #0f172a; letter-spacing: 0.5px; }
    .company-sub { font-size: 12px; color: #64748b; margin-top: 4px; }
    .badge { background: #eff6ff; color: #1d4ed8; padding: 4px 10px; border-radius: 4px; font-size: 11px; font-weight: bold; border: 1px solid #bfdbfe; }
    .info-grid {
      display: grid;
      grid-template-columns: repeat(3, 1fr);
      gap: 12px;
      background: #f8fafc;
      border: 1px solid #e2e8f0;
      border-radius: 6px;
      padding: 14px;
      margin-bottom: 24px;
      font-size: 12px;
    }
    .info-item span { display: block; }
    .info-label { color: #64748b; font-weight: 500; font-size: 11px; text-transform: uppercase; margin-bottom: 2px; }
    .info-val { color: #0f172a; font-weight: 600; font-size: 13px; }
    
    table.breakdown-table {
      width: 100%;
      border-collapse: collapse;
      margin-bottom: 20px;
      font-size: 12px;
    }
    table.breakdown-table th {
      background-color: #f1f5f9;
      color: #0f172a;
      text-align: left;
      padding: 10px 14px;
      border: 1px solid #cbd5e1;
      font-weight: 700;
    }
    table.breakdown-table td {
      padding: 9px 14px;
      border: 1px solid #e2e8f0;
    }
    .text-right { text-align: right; }
    .font-bold { font-weight: 700; }
    .bg-subtotal { background-color: #f8fafc; font-weight: bold; }
    
    .net-banner {
      background: #ecfdf5;
      border: 1px solid #a7f3d0;
      border-radius: 6px;
      padding: 16px 20px;
      display: flex;
      justify-content: space-between;
      align-items: center;
      margin-bottom: 24px;
    }
    .net-title { font-size: 12px; font-weight: 700; color: #065f46; text-transform: uppercase; }
    .net-words { font-size: 12px; color: #047857; font-style: italic; margin-top: 4px; }
    .net-amount { font-size: 24px; font-weight: 800; color: #065f46; }

    .footer {
      border-top: 1px solid #e2e8f0;
      padding-top: 16px;
      display: flex;
      justify-content: space-between;
      font-size: 11px;
      color: #64748b;
    }
    .stamp-box {
      border: 1px dashed #94a3b8;
      border-radius: 4px;
      padding: 8px 16px;
      text-align: center;
      color: #334155;
      font-weight: 600;
    }
    
    @media print {
      body { background: white; padding: 0; }
      .payslip-container { border: none; box-shadow: none; padding: 0; width: 100%; max-width: 100%; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <div class="no-print" style="max-width: 800px; margin: 0 auto 16px auto; text-align: right;">
    <button onclick="window.print()" style="background: #2563eb; color: white; border: none; padding: 10px 20px; border-radius: 6px; font-weight: bold; cursor: pointer;">
      🖨️ Print or Save as PDF
    </button>
  </div>

  <div class="payslip-container">
    <table class="header-table">
      <tr>
        <td>
          <div class="company-name">LOGILEAD TECHNOLOGIES PVT. LTD.</div>
          <div class="company-sub">Express Cargo & Logistics Park, Andheri East, Mumbai 400069 • www.logilead.com</div>
        </td>
        <td style="text-align: right;">
          <span class="badge">OFFICIAL SALARY VOUCHER</span>
          <div style="font-weight: 700; margin-top: 8px; font-size: 14px; color: #0f172a;">PAYSLIP: ${monthYear.toUpperCase()}</div>
          <div style="font-size: 11px; color: #16a34a; font-weight: 600;">Status: Paid Online</div>
        </td>
      </tr>
    </table>

    <div class="info-grid">
      <div class="info-item">
        <span class="info-label">Employee Name</span>
        <span class="info-val">$employeeName</span>
      </div>
      <div class="info-item">
        <span class="info-label">Employee Code</span>
        <span class="info-val">$employeeCode</span>
      </div>
      <div class="info-item">
        <span class="info-label">Department</span>
        <span class="info-val">$department</span>
      </div>
      <div class="info-item">
        <span class="info-label">Designation</span>
        <span class="info-val">$designation</span>
      </div>
      <div class="info-item">
        <span class="info-label">Date of Joining</span>
        <span class="info-val">$joinedOn</span>
      </div>
      <div class="info-item">
        <span class="info-label">Work Location</span>
        <span class="info-val">$location</span>
      </div>
      <div class="info-item">
        <span class="info-label">Bank Name</span>
        <span class="info-val">$bankName</span>
      </div>
      <div class="info-item">
        <span class="info-label">Bank Account No.</span>
        <span class="info-val">$accountNumber</span>
      </div>
      <div class="info-item">
        <span class="info-label">PAN Number</span>
        <span class="info-val">$panNumber</span>
      </div>
    </div>

    <table class="breakdown-table">
      <thead>
        <tr>
          <th>EARNINGS</th>
          <th class="text-right">AMOUNT (₹)</th>
          <th>DEDUCTIONS</th>
          <th class="text-right">AMOUNT (₹)</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Basic Salary (50%)</td>
          <td class="text-right">₹ ${salary.basic.toStringAsFixed(2)}</td>
          <td>Provident Fund (PF)</td>
          <td class="text-right">₹ ${salary.pf.toStringAsFixed(2)}</td>
        </tr>
        <tr>
          <td>House Rent Allowance (HRA 25%)</td>
          <td class="text-right">₹ ${salary.hra.toStringAsFixed(2)}</td>
          <td>Professional Tax (PT)</td>
          <td class="text-right">₹ ${salary.pt.toStringAsFixed(2)}</td>
        </tr>
        <tr>
          <td>Special Allowance (25%)</td>
          <td class="text-right">₹ ${salary.special.toStringAsFixed(2)}</td>
          <td>Income Tax (TDS)</td>
          <td class="text-right">₹ ${salary.tds.toStringAsFixed(2)}</td>
        </tr>
        <tr>
          <td>Transport / Other Allowances</td>
          <td class="text-right">₹ 0.00</td>
          <td>Loss of Pay (LOP)</td>
          <td class="text-right">₹ 0.00</td>
        </tr>
        <tr class="bg-subtotal">
          <td class="font-bold">Gross Earnings</td>
          <td class="text-right font-bold">₹ ${salary.gross.toStringAsFixed(2)}</td>
          <td class="font-bold">Total Deductions</td>
          <td class="text-right font-bold">₹ ${salary.deductions.toStringAsFixed(2)}</td>
        </tr>
      </tbody>
    </table>

    <div class="net-banner">
      <div>
        <div class="net-title">Net Take-Home Pay</div>
        <div class="net-words">In Words: ${salary.inWords}</div>
      </div>
      <div class="net-amount">₹ ${salary.netPay.toStringAsFixed(2)}</div>
    </div>

    <div class="footer">
      <div>
        <div>Generated electronically via LogiLead Corporate HRMS Portal.</div>
        <div>This is a computer-generated voucher and does not require a physical signature.</div>
      </div>
      <div class="stamp-box">
        ✓ Authorized Payroll Disbursed<br>
        <span style="font-size: 10px; color: #64748b;">LogiLead Finance Dept</span>
      </div>
    </div>
  </div>

  <script>
    // Automatically trigger print dialog when opened
    window.onload = function() {
      setTimeout(function() {
        window.print();
      }, 500);
    };
  </script>
</body>
</html>
''';
  }
}
