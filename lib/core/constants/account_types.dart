/// Account type definitions.

class AccountType {
  final String value;
  final String label;
  const AccountType({required this.value, required this.label});
}

const List<AccountType> kAccountTypes = [
  AccountType(value: 'cash', label: 'Cash'),
  AccountType(value: 'bank', label: 'Bank Account'),
  AccountType(value: 'e-wallet', label: 'E-Wallet'),
  AccountType(value: 'credit-card', label: 'Credit Card'),
];

class CommonAccount {
  final String name;
  final String type;
  const CommonAccount({required this.name, required this.type});
}

const List<CommonAccount> kCommonAccounts = [
  CommonAccount(name: 'Cash', type: 'cash'),
  CommonAccount(name: 'GCash', type: 'e-wallet'),
  CommonAccount(name: 'Maya', type: 'e-wallet'),
];
