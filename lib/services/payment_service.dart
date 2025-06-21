import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

final paymentServiceProvider = Provider<PaymentService>(
  (ref) => PaymentService(),
);

enum PaymentMethod { stripe, mpesa, cash }

enum PaymentStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
  refunded,
}

class PaymentService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Dio _dio = Dio();

  // Stripe configuration (use environment variables in production)
  static const String _stripePublishableKey = 'pk_test_your_stripe_key_here';
  static const String _stripeSecretKey = 'sk_test_your_stripe_key_here';

  // M-Pesa configuration (use environment variables in production)
  static const String _mpesaConsumerKey = 'your_mpesa_consumer_key';
  static const String _mpesaConsumerSecret = 'your_mpesa_consumer_secret';
  static const String _mpesaShortcode = 'your_shortcode';
  static const String _mpesaPasskey = 'your_passkey';

  Future<Map<String, dynamic>> processPayment({
    required String userId,
    required double amount,
    required String currency,
    required PaymentMethod method,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Create payment record
      final paymentId = await _createPaymentRecord(
        userId: userId,
        amount: amount,
        currency: currency,
        method: method,
        description: description,
        metadata: metadata,
      );

      Map<String, dynamic> result;

      switch (method) {
        case PaymentMethod.stripe:
          result = await _processStripePayment(
            paymentId: paymentId,
            amount: amount,
            currency: currency,
            description: description,
          );
          break;
        case PaymentMethod.mpesa:
          result = await _processMpesaPayment(
            paymentId: paymentId,
            amount: amount,
            phoneNumber: metadata?['phoneNumber'] ?? '',
            description: description,
          );
          break;
        case PaymentMethod.cash:
          result = await _processCashPayment(paymentId: paymentId);
          break;
      }

      // Update payment record with result
      await _updatePaymentRecord(paymentId, result);

      return {'success': true, 'paymentId': paymentId, 'data': result};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<String> _createPaymentRecord({
    required String userId,
    required double amount,
    required String currency,
    required PaymentMethod method,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final doc = await _firestore.collection('payments').add({
      'userId': userId,
      'amount': amount,
      'currency': currency,
      'method': method.name,
      'description': description,
      'status': PaymentStatus.pending.name,
      'metadata': metadata ?? {},
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> _updatePaymentRecord(
    String paymentId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('payments').doc(paymentId).update({
      'status': data['status'] ?? PaymentStatus.failed.name,
      'transactionId': data['transactionId'],
      'providerResponse': data['providerResponse'],
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> _processStripePayment({
    required String paymentId,
    required double amount,
    required String currency,
    required String description,
  }) async {
    try {
      // In a real implementation, you would:
      // 1. Create a payment intent on your backend
      // 2. Return the client secret to the frontend
      // 3. Use Stripe SDK to confirm payment

      // For demo purposes, we'll simulate a successful payment
      await Future.delayed(const Duration(seconds: 2));

      return {
        'status': PaymentStatus.completed.name,
        'transactionId': 'stripe_${DateTime.now().millisecondsSinceEpoch}',
        'providerResponse': {
          'id': 'pi_test_${DateTime.now().millisecondsSinceEpoch}',
          'amount': (amount * 100).toInt(), // Stripe uses cents
          'currency': currency.toLowerCase(),
          'status': 'succeeded',
        },
      };
    } catch (e) {
      return {'status': PaymentStatus.failed.name, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _processMpesaPayment({
    required String paymentId,
    required double amount,
    required String phoneNumber,
    required String description,
  }) async {
    try {
      // Get M-Pesa access token
      final accessToken = await _getMpesaAccessToken();

      // Generate timestamp and password
      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(RegExp(r'[^\d]'), '')
          .substring(0, 14);
      final password = base64Encode(
        utf8.encode('$_mpesaShortcode$_mpesaPasskey$timestamp'),
      );

      // Initiate STK push
      final response = await _dio.post(
        'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
        data: {
          'BusinessShortCode': _mpesaShortcode,
          'Password': password,
          'Timestamp': timestamp,
          'TransactionType': 'CustomerPayBillOnline',
          'Amount': amount.toInt(),
          'PartyA': phoneNumber,
          'PartyB': _mpesaShortcode,
          'PhoneNumber': phoneNumber,
          'CallBackURL': 'https://your-app.com/mpesa/callback',
          'AccountReference': paymentId,
          'TransactionDesc': description,
        },
      );

      if (response.statusCode == 200) {
        return {
          'status': PaymentStatus.processing.name,
          'transactionId': response.data['CheckoutRequestID'],
          'providerResponse': response.data,
        };
      } else {
        throw Exception('M-Pesa payment failed: ${response.data}');
      }
    } catch (e) {
      return {'status': PaymentStatus.failed.name, 'error': e.toString()};
    }
  }

  Future<String> _getMpesaAccessToken() async {
    final credentials = base64Encode(
      utf8.encode('$_mpesaConsumerKey:$_mpesaConsumerSecret'),
    );

    final response = await _dio.get(
      'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials',
      options: Options(headers: {'Authorization': 'Basic $credentials'}),
    );

    if (response.statusCode == 200) {
      return response.data['access_token'];
    } else {
      throw Exception('Failed to get M-Pesa access token');
    }
  }

  Future<Map<String, dynamic>> _processCashPayment({
    required String paymentId,
  }) async {
    // For cash payments, mark as pending for manual verification
    return {
      'status': PaymentStatus.pending.name,
      'transactionId': 'cash_$paymentId',
      'providerResponse': {
        'method': 'cash',
        'note': 'Payment to be collected in person',
      },
    };
  }

  Future<List<Map<String, dynamic>>> getPaymentHistory(String userId) async {
    final snapshot =
        await _firestore
            .collection('payments')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  Future<Map<String, dynamic>?> getPaymentDetails(String paymentId) async {
    final doc = await _firestore.collection('payments').doc(paymentId).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  Future<void> refundPayment(String paymentId, {String? reason}) async {
    final payment = await getPaymentDetails(paymentId);
    if (payment == null) throw Exception('Payment not found');

    // In a real implementation, you would call the payment provider's refund API
    // For now, we'll just update the status
    await _firestore.collection('payments').doc(paymentId).update({
      'status': PaymentStatus.refunded.name,
      'refundReason': reason,
      'refundedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Map<String, dynamic>> generatePaymentReceipt(String paymentId) async {
    final payment = await getPaymentDetails(paymentId);
    if (payment == null) throw Exception('Payment not found');

    // Generate receipt data
    return {
      'receiptId': 'RCP_${DateTime.now().millisecondsSinceEpoch}',
      'paymentId': paymentId,
      'amount': payment['amount'],
      'currency': payment['currency'],
      'method': payment['method'],
      'status': payment['status'],
      'transactionId': payment['transactionId'],
      'description': payment['description'],
      'createdAt': payment['createdAt'],
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }
}
