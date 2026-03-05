import 'package:flutter/material.dart';

class ExpirationTimePicker extends StatefulWidget {
  final int initialDays;
  final Function(int) onChanged;

  const ExpirationTimePicker({
    super.key,
    required this.initialDays,
    required this.onChanged,
  });

  @override
  State<ExpirationTimePicker> createState() => _ExpirationTimePickerState();
}

class _ExpirationTimePickerState extends State<ExpirationTimePicker> {
  late int _selectedDays;
  final TextEditingController _customController = TextEditingController();

  final List<Map<String, dynamic>> _presetOptions = [
    {'days': 1, 'label': '1 Day', 'description': 'Files expire in 24 hours'},
    {'days': 3, 'label': '3 Days', 'description': 'Files expire in 3 days'},
    {'days': 7, 'label': '7 Days', 'description': 'Files expire in 1 week'},
    {'days': 14, 'label': '14 Days', 'description': 'Files expire in 2 weeks'},
    {'days': 30, 'label': '30 Days', 'description': 'Files expire in 1 month'},
    {'days': -1, 'label': 'Custom', 'description': 'Set custom expiration'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedDays = widget.initialDays;
    if (!_presetOptions.any((option) => option['days'] == _selectedDays)) {
      _customController.text = _selectedDays.toString();
    }
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _updateSelection(int days) {
    setState(() {
      _selectedDays = days;
    });
    widget.onChanged(days);
  }

  DateTime _calculateExpirationDate(int days) {
    return DateTime.now().add(Duration(days: days));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'File Access Duration',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'How long should the receiver have access to these files?',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        // Preset options
        ..._presetOptions.map((option) {
          final days = option['days'] as int;
          final isSelected = _selectedDays == days;
          final isCustom = days == -1;
          
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: isSelected ? Colors.blue.shade50 : null,
            child: RadioListTile<int>(
              value: days,
              groupValue: _selectedDays,
              onChanged: (value) {
                if (value != null) {
                  _updateSelection(value);
                }
              },
              title: Text(
                option['label'],
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              subtitle: isCustom 
                  ? null 
                  : Text(
                      option['description'],
                      style: TextStyle(
                        color: isSelected ? Colors.blue.shade700 : Colors.grey[600],
                      ),
                    ),
              activeColor: Colors.blue,
            ),
          );
        }).toList(),
        
        // Custom input field
        if (_selectedDays == -1) ...[
          const SizedBox(height: 16),
          TextField(
            controller: _customController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Custom Days',
              hintText: 'Enter number of days',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule),
            ),
            onChanged: (value) {
              final days = int.tryParse(value);
              if (days != null && days > 0) {
                _updateSelection(days);
              }
            },
          ),
        ],
        
        const SizedBox(height: 16),
        
        // Expiration preview
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.blue.shade700,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Files will expire on:',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _formatDate(_calculateExpirationDate(_selectedDays)),
                      style: TextStyle(
                        color: Colors.blue.shade900,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);
    
    if (difference.inDays == 0) {
      return 'Today at ${_formatTime(date)}';
    } else if (difference.inDays == 1) {
      return 'Tomorrow at ${_formatTime(date)}';
    } else {
      return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
