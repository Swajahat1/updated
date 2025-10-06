import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/theme/app_theme.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final String userId;

  const PaymentMethodsScreen({super.key, required this.userId});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  bool _isLoading = false;
  List<dynamic> _paymentHistory = [];
  List<dynamic> _paymentMethods = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPaymentHistory();
    _fetchPaymentMethods();
  }

  Future<void> _fetchPaymentHistory() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http:// 192.168.2.102:3000/api/payments/user/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _paymentHistory = data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Failed to load payment history';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchPaymentMethods() async {
    // Simulate payment methods - in real app, fetch from Stripe
    setState(() {
      _paymentMethods = [
        {
          'id': '1',
          'type': 'card',
          'last4': '4242',
          'brand': 'visa',
          'isDefault': true,
        },
        {
          'id': '2',
          'type': 'card',
          'last4': '5555',
          'brand': 'mastercard',
          'isDefault': false,
        },
      ];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingM),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.surfaceColor,
                        foregroundColor: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Text(
                      'Payment Methods',
                      style: AppTheme.headingLarge.copyWith(
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  children: [
                    // Payment Methods Section
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Saved Payment Methods',
                                  style: AppTheme.headingSmall.copyWith(
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: _addPaymentMethod,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add'),
                                ),
                              ],
                            ),
                          ),
                          ..._paymentMethods
                              .map((method) => _buildPaymentMethodTile(method))
                              .toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppTheme.spacingL),

                    // Payment History Section
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusL),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(AppTheme.spacingM),
                            child: Text(
                              'Payment History',
                              style: AppTheme.headingSmall.copyWith(
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          if (_isLoading)
                            const Padding(
                              padding: EdgeInsets.all(AppTheme.spacingL),
                              child: Center(child: CircularProgressIndicator()),
                            )
                          else if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              child: Center(
                                child: Text(
                                  _errorMessage!,
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.errorColor,
                                  ),
                                ),
                              ),
                            )
                          else if (_paymentHistory.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(AppTheme.spacingL),
                              child: Center(
                                child: Text(
                                  'No payment history found',
                                  style: AppTheme.bodyMedium.copyWith(
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            )
                          else
                            ..._paymentHistory
                                .map((payment) =>
                                    _buildPaymentHistoryTile(payment))
                                .toList(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile(Map<String, dynamic> method) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Icon(
          method['brand'] == 'visa' ? Icons.credit_card : Icons.payment,
          color: AppTheme.primaryColor,
        ),
      ),
      title: Text(
        '${method['brand'].toString().toUpperCase()} •••• ${method['last4']}',
        style: AppTheme.bodyLarge.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: method['isDefault']
          ? Text(
              'Default payment method',
              style: AppTheme.bodySmall.copyWith(
                color: AppTheme.primaryColor,
              ),
            )
          : null,
      trailing: PopupMenuButton(
        itemBuilder: (context) => [
          const PopupMenuItem(
            value: 'default',
            child: Text('Set as default'),
          ),
          const PopupMenuItem(
            value: 'delete',
            child: Text('Delete'),
          ),
        ],
        onSelected: (value) {
          if (value == 'default') {
            _setDefaultPaymentMethod(method['id']);
          } else if (value == 'delete') {
            _deletePaymentMethod(method['id']);
          }
        },
      ),
    );
  }

  Widget _buildPaymentHistoryTile(Map<String, dynamic> payment) {
    final amount = payment['amount']?.toString() ?? '0';
    final status = payment['status'] ?? 'Unknown';
    final date = payment['createdAt'] ?? payment['paymentDate'] ?? 'Unknown';

    Color statusColor;
    switch (status.toLowerCase()) {
      case 'completed':
      case 'success':
        statusColor = AppTheme.successColor;
        break;
      case 'pending':
        statusColor = AppTheme.warningColor;
        break;
      case 'failed':
      case 'error':
        statusColor = AppTheme.errorColor;
        break;
      default:
        statusColor = AppTheme.textSecondary;
    }

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(AppTheme.spacingS),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Icon(
          Icons.payment,
          color: statusColor,
        ),
      ),
      title: Text(
        '\$${amount}',
        style: AppTheme.bodyLarge.copyWith(
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            payment['description'] ?? 'Therapy Session',
            style: AppTheme.bodyMedium.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            date,
            style: AppTheme.bodySmall.copyWith(
              color: AppTheme.textLight,
            ),
          ),
        ],
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingS,
          vertical: AppTheme.spacingXS,
        ),
        decoration: BoxDecoration(
          color: statusColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppTheme.radiusS),
        ),
        child: Text(
          status,
          style: AppTheme.bodySmall.copyWith(
            color: statusColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  void _addPaymentMethod() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Payment Method'),
        content: const Text(
            'Payment method integration with Stripe will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _setDefaultPaymentMethod(String methodId) {
    setState(() {
      for (var method in _paymentMethods) {
        method['isDefault'] = method['id'] == methodId;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Default payment method updated'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _deletePaymentMethod(String methodId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content:
            const Text('Are you sure you want to delete this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _paymentMethods
                    .removeWhere((method) => method['id'] == methodId);
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Payment method deleted'),
                  backgroundColor: AppTheme.successColor,
                ),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
