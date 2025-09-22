import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../services/qr_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class TransferScreen extends StatefulWidget {
  final PaymentQRData? qrData;

  const TransferScreen({Key? key, this.qrData}) : super(key: key);

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountNumberController = TextEditingController();
  final _accountNameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final AccountService _accountService = AccountService();

  List<Account> _accounts = [];
  Account? _selectedAccount;
  bool _isLoading = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
    _prefillFromQR();
  }

  void _prefillFromQR() {
    if (widget.qrData != null) {
      _accountNumberController.text = widget.qrData!.accountNumber;
      _accountNameController.text = widget.qrData!.accountName ?? '';
      if (widget.qrData!.amount != null) {
        _amountController.text = widget.qrData!.amount!.toStringAsFixed(0);
      }
      if (widget.qrData!.description != null) {
        _descriptionController.text = widget.qrData!.description!;
      }
    }
  }

  Future<void> _loadAccounts() async {
    setState(() => _isLoading = true);
    try {
      final accounts = await _accountService.getAccounts();
      setState(() {
        _accounts = accounts;
        _selectedAccount = accounts.isNotEmpty ? accounts.first : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load accounts: $e');
    }
  }

  Future<void> _processTransfer() async {
    if (!_formKey.currentState!.validate() || _selectedAccount == null) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));

      // Check if sufficient balance
      if (_selectedAccount!.availableBalance < amount) {
        _showErrorSnackBar('Insufficient balance');
        setState(() => _isProcessing = false);
        return;
      }

      final transaction = await _accountService.transferMoney(
        fromAccountId: _selectedAccount!.id,
        toAccountNumber: _accountNumberController.text,
        amount: amount,
        description: _descriptionController.text.isEmpty
            ? 'Transfer to ${_accountNameController.text}'
            : _descriptionController.text,
        recipientName: _accountNameController.text.isEmpty
            ? null
            : _accountNameController.text,
      );

      setState(() => _isProcessing = false);

      // Show success dialog
      _showSuccessDialog(transaction);
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Transfer failed: $e');
    }
  }

  void _showSuccessDialog(Transaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: Icon(
          Icons.check_circle,
          color: AppColors.success,
          size: 64,
        ),
        title: const Text('Transfer Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your transfer of ${transaction.formattedAmountWithoutSign} has been processed successfully.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.grey100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildInfoRow('Reference', transaction.reference ?? 'N/A'),
                  _buildInfoRow('To', transaction.recipientName ?? 'N/A'),
                  _buildInfoRow(
                      'Account', transaction.recipientAccount ?? 'N/A'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  String? _validateAccountNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Account number is required';
    }
    if (value.length < 10) {
      return 'Account number must be at least 10 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Account number must contain only digits';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    if (amount < 10000) {
      return 'Minimum transfer amount is Rp 10,000';
    }
    if (_selectedAccount != null &&
        amount > _selectedAccount!.availableBalance) {
      return 'Amount exceeds available balance';
    }
    return null;
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _accountNameController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Transfer Money'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // From Account Selection
                    Text(
                      'From Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.grey300),
                      ),
                      child: _accounts.isEmpty
                          ? const Text('No accounts available')
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<Account>(
                                value: _selectedAccount,
                                isExpanded: true,
                                items: _accounts.map((account) {
                                  return DropdownMenuItem<Account>(
                                    value: account,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          account.accountNumber,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          'Available: ${account.formattedAvailableBalance}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (Account? account) {
                                  setState(() {
                                    _selectedAccount = account;
                                  });
                                },
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // To Account Details
                    Text(
                      'To Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _accountNumberController,
                      label: 'Account Number',
                      keyboardType: TextInputType.number,
                      validator: _validateAccountNumber,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _accountNameController,
                      label: 'Account Name (Optional)',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 24),

                    // Transfer Details
                    Text(
                      'Transfer Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _amountController,
                      label: 'Amount (IDR)',
                      keyboardType: TextInputType.number,
                      validator: _validateAmount,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _descriptionController,
                      label: 'Description (Optional)',
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 32),

                    // Transfer Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text:
                            _isProcessing ? 'Processing...' : 'Transfer Money',
                        onPressed: _isProcessing ? null : _processTransfer,
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
