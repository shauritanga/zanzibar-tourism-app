import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zanzibar_tourism/providers/payment_provider.dart';
import 'package:zanzibar_tourism/services/payment_service.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final double amount;
  final String description;
  final String userId;
  final Map<String, dynamic>? metadata;

  const PaymentScreen({
    super.key,
    required this.amount,
    required this.description,
    required this.userId,
    this.metadata,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentMethod _selectedMethod = PaymentMethod.stripe;
  final _phoneController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      Map<String, dynamic>? metadata = widget.metadata;
      
      // Add phone number for M-Pesa
      if (_selectedMethod == PaymentMethod.mpesa) {
        if (_phoneController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter your phone number')),
          );
          setState(() => _isProcessing = false);
          return;
        }
        metadata = {...?metadata, 'phoneNumber': _phoneController.text.trim()};
      }

      await ref.read(paymentNotifierProvider.notifier).processPayment(
        userId: widget.userId,
        amount: widget.amount,
        currency: 'USD',
        method: _selectedMethod,
        description: widget.description,
        metadata: metadata,
      );

      // Listen to payment result
      ref.listen(paymentNotifierProvider, (previous, next) {
        next.when(
          data: (result) {
            if (result != null && result['success'] == true) {
              _showSuccessDialog(result);
            } else if (result != null && result['success'] == false) {
              _showErrorDialog(result['error'] ?? 'Payment failed');
            }
          },
          loading: () {},
          error: (error, stack) {
            _showErrorDialog(error.toString());
          },
        );
      });
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 8),
            Text('Payment Successful'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${widget.amount.toStringAsFixed(2)}'),
            Text('Payment ID: ${result['paymentId']}'),
            if (result['data']?['transactionId'] != null)
              Text('Transaction ID: ${result['data']['transactionId']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to previous screen with success
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Payment Failed'),
          ],
        ),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Payment Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Summary',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('Description: ${widget.description}'),
                    const SizedBox(height: 4),
                    Text(
                      'Amount: \$${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Payment Method Selection
            const Text(
              'Select Payment Method',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Stripe Option
            Card(
              child: RadioListTile<PaymentMethod>(
                title: const Text('Credit/Debit Card'),
                subtitle: const Text('Pay with Visa, Mastercard, or other cards'),
                value: PaymentMethod.stripe,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
                secondary: const Icon(Icons.credit_card, color: Colors.blue),
              ),
            ),

            // M-Pesa Option
            Card(
              child: RadioListTile<PaymentMethod>(
                title: const Text('M-Pesa'),
                subtitle: const Text('Pay with your mobile money'),
                value: PaymentMethod.mpesa,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
                secondary: const Icon(Icons.phone_android, color: Colors.green),
              ),
            ),

            // Cash Option
            Card(
              child: RadioListTile<PaymentMethod>(
                title: const Text('Cash'),
                subtitle: const Text('Pay in person at pickup'),
                value: PaymentMethod.cash,
                groupValue: _selectedMethod,
                onChanged: (value) {
                  setState(() => _selectedMethod = value!);
                },
                secondary: const Icon(Icons.money, color: Colors.orange),
              ),
            ),

            // M-Pesa Phone Number Input
            if (_selectedMethod == PaymentMethod.mpesa) ...[
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  hintText: '+255 XXX XXX XXX',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
            ],

            const Spacer(),

            // Pay Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _processPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Pay \$${widget.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
