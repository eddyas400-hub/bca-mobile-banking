import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class BillPaymentScreen extends StatefulWidget {
  const BillPaymentScreen({Key? key}) : super(key: key);

  @override
  State<BillPaymentScreen> createState() => _BillPaymentScreenState();
}

class _BillPaymentScreenState extends State<BillPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _billNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final AccountService _accountService = AccountService();
  
  List<Account> _accounts = [];
  Account? _selectedAccount;
  String? _selectedBillType;
  bool _isLoading = false;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _billTypes = [
    {
      'name': 'PLN (Electricity)',
      'icon': Icons.flash_on,
      'color': Colors.yellow[700]!,
      'type': 'electricity',
      'description': 'Pay your electricity bill'
    },
    {
      'name': 'PDAM (Water)',
      'icon': Icons.water_drop,
      'color': Colors.blue,
      'type': 'water',
      'description': 'Pay your water bill'
    },
    {
      'name': 'Internet',
      'icon': Icons.wifi,
      'color': Colors.green,
      'type': 'internet',
      'description': 'Pay your internet bill'
    },
    {
      'name': 'Phone',
      'icon': Icons.phone,
      'color': Colors.orange,
      'type': 'phone',
      'description': 'Pay your phone bill'
    },
    {
      'name': 'Gas',
      'icon': Icons.local_gas_station,
      'color': Colors.red,
      'type': 'gas',
      'description': 'Pay your gas bill'
    },
    {
      'name': 'Insurance',
      'icon': Icons.security,
      'color': Colors.purple,
      'type': 'insurance',
      'description': 'Pay your insurance premium'
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  @override
  void dispose() {
    _billNumberController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadAccounts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final accounts = await _accountService.getAccounts();
      setState(() {
        _accounts = accounts;
        _selectedAccount = accounts.isNotEmpty ? accounts.first : null;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load accounts: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processBillPayment() async {
    if (!_formKey.currentState!.validate() || 
        _selectedAccount == null || 
        _selectedBillType == null) {
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

      final transaction = await _accountService.payBill(
        accountId: _selectedAccount!.id,
        billType: _selectedBillType!,
        billNumber: _billNumberController.text,
        amount: amount,
        description: 'Bill Payment - $_selectedBillType',
      );

      setState(() => _isProcessing = false);
      
      // Show success dialog
      _showSuccessDialog(transaction);
      
    } catch (e) {
      setState(() => _isProcessing = false);
      _showErrorSnackBar('Bill payment failed: $e');
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
        title: const Text('Payment Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Your bill payment of ${transaction.formattedAmountWithoutSign} has been processed successfully.',
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
                  _buildInfoRow('Bill Type', _selectedBillType ?? 'N/A'),
                  _buildInfoRow('Bill Number', _billNumberController.text),
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

  String? _validateBillNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Bill number is required';
    }
    if (value.length < 8) {
      return 'Bill number must be at least 8 characters';
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
    if (amount < 1000) {
      return 'Minimum payment amount is Rp 1,000';
    }
    if (_selectedAccount != null && amount > _selectedAccount!.availableBalance) {
      return 'Amount exceeds available balance';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pay Bills'),
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
                                      crossAxisAlignment: CrossAxisAlignment.start,
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

                    // Bill Type Selection
                    Text(
                      'Select Bill Type',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 2.5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _billTypes.length,
                      itemBuilder: (context, index) {
                        final billType = _billTypes[index];
                        final isSelected = _selectedBillType == billType['type'];
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedBillType = billType['type'];
                            });
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppColors.primary : AppColors.divider,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  Icon(
                                    billType['icon'],
                                    size: 24,
                                    color: isSelected ? AppColors.primary : billType['color'],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          billType['name'],
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                          ),
                                        ),
                                        Text(
                                          billType['description'],
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Bill Details
                    Text(
                      'Bill Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    CustomTextField(
                      controller: _billNumberController,
                      label: 'Bill Number / Customer ID',
                      keyboardType: TextInputType.text,
                      validator: _validateBillNumber,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _amountController,
                      label: 'Amount (IDR)',
                      keyboardType: TextInputType.number,
                      validator: _validateAmount,
                    ),
                    const SizedBox(height: 32),

                    // Pay Button
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: _isProcessing ? 'Processing...' : 'Pay Bill',
                        onPressed: _isProcessing ? null : _processBillPayment,
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