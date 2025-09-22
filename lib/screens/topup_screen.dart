import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/strings.dart';
import '../models/account.dart';
import '../models/transaction.dart';
import '../services/account_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({Key? key}) : super(key: key);

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneNumberController = TextEditingController();
  final _amountController = TextEditingController();
  final AccountService _accountService = AccountService();
  
  List<Account> _accounts = [];
  Account? _selectedAccount;
  String? _selectedProvider;
  bool _isLoading = false;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _providers = [
    {
      'name': 'GoPay',
      'icon': Icons.account_balance_wallet,
      'color': Colors.green,
      'type': 'ewallet'
    },
    {
      'name': 'OVO',
      'icon': Icons.account_balance_wallet,
      'color': Colors.purple,
      'type': 'ewallet'
    },
    {
      'name': 'DANA',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
      'type': 'ewallet'
    },
    {
      'name': 'Telkomsel',
      'icon': Icons.phone_android,
      'color': Colors.red,
      'type': 'mobile'
    },
    {
      'name': 'Indosat',
      'icon': Icons.phone_android,
      'color': Colors.yellow[700]!,
      'type': 'mobile'
    },
    {
      'name': 'XL Axiata',
      'icon': Icons.phone_android,
      'color': Colors.blue[800]!,
      'type': 'mobile'
    },
  ];

  final List<double> _quickAmounts = [10000, 25000, 50000, 100000, 200000, 500000];

  @override
  void initState() {
    super.initState();
    print('DEBUG: TopUpScreen initState called');
    _loadAccounts();
  }

  @override
  void dispose() {
    _phoneNumberController.dispose();
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
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter phone number';
    }
    if (value.length < 10 || value.length > 13) {
      return 'Phone number must be 10-13 digits';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return 'Phone number must contain only digits';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter amount';
    }
    final amount = double.tryParse(value.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return 'Please enter a valid amount';
    }
    if (amount < 10000) {
      return 'Minimum top-up amount is Rp 10,000';
    }
    if (amount > 5000000) {
      return 'Maximum top-up amount is Rp 5,000,000';
    }
    if (_selectedAccount != null && amount > _selectedAccount!.availableBalance) {
      return 'Insufficient balance';
    }
    return null;
  }

  Future<void> _processTopUp() async {
    print('DEBUG: _processTopUp called');
    print('DEBUG: Form valid: ${_formKey.currentState?.validate()}');
    print('DEBUG: Selected provider: $_selectedProvider');
    print('DEBUG: Selected account: ${_selectedAccount?.name}');
    print('DEBUG: Phone number: ${_phoneNumberController.text}');
    print('DEBUG: Amount: ${_amountController.text}');
    
    if (!_formKey.currentState!.validate()) {
      print('DEBUG: Form validation failed');
      return;
    }

    if (_selectedProvider == null) {
      print('DEBUG: No provider selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a provider'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    if (_selectedAccount == null) {
      print('DEBUG: No account selected');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an account'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      final phoneNumber = _phoneNumberController.text;
      
      final transaction = await _accountService.topUp(
        accountId: _selectedAccount!.id,
        provider: _selectedProvider!,
        number: phoneNumber,
        amount: amount,
        description: '$_selectedProvider Top Up - $phoneNumber',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up successful! Transaction ID: ${transaction.reference}'),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Top-up failed: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _setQuickAmount(double amount) {
    _amountController.text = amount.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.topUp),
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
                    // Account Selection
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
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: _accounts.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No accounts available'),
                            )
                          : DropdownButtonHideUnderline(
                              child: DropdownButton<Account>(
                                value: _selectedAccount,
                                isExpanded: true,
                                items: _accounts.map((Account account) {
                                  return DropdownMenuItem<Account>(
                                    value: account,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          account.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        Text(
                                          '${account.maskedAccountNumber} • ${account.formattedAvailableBalance}',
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

                    // Provider Selection
                    Text(
                      'Select Provider',
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
                        crossAxisCount: 3,
                        childAspectRatio: 1.2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                      ),
                      itemCount: _providers.length,
                      itemBuilder: (context, index) {
                        final provider = _providers[index];
                        final isSelected = _selectedProvider == provider['name'];
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedProvider = provider['name'];
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  provider['icon'],
                                  size: 32,
                                  color: isSelected ? AppColors.primary : provider['color'],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  provider['name'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),

                    // Phone Number Input
                    CustomTextField(
                      controller: _phoneNumberController,
                      label: 'Phone Number',
                      hint: 'Enter phone number',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: _validatePhoneNumber,
                    ),
                    const SizedBox(height: 24),

                    // Amount Input
                    CustomTextField(
                      controller: _amountController,
                      label: 'Amount (IDR)',
                      hint: 'Enter amount',
                      prefixIcon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      validator: _validateAmount,
                    ),
                    const SizedBox(height: 16),

                    // Quick Amount Selection
                    Text(
                      'Quick Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickAmounts.map((amount) {
                        return GestureDetector(
                          onTap: () => _setQuickAmount(amount),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.divider),
                            ),
                            child: Text(
                              'Rp ${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 32),

                    // Top Up Button
                    SizedBox(
                      width: double.infinity,
                      child: Builder(
                        builder: (context) {
                          print('DEBUG: Building TopUp button - _isProcessing: $_isProcessing');
                          return CustomButton(
                            text: _isProcessing ? 'Processing...' : 'Top Up Now',
                            onPressed: _isProcessing ? null : _processTopUp,
                            isLoading: _isProcessing,
                            backgroundColor: AppColors.primary,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}