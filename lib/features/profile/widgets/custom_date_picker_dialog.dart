import 'package:flutter/material.dart';

/// 1:1 Strict Pure Flutter Recreation of `#custom-datepicker-overlay`
class CustomDatePickerDialog extends StatefulWidget {
  final DateTime initialDate;
  final ValueChanged<DateTime> onConfirm;
  final VoidCallback onCancel;

  const CustomDatePickerDialog({
    super.key,
    required this.initialDate,
    required this.onConfirm,
    required this.onCancel,
  });

  static Future<DateTime?> show(BuildContext context, {DateTime? initialDate}) {
    return showDialog<DateTime>(
      context: context,
      barrierColor: const Color(0x66000000),
      builder: (ctx) => CustomDatePickerDialog(
        initialDate: initialDate ?? DateTime(1990, 1, 1),
        onConfirm: (date) => Navigator.of(ctx).pop(date),
        onCancel: () => Navigator.of(ctx).pop(null),
      ),
    );
  }

  @override
  State<CustomDatePickerDialog> createState() => _CustomDatePickerDialogState();
}

class _CustomDatePickerDialogState extends State<CustomDatePickerDialog> {
  late DateTime _selectedDate;
  late DateTime _viewMonth;
  bool _showYearPicker = false;

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  static const _weekdays = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _viewMonth = DateTime(_selectedDate.year, _selectedDate.month, 1);
  }

  void _onMonthOffset(int offset) {
    setState(() {
      _viewMonth = DateTime(_viewMonth.year, _viewMonth.month + offset, 1);
    });
  }

  String _formatHeaderDate(DateTime dt) {
    const weekdaysLong = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const monthsShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final wd = weekdaysLong[dt.weekday - 1];
    final m = monthsShort[dt.month - 1];
    return '$wd, $m ${dt.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Container(
          width: 320,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFFFF),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. Header (.datepicker-header)
              GestureDetector(
                onTap: () => setState(() => _showYearPicker = !_showYearPicker),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF0B9175), Color(0xFF005140)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${_selectedDate.year}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xD9FFFFFF),
                            ),
                          ),
                          Icon(
                            _showYearPicker ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatHeaderDate(_selectedDate),
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Body (Year list or Month Calendar Grid)
              _showYearPicker ? _buildYearPicker() : _buildCalendarGrid(),

              // 3. Action Buttons (.datepicker-actions)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: widget.onCancel,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF005140),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => widget.onConfirm(_selectedDate),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005140),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9999),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: const Text(
                        'OK',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
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

  Widget _buildYearPicker() {
    final currentYear = DateTime.now().year;
    const startYear = 1920;
    final years = List.generate(currentYear - startYear + 1, (i) => currentYear - i);

    return SizedBox(
      height: 260,
      child: ListView.builder(
        itemCount: years.length,
        itemBuilder: (context, index) {
          final year = years[index];
          final isSelected = year == _selectedDate.year;

          return InkWell(
            onTap: () {
              setState(() {
                _selectedDate = DateTime(year, _selectedDate.month, _selectedDate.day);
                _viewMonth = DateTime(year, _selectedDate.month, 1);
                _showYearPicker = false;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              child: Text(
                '$year',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: isSelected ? 18 : 15,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? const Color(0xFF005140) : const Color(0xFF181C1A),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final year = _viewMonth.year;
    final month = _viewMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final totalDaysInMonth = DateTime(year, month + 1, 0).day;
    // Weekday: 1=Mon .. 7=Sun. In Sunday-first grid: Sun=0, Mon=1 .. Sat=6
    final startOffset = firstDayOfMonth.weekday % 7;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Month navigation (.datepicker-nav)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 22, color: Color(0xFF005140)),
                onPressed: () => _onMonthOffset(-1),
                splashRadius: 20,
              ),
              Text(
                '${_months[month - 1]} $year',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF181C1A),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 22, color: Color(0xFF005140)),
                onPressed: () => _onMonthOffset(1),
                splashRadius: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Weekday Labels (.datepicker-weekdays)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: _weekdays.map((w) {
              return SizedBox(
                width: 32,
                child: Text(
                  w,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6E7A75),
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Days Grid (.datepicker-days)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: startOffset + totalDaysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemBuilder: (context, index) {
              if (index < startOffset) {
                return const SizedBox.shrink();
              }

              final day = index - startOffset + 1;
              final isSelected = day == _selectedDate.day &&
                  month == _selectedDate.month &&
                  year == _selectedDate.year;

              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedDate = DateTime(year, month, day);
                  });
                },
                borderRadius: BorderRadius.circular(9999),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF005140) : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? Colors.white : const Color(0xFF181C1A),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
