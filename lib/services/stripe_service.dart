import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StripeService {
  static const String _baseUrl = 'http:// 192.168.2.102:3000/api/stripe';

  // Initialize Stripe with publishable key
  static Future<void> init() async {
    Stripe.publishableKey =
        'pk_test_51RCF7D2XdGiu93ZvZQcJgRtZDWfK1mxn2HyNUAMvaOBnbBfwu8opr4OIjcI1yssA92P88ZhXNsCkAODg2YemU3aR008klErbkH';
    await Stripe.instance.applySettings();
  }

  // Create a Stripe customer
  static Future<Map<String, dynamic>?> createCustomer({
    required String email,
    required String name,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/createcustomer'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'name': name,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['customer'];
      } else {
        print('Failed to create customer: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error creating customer: $e');
      return null;
    }
  }

  // Create payment intent
  static Future<Map<String, dynamic>?> createPaymentIntent({
    required double amount,
    required String currency,
    String? customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/create-payment-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'amount': (amount * 100).round(), // Convert to cents
          'currency': currency,
          'customerId': customerId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create payment intent: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating payment intent: $e');
      return null;
    }
  }

  // Process payment with proper error handling
  static Future<bool> processPayment({
    required String clientSecret,
    required String email,
  }) async {
    try {
      // Initialize payment sheet with better error handling
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'MindEase',
          customerEphemeralKeySecret: null,
          customerId: null,
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6366F1),
            ),
          ),
        ),
      );

      // Present payment sheet with proper error handling
      await Stripe.instance.presentPaymentSheet();

      debugPrint('Payment completed successfully');
      return true;
    } on StripeException catch (e) {
      debugPrint('Stripe error: ${e.error.localizedMessage}');

      // Handle specific Stripe errors
      switch (e.error.code) {
        case FailureCode.Canceled:
          debugPrint('Payment was canceled by user');
          return false;
        case FailureCode.Failed:
          debugPrint('Payment failed');
          return false;
        default:
          debugPrint('Unknown Stripe error: ${e.error.localizedMessage}');
          return false;
      }
    } catch (e) {
      debugPrint('General payment error: $e');
      return false;
    }
  }

  // Alternative simple payment method for testing
  static Future<bool> processSimplePayment({
    required double amount,
    required String currency,
  }) async {
    try {
      // For testing purposes, simulate payment success after delay
      await Future.delayed(const Duration(seconds: 2));
      debugPrint(
          'Simulated payment of \$${amount.toStringAsFixed(2)} completed');
      return true;
    } catch (e) {
      debugPrint('Simulated payment failed: $e');
      return false;
    }
  }

  // Create setup intent for adding payment methods
  static Future<Map<String, dynamic>?> createSetupIntent({
    String? customerId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/create-setup-intent'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'customer_id': customerId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create setup intent: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating setup intent: $e');
      return null;
    }
  }

  // Setup payment method using setup intent
  static Future<bool> setupPaymentMethod({
    required String clientSecret,
  }) async {
    try {
      // Initialize payment sheet for setup
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          setupIntentClientSecret: clientSecret,
          merchantDisplayName: 'MindEase',
          style: ThemeMode.system,
          appearance: const PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Color(0xFF6366F1),
            ),
          ),
        ),
      );

      // Present payment sheet
      await Stripe.instance.presentPaymentSheet();

      debugPrint('Payment method setup completed successfully');
      return true;
    } on StripeException catch (e) {
      debugPrint('Stripe setup error: ${e.error.localizedMessage}');
      return false;
    } catch (e) {
      debugPrint('Setup payment method failed: $e');
      return false;
    }
  }
}
