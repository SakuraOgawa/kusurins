import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddMedicationScreen extends StatefulWidget {
  final String userName;

  const AddMedicationScreen({super.key, required this.userName});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _doseController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  bool _isSaving = false;

  /// Firestore にお薬を保存
  Future<void> _saveMedication() async {
    final name = _nameController.text.trim();
    final dose = _doseController.text.trim();
    final time = _timeController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('おくすりの名前を入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userName)
          .collection('medications')
          .add({
        'name': name,
        'dose': dose,
        'time': time,
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('おくすりを追加しました')),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存に失敗しました: $e')),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: const Text('おくすりを追加'),
        backgroundColor: Colors.red[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'おくすりの名前',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _doseController,
              decoration: const InputDecoration(
                labelText: '服用量（例：1錠）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: '服用時間（例：朝・昼・夜）',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _saveMedication,
                    icon: const Icon(Icons.save),
                    label: const Text('保存する'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 32),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}