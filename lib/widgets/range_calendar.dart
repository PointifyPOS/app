import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A selected date range. [endDate] is null while only the first day is picked.
class PickerDateRange {
  final DateTime? startDate;
  final DateTime? endDate;
  const PickerDateRange(this.startDate, this.endDate);
}

/// Inline month calendar for picking a date range (no third-party licence needed).
///
/// Tap a first day, then a last day. [onSelectionChanged] fires on every tap;
/// with [showActionButtons], [onSubmit] fires when the confirm button is pressed.
class RangeCalendar extends StatefulWidget {
  final DateTime? minDate;
  final DateTime? maxDate;
  final bool showActionButtons;
  final String confirmText;
  final Color? color;
  final ValueChanged<PickerDateRange>? onSelectionChanged;
  final ValueChanged<PickerDateRange>? onSubmit;
  final VoidCallback? onCancel;

  const RangeCalendar({
    super.key,
    this.minDate,
    this.maxDate,
    this.showActionButtons = false,
    this.confirmText = "OK",
    this.color,
    this.onSelectionChanged,
    this.onSubmit,
    this.onCancel,
  });

  @override
  State<RangeCalendar> createState() => _RangeCalendarState();
}

class _RangeCalendarState extends State<RangeCalendar> {
  late DateTime _month;
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
  }

  DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _enabled(DateTime d) {
    if (widget.maxDate != null && d.isAfter(_day(widget.maxDate!))) return false;
    if (widget.minDate != null && d.isBefore(_day(widget.minDate!))) return false;
    return true;
  }

  void _tap(DateTime d) {
    setState(() {
      if (_start == null || _end != null || d.isBefore(_start!)) {
        _start = d;
        _end = null;
      } else {
        _end = d;
      }
    });
    widget.onSelectionChanged?.call(PickerDateRange(_start, _end));
  }

  void _changeMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final color = widget.color ?? Theme.of(context).colorScheme.primary;
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month, 1).weekday % 7; // Sunday first
    final cells = <Widget>[
      for (final w in const ["S", "M", "T", "W", "T", "F", "S"])
        Center(
            child: Text(w,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black54))),
      for (var i = 0; i < leading; i++) const SizedBox.shrink(),
      for (var day = 1; day <= daysInMonth; day++)
        _dayCell(DateTime(_month.year, _month.month, day), color),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => _changeMonth(-1)),
            Expanded(
              child: Text(DateFormat("MMMM yyyy").format(_month),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: color, fontSize: 18)),
            ),
            IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => _changeMonth(1)),
          ],
        ),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
        if (widget.showActionButtons)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null)
                  TextButton(
                      onPressed: widget.onCancel, child: const Text("Cancel")),
                TextButton(
                  onPressed: _start == null
                      ? null
                      : () => widget.onSubmit
                          ?.call(PickerDateRange(_start, _end ?? _start)),
                  child: Text(widget.confirmText,
                      style: TextStyle(color: _start == null ? null : color)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _dayCell(DateTime d, Color color) {
    final enabled = _enabled(d);
    final isEdge = d == _start || d == _end;
    final inRange =
        _start != null && _end != null && d.isAfter(_start!) && d.isBefore(_end!);
    return GestureDetector(
      onTap: enabled ? () => _tap(d) : null,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isEdge
              ? color
              : inRange
                  ? color.withValues(alpha: 0.15)
                  : null,
          shape: isEdge ? BoxShape.circle : BoxShape.rectangle,
        ),
        alignment: Alignment.center,
        child: Text(
          "${d.day}",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isEdge
                ? Colors.white
                : enabled
                    ? color
                    : Colors.black26,
          ),
        ),
      ),
    );
  }
}
