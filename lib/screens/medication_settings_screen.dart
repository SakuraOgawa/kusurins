import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MedicationSettingsScreen extends StatefulWidget {
  final String userName;
  final String? medId;
  final Map<String, dynamic>? existingData;

  const MedicationSettingsScreen({
    super.key,
    required this.userName,
    this.medId,
    this.existingData,
  });

  @override
  State<MedicationSettingsScreen> createState() =>
      _MedicationSettingsScreenState();
}

class _MedicationSettingsScreenState extends State<MedicationSettingsScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  String? _selectedShape;
  String? _selectedColor;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _notificationEnabled = false;
  bool _isSaving = false;

  // 🔽 朝・昼・夜・寝る前、それぞれに「時間」と「錠数」を持つ
  List<Map<String, String>> _times = List.generate(
    4,
    (_) => {'time': '', 'count': ''},
  );
  final List<String> _timeLabels = ['朝', '昼', '夜', '寝る前'];

  final List<String> shapeOptions = ['丸型', '楕円形', '四角形', 'カプセル型', 'その他'];

  final List<Map<String, dynamic>> colorOptions = [
    {'name': '白', 'color': Colors.white},
    {'name': '赤', 'color': Colors.red},
    {'name': '青', 'color': Colors.blue},
    {'name': '緑', 'color': Colors.green},
    {'name': '黄色', 'color': Colors.yellow},
    {'name': 'ピンク', 'color': Colors.pink},
    {'name': 'オレンジ', 'color': Colors.orange},
    {'name': '透明', 'color': Colors.grey[300]},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      final data = widget.existingData!;
      _nameController.text = data['name'] ?? '';
      _memoController.text = data['memo'] ?? '';
      _selectedColor = data['color'];
      _selectedShape = data['shape'];
      _notificationEnabled = data['notification'] ?? false;
      _startDate = (data['startDate'] as Timestamp?)?.toDate();
      _endDate = (data['endDate'] as Timestamp?)?.toDate();

      if (data['time'] != null) {
        final dynamic timeData = data['time'];
        if (timeData is List) {
          for (int i = 0; i < 4; i++) {
            if (i < timeData.length) {
              final t = timeData[i];
              if (t is Map<String, dynamic>) {
                _times[i]['time'] = t['time'] ?? '';
                _times[i]['count'] = t['count'] ?? '';
              } else if (t is String) {
                _times[i]['time'] = t;
              }
            }
          }
        }
      }
    }
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  Future<void> _saveMedication() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('おくすりの名前を入力してください')),
      );
      return;
    }

    // 🔽 時間形式チェック（空欄はOK）
    final timeRegExp = RegExp(r'^[0-2]?[0-9]:[0-5][0-9]$');
    for (var t in _times) {
      if (t['time']!.isNotEmpty && !timeRegExp.hasMatch(t['time']!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('時間の形式が正しくありません: ${t['time']}')),
        );
        return;
      }
    }

    // 🔽 錠数形式チェック（数字のみOK）
    final countRegExp = RegExp(r'^[0-9]+$');
    for (var t in _times) {
      if (t['count']!.isNotEmpty && !countRegExp.hasMatch(t['count']!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('錠数の形式が正しくありません: ${t['count']}')),
        );
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userName)
          .collection('medications');

      final data = {
        'name': _nameController.text,
        'color': _selectedColor ?? '未設定',
        'shape': _selectedShape ?? '未設定',
        'time': _times,
        'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
        'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
        'notification': _notificationEnabled,
        'memo': _memoController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.medId == null) {
        await docRef.add(data);
      } else {
        await docRef.doc(widget.medId).update(data);
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint('保存に失敗: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.medId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'おくすり情報を編集' : 'おくすりを追加'),
        backgroundColor: Colors.red[200],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'おくすりの名前'),
            ),
            const SizedBox(height: 16),

            const Text('おくすりの色'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: colorOptions.map((color) {
                final isSelected = _selectedColor == color['name'];
                return ChoiceChip(
                  label: Text(color['name']),
                  selected: isSelected,
                  selectedColor: Colors.red[100],
                  backgroundColor: Colors.grey[200],
                  avatar: CircleAvatar(
                    backgroundColor: color['color'],
                  ),
                  onSelected: (_) {
                    setState(() {
                      _selectedColor = color['name'];
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedShape,
              decoration: const InputDecoration(labelText: 'おくすりの形状'),
              items: shapeOptions
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedShape = v),
            ),

            const SizedBox(height: 16),
            const Text('服用時間・錠数'),
            const SizedBox(height: 8),

            Column(
              children: List.generate(4, (i) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          decoration: InputDecoration(
                            labelText: '${_timeLabels[i]}の時間',
                            hintText: '例: 08:30',
                            border: const OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.datetime,
                          onChanged: (v) => _times[i]['time'] = v,
                          controller:
                              TextEditingController(text: _times[i]['time']),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            labelText: '錠数',
                            hintText: '例: 2',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _times[i]['count'] = v,
                          controller:
                              TextEditingController(text: _times[i]['count']),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

            const SizedBox(height: 16),
            ListTile(
              title: Text(_startDate != null && _endDate != null
                  ? '服薬期間: ${_startDate!.toLocal().toString().split(' ')[0]} 〜 ${_endDate!.toLocal().toString().split(' ')[0]}'
                  : '服薬期間を選択'),
              trailing: const Icon(Icons.date_range),
              onTap: _pickDateRange,
            ),

            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('通知を受け取る'),
              value: _notificationEnabled,
              onChanged: (v) => setState(() => _notificationEnabled = v),
            ),

            const SizedBox(height: 16),
            TextField(
              controller: _memoController,
              decoration: const InputDecoration(
                labelText: 'メモ',
                hintText: '注意事項などを入力',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),

            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: Text(isEdit ? '変更を保存' : '追加する'),
              onPressed: _isSaving ? null : _saveMedication,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[200],
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}