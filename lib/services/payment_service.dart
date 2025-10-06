import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentService {
  static const String _baseUrl =
      'https://mindease-backend-production.up.railway.app/api';

  // Initialize Stripe
  static Future<void> initializeStripe() async {
    Stripe.publishableKey =
        'pk_test_51234567890abcdef'; // Replace with your publishable key
    await Stripe.instance.applySettings();
  }

  // Create payment intent
  static Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    required String userId,
    required String appointmentId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': (amount * 100).round(), // Convert to cents
          'currency': currency,
          'userId': userId,
          'appointmentId': appointmentId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create payment intent');
      }
    } catch (e) {
      print('Error creating payment intent: $e');
      return null;
    }
  }

  // Process payment
  static Future<bool> processPayment({
    required BuildContext context,
    required double amount,
    required String currency,
    required String userId,
    required String appointmentId,
    required String description,
  }) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Processing payment...'),
            ],
          ),
        ),
      );

      // Create payment intent
      final paymentIntentData = await createPaymentIntent(
        amount: amount,
        currency: currency,
        userId: userId,
        appointmentId: appointmentId,
      );

      if (paymentIntentData == null) {
        Navigator.pop(context); // Close loading dialog
        _showErrorDialog(context, 'Failed to initialize payment');
        return false;
      }

      // Initialize payment sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentData['client_secret'],
          merchantDisplayName: 'MindEase',
          style: ThemeMode.system,
          billingDetails: BillingDetails(
            name: 'User', // You can get this from user data
            email: 'user@example.com', // You can get this from user data
          ),
        ),
      );

      Navigator.pop(context); // Close loading dialog

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      // Payment successful
      _showSuccessDialog(context, 'Payment successful!');
      return true;
    } on StripeException catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      _showErrorDialog(context, 'Payment failed: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      Navigator.pop(context); // Close loading dialog if still open
      _showErrorDialog(context, 'Payment failed: $e');
      return false;
    }
  }

  // Show success dialog
  static void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Success'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show error dialog
  static void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Get payment history
  static Future<List<Map<String, dynamic>>> getPaymentHistory(
      String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/payments/history/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch payment history');
      }
    } catch (e) {
      print('Error fetching payment history: $e');
      return [];
    }
  }

  // Refund payment
  static Future<bool> refundPayment({
    required String paymentIntentId,
    required double amount,
    required String reason,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/payments/refund'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'paymentIntentId': paymentIntentId,
          'amount': (amount * 100).round(), // Convert to cents
          'reason': reason,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error processing refund: $e');
      return false;
    }
  }

  // Show payment options dialog
  static void showPaymentDialog({
    required BuildContext context,
    required double amount,
    required String description,
    required String userId,
    required String appointmentId,
    required VoidCallback onSuccess,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Payment Required'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(description),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('\$${amount.toStringAsFixed(2)}',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            SizedBox(height: 16),
            Text('Payment will be processed securely through Stripe.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await processPayment(
                context: context,
                amount: amount,
                currency: 'usd',
                userId: userId,
                appointmentId: appointmentId,
                description: description,
              );

              if (success) {
                onSuccess();
              }
            },
            child: Text('Pay Now'),
          ),
        ],
      ),
    );
  }

  // Format currency
  static String formatCurrency(double amount, {String currency = 'USD'}) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  // Validate payment amount
  static bool isValidAmount(double amount) {
    return amount > 0 && amount <= 999999.99;
  }
}
