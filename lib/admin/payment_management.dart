import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:myapp/theme/app_theme.dart';

class PaymentManagementScreen extends StatefulWidget {
  const PaymentManagementScreen({super.key});

  @override
  _PaymentManagementScreenState createState() =>
      _PaymentManagementScreenState();
}

class _PaymentManagementScreenState extends State<PaymentManagementScreen> {
  List<Map<String, dynamic>> _payments = [];
  List<Map<String, dynamic>> _filteredPayments = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';

  // Commission rate (20% for the platform)
  final double _commissionRate = 0.20;

  final List<String> _filterOptions = [
    'All',
    'Completed',
    'Pending',
    'Failed',
    'Refunded'
  ];

  // Summary data
  double _totalRevenue = 0.0;
  double _totalCommission = 0.0;
  double _totalTherapistPayouts = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchPayments();
    _searchController.addListener(_filterPayments);
  }

  Future<void> _fetchPayments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('http:// 192.168.2.102:3000/api/payments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _payments = data.cast<Map<String, dynamic>>();
          _filteredPayments = _payments;
          _calculateSummary();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load payments');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorDialog('Failed to fetch payments: $e');
    }
  }

  void _calculateSummary() {
    _totalRevenue = 0.0;
    _totalCommission = 0.0;
    _totalTherapistPayouts = 0.0;

    for (var payment in _payments) {
      if (payment['status'] == 'Completed') {
        final amount = (payment['amount'] ?? 0).toDouble();
        _totalRevenue += amount;
        final commission = amount * _commissionRate;
        _totalCommission += commission;
        _totalTherapistPayouts += (amount - commission);
      }
    }
  }

  void _filterPayments() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredPayments = _payments.where((payment) {
        final userEmail = payment['userEmail']?.toString().toLowerCase() ?? '';
        final therapistEmail =
            payment['therapistEmail']?.toString().toLowerCase() ?? '';
        final status = payment['status']?.toString().toLowerCase() ?? '';
        final paymentId = payment['_id']?.toString().toLowerCase() ?? '';

        // Text search
        final matchesSearch = userEmail.contains(query) ||
            therapistEmail.contains(query) ||
            status.contains(query) ||
            paymentId.contains(query);

        // Filter by status
        final matchesFilter = _selectedFilter == 'All' ||
            status.contains(_selectedFilter.toLowerCase());

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _showPaymentDetails(Map<String, dynamic> payment) {
    final amount = (payment['amount'] ?? 0).toDouble();
    final commission = amount * _commissionRate;
    final therapistPayout = amount - commission;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Payment ID', payment['_id'] ?? 'N/A'),
              _buildDetailRow('User Email', payment['userEmail'] ?? 'N/A'),
              _buildDetailRow(
                  'Therapist Email', payment['therapistEmail'] ?? 'N/A'),
              _buildDetailRow('Amount Paid', '\$${amount.toStringAsFixed(2)}'),
              _buildDetailRow(
                  'Platform Commission (${(_commissionRate * 100).toInt()}%)',
                  '\$${commission.toStringAsFixed(2)}'),
              _buildDetailRow('Therapist Payout',
                  '\$${therapistPayout.toStringAsFixed(2)}'),
              _buildDetailRow('Status', payment['status'] ?? 'N/A'),
              _buildDetailRow(
                  'Payment Method', payment['paymentMethod'] ?? 'N/A'),
              _buildDetailRow(
                  'Stripe Payment ID', payment['stripePaymentId'] ?? 'N/A'),
              _buildDetailRow(
                  'Appointment ID', payment['appointmentId'] ?? 'N/A'),
              _buildDetailRow('Created', payment['createdAt'] ?? 'N/A'),
              if (payment['refundedAt'] != null)
                _buildDetailRow('Refunded At', payment['refundedAt']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (payment['status'] == 'Completed')
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showRefundDialog(payment);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Process Refund'),
            ),
        ],
      ),
    );
  }

  void _showRefundDialog(Map<String, dynamic> payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Process Refund'),
        content: Text(
            'Are you sure you want to process a refund for this payment of \$${payment['amount']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processRefund(payment['_id']);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Process Refund'),
          ),
        ],
      ),
    );
  }

  Future<void> _processRefund(String paymentId) async {
    try {
      final response = await http.post(
        Uri.parse('http:// 192.168.2.102:3000/api/payments/$paymentId/refund'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        _fetchPayments(); // Refresh the list
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Refund processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        throw Exception('Failed to process refund');
      }
    } catch (e) {
      _showErrorDialog('Failed to process refund: $e');
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'refunded':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Summary Cards
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[50],
            child: Column(
              children: [
                GridView.count(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.2,
                  children: [
                    _buildSummaryCard(
                      'Total Revenue',
                      '\$${_totalRevenue.toStringAsFixed(2)}',
                      Colors.blue,
                      Icons.attach_money,
                    ),
                    _buildSummaryCard(
                      'Platform Commission',
                      '\$${_totalCommission.toStringAsFixed(2)}',
                      Colors.green,
                      Icons.business,
                    ),
                    _buildSummaryCard(
                      'Therapist Payouts',
                      '\$${_totalTherapistPayouts.toStringAsFixed(2)}',
                      Colors.purple,
                      Icons.psychology,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search and Filter
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText:
                        'Search payments by user, therapist, or payment ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedFilter,
                        decoration: const InputDecoration(
                          labelText: 'Filter by Status',
                          border: OutlineInputBorder(),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _filterOptions.map((filter) {
                          return DropdownMenuItem(
                            value: filter,
                            child: Text(filter),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedFilter = value!;
                          });
                          _filterPayments();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchPayments,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total Payments: ${_filteredPayments.length}',
                  style: AppTheme.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Payments List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPayments.isEmpty
                    ? const Center(
                        child: Text(
                          'No payments found',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredPayments.length,
                        itemBuilder: (context, index) {
                          final payment = _filteredPayments[index];
                          final status = payment['status'] ?? 'Unknown';
                          final amount = (payment['amount'] ?? 0).toDouble();
                          final commission = amount * _commissionRate;
                          final therapistPayout = amount - commission;

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getStatusColor(status),
                                child: const Icon(
                                  Icons.payment,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                '${payment['userEmail'] ?? 'Unknown User'} → ${payment['therapistEmail'] ?? 'Unknown Therapist'}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                      'Amount: \$${amount.toStringAsFixed(2)} | Status: $status'),
                                  Text(
                                      'Commission: \$${commission.toStringAsFixed(2)} | Therapist: \$${therapistPayout.toStringAsFixed(2)}'),
                                  Text(
                                      'Payment ID: ${payment['_id'] ?? 'N/A'}'),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.info),
                                onPressed: () => _showPaymentDetails(payment),
                              ),
                              onTap: () => _showPaymentDetails(payment),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
