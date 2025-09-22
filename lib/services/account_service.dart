import '../models/account.dart';
import '../models/transaction.dart';

class AccountService {
  // Mock accounts data
  final List<Account> _mockAccounts = [
    Account(
      id: '1',
      name: 'BCA Savings Account',
      accountNumber: '1234567890',
      accountName: 'Primary Savings',
      type: AccountType.savings,
      balance: 15000000.00,
      availableBalance: 15000000.00,
      currency: 'IDR',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 365)),
      updatedAt: DateTime.now(),
    ),
    Account(
      id: '2',
      name: 'BCA Checking Account',
      accountNumber: '0987654321',
      accountName: 'Current Account',
      type: AccountType.current,
      balance: 5000000.00,
      availableBalance: 5000000.00,
      currency: 'IDR',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now(),
    ),
    Account(
      id: '3',
      name: 'BCA Credit Card',
      accountNumber: '1122334455',
      accountName: 'BCA Credit Card',
      type: AccountType.creditCard,
      balance: -2500000.00, // Negative balance for credit card
      availableBalance: 7500000.00, // Available credit limit
      currency: 'IDR',
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 90)),
      updatedAt: DateTime.now(),
    ),
  ];

  // Mock transactions data
  final List<Transaction> _mockTransactions = [
    Transaction(
      id: 'txn_001',
      accountId: '1',
      type: TransactionType.transfer,
      status: TransactionStatus.completed,
      amount: 500000.00,
      description: 'Transfer to John Doe',
      recipientName: 'John Doe',
      recipientAccount: '1111222233334444',
      reference: 'TRF001',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      completedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Transaction(
      id: 'txn_002',
      accountId: '1',
      type: TransactionType.payment,
      status: TransactionStatus.completed,
      amount: 150000.00,
      description: 'PLN Electricity Bill',
      reference: 'BILL002',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      completedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Transaction(
      id: 'txn_003',
      accountId: '1',
      type: TransactionType.topup,
      status: TransactionStatus.completed,
      amount: 100000.00,
      description: 'GoPay Top Up',
      reference: 'TOP003',
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      completedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Transaction(
      id: 'txn_004',
      accountId: '1',
      type: TransactionType.deposit,
      status: TransactionStatus.completed,
      amount: 2000000.00,
      description: 'Salary Deposit',
      reference: 'SAL004',
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      completedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    Transaction(
      id: 'txn_005',
      accountId: '2',
      type: TransactionType.transfer,
      status: TransactionStatus.completed,
      amount: 750000.00,
      description: 'Transfer to Jane Smith',
      recipientName: 'Jane Smith',
      recipientAccount: '9999888877776666',
      reference: 'TRF005',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      completedAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    Transaction(
      id: 'txn_006',
      accountId: '3',
      type: TransactionType.payment,
      status: TransactionStatus.completed,
      amount: 300000.00,
      description: 'Online Shopping',
      reference: 'SHOP006',
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      completedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Transaction(
      id: 'txn_007',
      accountId: '1',
      type: TransactionType.withdrawal,
      status: TransactionStatus.completed,
      amount: 200000.00,
      description: 'ATM Withdrawal',
      reference: 'ATM007',
      createdAt: DateTime.now().subtract(const Duration(days: 6)),
      completedAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    Transaction(
      id: 'txn_008',
      accountId: '1',
      type: TransactionType.transfer,
      status: TransactionStatus.pending,
      amount: 1000000.00,
      description: 'Transfer to Business Account',
      recipientName: 'ABC Company',
      recipientAccount: '1122334455667788',
      reference: 'TRF008',
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  // Get all accounts for current user
  Future<List<Account>> getAccounts() async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 500));
    return List.from(_mockAccounts);
  }

  // Get account by ID
  Future<Account?> getAccountById(String accountId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockAccounts.firstWhere((account) => account.id == accountId);
    } catch (e) {
      return null;
    }
  }

  // Get primary account (first savings account)
  Future<Account?> getPrimaryAccount() async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockAccounts.firstWhere(
        (account) => account.type == AccountType.savings && account.isActive,
      );
    } catch (e) {
      return null;
    }
  }

  // Get total balance across all accounts
  Future<double> getTotalBalance() async {
    final accounts = await getAccounts();
    return accounts
        .where((account) => account.type != AccountType.creditCard)
        .fold<double>(0.0, (sum, account) => sum + account.balance);
  }

  // Get transactions for an account
  Future<List<Transaction>> getTransactions({
    String? accountId,
    int limit = 50,
    int offset = 0,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    var transactions = List<Transaction>.from(_mockTransactions);
    
    if (accountId != null) {
      transactions = transactions
          .where((transaction) => transaction.accountId == accountId)
          .toList();
    }
    
    // Sort by date (newest first)
    transactions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    
    // Apply pagination
    final startIndex = offset;
    final endIndex = (offset + limit).clamp(0, transactions.length);
    
    if (startIndex >= transactions.length) {
      return [];
    }
    
    return transactions.sublist(startIndex, endIndex);
  }

  // Get recent transactions (last 5)
  Future<List<Transaction>> getRecentTransactions({String? accountId}) async {
    return getTransactions(accountId: accountId, limit: 5);
  }

  // Get transaction by ID
  Future<Transaction?> getTransactionById(String transactionId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _mockTransactions.firstWhere(
        (transaction) => transaction.id == transactionId,
      );
    } catch (e) {
      return null;
    }
  }

  // Transfer money between accounts
  Future<Transaction> transferMoney({
    required String fromAccountId,
    required String toAccountNumber,
    required double amount,
    required String description,
    String? recipientName,
  }) async {
    // Simulate API call delay
    await Future.delayed(const Duration(seconds: 2));
    
    // Create new transaction
    final transaction = Transaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      accountId: fromAccountId,
      type: TransactionType.transfer,
      status: TransactionStatus.completed,
      amount: amount,
      description: description,
      recipientName: recipientName,
      recipientAccount: toAccountNumber,
      reference: 'TRF${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
    );
    
    // Add to mock transactions
    _mockTransactions.insert(0, transaction);
    
    // Update account balance
    final accountIndex = _mockAccounts.indexWhere((a) => a.id == fromAccountId);
    if (accountIndex != -1) {
      final account = _mockAccounts[accountIndex];
      _mockAccounts[accountIndex] = account.copyWith(
        balance: account.balance - amount,
        availableBalance: account.availableBalance - amount,
        updatedAt: DateTime.now(),
      );
    }
    
    return transaction;
  }

  // Pay bill
  Future<Transaction> payBill({
    required String accountId,
    required String billType,
    required String billNumber,
    required double amount,
    required String description,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final transaction = Transaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      accountId: accountId,
      type: TransactionType.payment,
      status: TransactionStatus.completed,
      amount: amount,
      description: description,
      reference: 'BILL${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      metadata: {
        'billType': billType,
        'billNumber': billNumber,
      },
    );
    
    _mockTransactions.insert(0, transaction);
    
    // Update account balance
    final accountIndex = _mockAccounts.indexWhere((a) => a.id == accountId);
    if (accountIndex != -1) {
      final account = _mockAccounts[accountIndex];
      _mockAccounts[accountIndex] = account.copyWith(
        balance: account.balance - amount,
        availableBalance: account.availableBalance - amount,
        updatedAt: DateTime.now(),
      );
    }
    
    return transaction;
  }

  // Top up e-wallet or mobile credit
  Future<Transaction> topUp({
    required String accountId,
    required String provider,
    required String number,
    required double amount,
    required String description,
  }) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final transaction = Transaction(
      id: 'txn_${DateTime.now().millisecondsSinceEpoch}',
      accountId: accountId,
      type: TransactionType.topup,
      status: TransactionStatus.completed,
      amount: amount,
      description: description,
      reference: 'TOP${DateTime.now().millisecondsSinceEpoch}',
      createdAt: DateTime.now(),
      completedAt: DateTime.now(),
      metadata: {
        'provider': provider,
        'number': number,
      },
    );
    
    _mockTransactions.insert(0, transaction);
    
    // Update account balance
    final accountIndex = _mockAccounts.indexWhere((a) => a.id == accountId);
    if (accountIndex != -1) {
      final account = _mockAccounts[accountIndex];
      _mockAccounts[accountIndex] = account.copyWith(
        balance: account.balance - amount,
        availableBalance: account.availableBalance - amount,
        updatedAt: DateTime.now(),
      );
    }
    
    return transaction;
  }
}