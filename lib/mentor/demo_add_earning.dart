import 'package:flutter/material.dart';
import '../utils/transaction_helper.dart';

/// Demo page to test adding earnings to mentor balance
/// In production, this would be called when a student books/pays for a session
class DemoAddEarning extends StatefulWidget {
  final String mentorUid;
  final String mentorName;

  const DemoAddEarning({
    super.key,
    required this.mentorUid,
    required this.mentorName,
  });

  @override
  State<DemoAddEarning> createState() => _DemoAddEarningState();
}

class _DemoAddEarningState extends State<DemoAddEarning> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool isLoading = false;

  Future<void> _addEarning() async {
    if (_amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Masukkan jumlah pembayaran')),
      );
      return;
    }

    double? amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah tidak valid')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await TransactionHelper.addEarning(
        mentorUid: widget.mentorUid,
        amount: amount,
        description: _descriptionController.text.isEmpty
            ? 'Pembayaran sesi mentoring'
            : _descriptionController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Berhasil menambah Rp$amount ke saldo mentor'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error: $e')),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tambah Pemasukan',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green[700],
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.green[700], size: 32),
                    const SizedBox(height: 8),
                    Text(
                      'Mentor: ${widget.mentorName}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Demo: Simulasi pembayaran dari pelajar',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Jumlah (Rp)',
                hintText: 'Contoh: 100000',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Deskripsi (opsional)',
                hintText: 'Contoh: Pembayaran sesi Matematika',
                prefixIcon: const Icon(Icons.description),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _addEarning,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Tambah Pemasukan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
