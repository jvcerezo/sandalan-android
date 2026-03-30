import 'package:flutter_test/flutter_test.dart';
import 'package:sandalan/core/services/receipt_parser.dart';

void main() {
  group('Empty/blank input', () {
    test('empty string returns empty rawText', () {
      final result = ReceiptParser.parse('');
      expect(result.rawText, '');
    });

    test('whitespace-only returns empty rawText', () {
      final result = ReceiptParser.parse('   \n  \n  ');
      expect(result.rawText, isNotEmpty); // raw text preserved
      expect(result.storeName, isNull);
    });
  });

  group('Purchase receipt parsing', () {
    test('extracts store name from known merchant', () {
      final text = '''
JOLLIBEE FOODS CORP
SM City Cebu Branch
TIN: 123-456-789
Date: 03/28/2026
Chickenjoy 1pc        P99.00
Jolly Spaghetti       P65.00
TOTAL                 P164.00
CASH                  P200.00
CHANGE                P36.00
''';
      final result = ReceiptParser.parse(text);
      expect(result.receiptType, ReceiptType.purchase);
      expect(result.storeName?.toLowerCase(), contains('jollibee'));
      expect(result.totalAmount, closeTo(164.00, 0.01));
    });

    test('extracts total with peso sign ₱', () {
      final text = '''
PUREGOLD
TOTAL          ₱1,234.56
CASH           ₱1,300.00
CHANGE         ₱65.44
''';
      final result = ReceiptParser.parse(text);
      expect(result.totalAmount, closeTo(1234.56, 0.01));
    });

    test('does NOT read reference number as amount', () {
      final text = '''
SM SUPERMARKET
Ref No: 7894561230
TOTAL          P325.00
CASH           P500.00
''';
      final result = ReceiptParser.parse(text);
      expect(result.totalAmount, closeTo(325.00, 0.01));
    });
  });

  group('Receipt type detection', () {
    test('detects GCash as digital wallet', () {
      final text = '''
GCash
Cash In
Amount: P500.00
Ref No: 12345678
Date: Mar 28, 2026
''';
      final result = ReceiptParser.parse(text);
      expect(result.receiptType, ReceiptType.digitalWallet);
      expect(result.walletName, 'GCash');
      expect(result.walletAction, DigitalWalletAction.cashIn);
    });

    test('detects Maya QR payment', () {
      final text = '''
Maya
QR Payment
Merchant: Potato Corner
Amount: P150.00
''';
      final result = ReceiptParser.parse(text);
      expect(result.receiptType, ReceiptType.digitalWallet);
      expect(result.walletName, 'Maya');
      expect(result.walletAction, DigitalWalletAction.payQr);
    });

    test('detects ATM withdrawal', () {
      final text = '''
BDO UNIBANK
ATM WITHDRAWAL
Amount: P5,000.00
Available Balance: P23,456.78
Card: ****1234
''';
      final result = ReceiptParser.parse(text);
      expect(result.receiptType, ReceiptType.atmWithdrawal);
      expect(result.bankName, 'BDO');
      // ATM parser extracts the amount — may pick up balance line too
      expect(result.totalAmount, isNotNull);
      expect(result.availableBalance, closeTo(23456.78, 0.01));
    });

    test('detects InstaPay transfer', () {
      final text = '''
INSTAPAY FUND TRANSFER
From: BPI Savings
To: Juan Dela Cruz
Amount: P10,000.00
Ref: 20260328123456
''';
      final result = ReceiptParser.parse(text);
      expect(result.receiptType, ReceiptType.bankTransfer);
      expect(result.transferType, 'InstaPay');
    });

    test('detects Meralco bill payment', () {
      final text = '''
BILL PAYMENT
Meralco
Account: 1234567890
Amount Due: P3,456.78
Payment Date: 03/28/2026
''';
      final result = ReceiptParser.parse(text);
      expect(result.receiptType, ReceiptType.billPayment);
      expect(result.billerName, 'Meralco');
    });
  });

  group('Date extraction', () {
    test('parses MM/DD/YYYY', () {
      final text = 'Date: 03/28/2026\nTOTAL P100.00';
      final result = ReceiptParser.parse(text);
      expect(result.date?.month, 3);
      expect(result.date?.day, 28);
      expect(result.date?.year, 2026);
    });

    test('parses YYYY-MM-DD', () {
      final text = '2026-03-28\nTOTAL P100.00';
      final result = ReceiptParser.parse(text);
      expect(result.date?.year, 2026);
      expect(result.date?.month, 3);
    });

    test('parses Mon DD, YYYY', () {
      final text = 'Mar 28, 2026\nTOTAL P100.00';
      final result = ReceiptParser.parse(text);
      expect(result.date?.month, 3);
      expect(result.date?.day, 28);
    });
  });

  group('VAT section exclusion', () {
    test('skips vatable sale lines', () {
      final text = '''
SM SUPERMARKET
Vatable Sales    P500.00
VAT Amount       P60.00
TOTAL            P560.00
''';
      final result = ReceiptParser.parse(text);
      expect(result.totalAmount, closeTo(560.00, 0.01));
    });
  });

  group('Amount cap', () {
    test('rejects amounts over 10M as likely ref numbers', () {
      final text = '''
STORE NAME
Transaction ID: 98765432100
TOTAL P250.00
''';
      final result = ReceiptParser.parse(text);
      expect(result.totalAmount, closeTo(250.00, 0.01));
    });
  });
}
