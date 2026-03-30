import 'package:flutter_test/flutter_test.dart';
import 'package:sandalan/core/math/ph_math.dart';
import 'package:sandalan/core/constants/ph_rates.dart';

void main() {
  group('SSS Contributions', () {
    test('below minimum salary returns minMsc=4000', () {
      final result = calculateSSS(3000);
      expect(result.msc, 4000);
    });

    test('at maximum salary returns maxMsc=30000', () {
      final result = calculateSSS(30000);
      expect(result.msc, 30000);
    });

    test('mid-range salary 15000 returns correct split', () {
      final result = calculateSSS(15000);
      expect(result.msc, 15000);
      expect(result.employee, closeTo(15000 * 0.045, 0.01));
      expect(result.employer, closeTo(15000 * 0.095, 0.01));
    });

    test('self-employed pays total rate, employer=0', () {
      final result = calculateSSS(20000, employmentType: EmploymentType.selfEmployed);
      expect(result.employer, 0);
      expect(result.employee, closeTo(20000 * 0.14, 0.01));
    });

    test('OFW pays total rate, EC=0', () {
      final result = calculateSSS(20000, employmentType: EmploymentType.ofw);
      expect(result.ec, 0);
      expect(result.employer, 0);
    });

    test('EC is 10 when MSC<=14500', () {
      final result = calculateSSS(14000);
      expect(result.ec, 10);
    });

    test('EC is 30 when MSC>14500', () {
      final result = calculateSSS(15000);
      expect(result.ec, 30);
    });
  });

  group('PhilHealth Contributions', () {
    test('below minimum salary clamps to 10000', () {
      final result = calculatePhilHealth(5000);
      expect(result.monthlySalary, 10000);
      expect(result.total, closeTo(10000 * 0.05, 0.01));
    });

    test('above maximum salary clamps to 100000', () {
      final result = calculatePhilHealth(150000);
      expect(result.monthlySalary, 100000);
    });

    test('50000 salary returns 1250 employee, 1250 employer', () {
      final result = calculatePhilHealth(50000);
      expect(result.employee, 1250);
      expect(result.employer, 1250);
    });

    test('self-employed pays full premium, employer=0', () {
      final result = calculatePhilHealth(30000, employmentType: EmploymentType.selfEmployed);
      expect(result.employer, 0);
      expect(result.employee, closeTo(30000 * 0.05, 0.01));
    });
  });

  group('Pag-IBIG Contributions', () {
    test('salary <= 1500 uses low employee rate (1%)', () {
      final result = calculatePagIbig(1500);
      expect(result.employee, closeTo(1500 * 0.01, 0.01));
    });

    test('salary > 1500 uses high employee rate (2%)', () {
      final result = calculatePagIbig(5000);
      expect(result.employee, closeTo(5000 * 0.02, 0.01));
    });

    test('caps base at maxCompensation 10000', () {
      final result = calculatePagIbig(50000);
      expect(result.employee, closeTo(10000 * 0.02, 0.01));
    });
  });

  group('Combined Government Deductions', () {
    test('netTakeHome = salary - total employee deductions', () {
      final result = calculateGovernmentDeductions(25000);
      final expectedEmployee = result.sss.employee + result.philhealth.employee + result.pagibig.employee;
      expect(result.totalEmployee, closeTo(expectedEmployee, 0.01));
      expect(result.netTakeHome, closeTo(25000 - expectedEmployee, 0.01));
    });
  });

  group('TRAIN Law Income Tax', () {
    test('250000 annual returns 0 tax (exempt bracket)', () {
      final result = computeIncomeTax(250000);
      expect(result.taxDue, 0);
    });

    test('400000 annual returns 22500 tax', () {
      final result = computeIncomeTax(400000);
      expect(result.taxDue, closeTo(22500, 0.01));
    });

    test('500000 annual = 22500 + 20% of 100k = 42500', () {
      final result = computeIncomeTax(500000);
      expect(result.taxDue, closeTo(42500, 0.01));
    });

    test('2000000 annual = 402500', () {
      final result = computeIncomeTax(2000000);
      expect(result.taxDue, closeTo(402500, 0.01));
    });

    test('quarterly estimate is taxDue / 4', () {
      final result = computeIncomeTax(500000);
      expect(result.quarterlyEstimate, closeTo(result.taxDue / 4, 0.01));
    });
  });

  group('Flat Tax (8%)', () {
    test('500000 gross = 8% of (500k - 250k) = 20000', () {
      final result = computeFlatTax(500000);
      expect(result.taxDue, closeTo(20000, 0.01));
    });

    test('income below 250k = 0 tax', () {
      final result = computeFlatTax(200000);
      expect(result.taxDue, 0);
    });
  });

  group('13th Month Pay', () {
    test('12 months at 30000 = gross 30000, all tax-exempt', () {
      final result = calculate13thMonth(30000, monthsWorked: 12);
      expect(result.gross, closeTo(30000, 0.01));
      expect(result.taxable, 0);
    });

    test('12 months at 120000 = gross 120000, taxable 30000', () {
      final result = calculate13thMonth(120000, monthsWorked: 12);
      expect(result.gross, closeTo(120000, 0.01));
      expect(result.taxExemptPortion, closeTo(90000, 0.01));
      expect(result.taxable, closeTo(30000, 0.01));
    });

    test('6 months at 60000 = gross 30000', () {
      final result = calculate13thMonth(60000, monthsWorked: 6);
      expect(result.gross, closeTo(30000, 0.01));
    });
  });
}
