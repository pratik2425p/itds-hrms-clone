class SalaryBreakdown {
  final double gross;
  final double basic;
  final double hra;
  final double special;
  final double pf;
  final double pt;
  final double tds;
  final double deductions;
  final double netPay;

  SalaryBreakdown({
    required this.gross,
    required this.basic,
    required this.hra,
    required this.special,
    required this.pf,
    required this.pt,
    required this.tds,
    required this.deductions,
    required this.netPay,
  });

  factory SalaryBreakdown.fromGross(double grossAmount) {
    final double gross = grossAmount > 0 ? grossAmount : 50000.0;
    
    // Indian standard compensation breakdown:
    // Basic: 50% of Gross
    final double basic = (gross * 0.50).roundToDouble();
    
    // HRA: 25% of Gross
    final double hra = (gross * 0.25).roundToDouble();
    
    // Special Allowance: Remaining balance (25% of Gross)
    final double special = (gross - basic - hra).roundToDouble();

    // Statutory deductions:
    // PF: 12% of Basic, standard statutory cap of Rs 1,800/month
    final double rawPf = basic * 0.12;
    final double pf = (rawPf > 1800.0 ? 1800.0 : rawPf).roundToDouble();
    
    // Professional Tax (PT): Rs 200/month
    const double pt = 200.0;

    // TDS (Tax Deducted at Source estimate)
    double tds = 0.0;
    if (gross >= 100000) {
      tds = (gross * 0.10).roundToDouble();
    } else if (gross >= 75000) {
      tds = (gross * 0.05).roundToDouble();
    } else if (gross >= 50000) {
      tds = 1500.0;
    } else {
      tds = 0.0;
    }

    final double deductions = (pf + pt + tds).roundToDouble();
    final double netPay = (gross - deductions).roundToDouble();

    return SalaryBreakdown(
      gross: gross,
      basic: basic,
      hra: hra,
      special: special,
      pf: pf,
      pt: pt,
      tds: tds,
      deductions: deductions,
      netPay: netPay,
    );
  }

  String get inWords {
    final int amount = netPay.round();
    return 'Rupees ${numberToWords(amount)} Only';
  }

  static String numberToWords(int number) {
    if (number == 0) return 'Zero';

    final units = [
      '', 'One', 'Two', 'Three', 'Four', 'Five', 'Six', 'Seven', 'Eight', 'Nine',
      'Ten', 'Eleven', 'Twelve', 'Thirteen', 'Fourteen', 'Fifteen', 'Sixteen',
      'Seventeen', 'Eighteen', 'Nineteen'
    ];

    final tens = [
      '', '', 'Twenty', 'Thirty', 'Forty', 'Fifty', 'Sixty', 'Seventy', 'Eighty', 'Ninety'
    ];

    String convertLessThanOneThousand(int n) {
      if (n == 0) return '';
      if (n < 20) return units[n];
      if (n < 100) {
        return tens[n ~/ 10] + (n % 10 != 0 ? ' ${units[n % 10]}' : '');
      }
      return '${units[n ~/ 100]} Hundred${n % 100 != 0 ? ' and ${convertLessThanOneThousand(n % 100)}' : ''}';
    }

    String result = '';
    int num = number;

    if (num >= 10000000) {
      result += '${convertLessThanOneThousand(num ~/ 10000000)} Crore ';
      num %= 10000000;
    }
    if (num >= 100000) {
      result += '${convertLessThanOneThousand(num ~/ 100000)} Lakh ';
      num %= 100000;
    }
    if (num >= 1000) {
      result += '${convertLessThanOneThousand(num ~/ 1000)} Thousand ';
      num %= 1000;
    }
    if (num > 0) {
      result += convertLessThanOneThousand(num);
    }

    return result.trim();
  }
}
