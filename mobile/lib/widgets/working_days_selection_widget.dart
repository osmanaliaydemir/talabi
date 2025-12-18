import 'package:flutter/material.dart';
import 'package:mobile/models/working_hour.dart';
import 'package:mobile/l10n/app_localizations.dart';

class WorkingDaysSelectionWidget extends StatefulWidget {
  const WorkingDaysSelectionWidget({
    super.key,
    required this.initialWorkingHours,
    required this.onWorkingHoursChanged,
  });

  final List<WorkingHour> initialWorkingHours;
  final ValueChanged<List<WorkingHour>> onWorkingHoursChanged;

  @override
  State<WorkingDaysSelectionWidget> createState() =>
      _WorkingDaysSelectionWidgetState();
}

class _WorkingDaysSelectionWidgetState
    extends State<WorkingDaysSelectionWidget> {
  late List<WorkingHour> _workingHours;

  @override
  void initState() {
    super.initState();
    _initWorkingHours();
  }

  void _initWorkingHours() {
    _workingHours = List.from(widget.initialWorkingHours);
    _ensureAllDaysPresent();
  }

  void _ensureAllDaysPresent() {
    // We expect 7 days (0-6). If missing, add closed days.
    // This assumes specific DayOfWeek mapping (0=Sunday, 1=Monday, etc.) matching backend.

    // Create a map for easy lookup
    final existingMap = {for (final h in _workingHours) h.dayOfWeek: h};
    // Default English names if localization not available in model
    final List<String> defaultDayNames = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];

    final List<WorkingHour> completeList = [];
    for (int i = 0; i < 7; i++) {
      if (existingMap.containsKey(i)) {
        completeList.add(existingMap[i]!);
      } else {
        completeList.add(
          WorkingHour(
            dayOfWeek: i,
            dayName: defaultDayNames[i],
            isClosed: true,
            startTime: '09:00',
            endTime: '18:00',
          ),
        );
      }
    }

    // Sort by dayOfWeek
    completeList.sort((a, b) => a.dayOfWeek.compareTo(b.dayOfWeek));
    _workingHours = completeList;
  }

  void _updateHour(int index, WorkingHour newHour) {
    setState(() {
      _workingHours[index] = newHour;
    });
    widget.onWorkingHoursChanged(_workingHours);
  }

  Future<void> _selectTime(
    BuildContext context,
    int index,
    bool isStartTime,
  ) async {
    final hour = _workingHours[index];
    final initialTimeStr = isStartTime ? hour.startTime : hour.endTime;

    TimeOfDay initialTime = const TimeOfDay(hour: 9, minute: 0);
    if (initialTimeStr != null) {
      final parts = initialTimeStr.split(':');
      if (parts.length >= 2) {
        initialTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 9,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (BuildContext context, Widget? child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

      _updateHour(
        index,
        hour.copyWith(
          startTime: isStartTime ? timeStr : null,
          endTime: !isStartTime ? timeStr : null,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _workingHours.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final hour = _workingHours[index];
        final isClosed = hour.isClosed;
        final is24Hours =
            !isClosed && (hour.startTime == null || hour.endTime == null);

        // Handling day name localization logic could optionally be moved here
        // using AppLocalizations if we had day keys. For now using what's in model.

        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isClosed
                  ? Colors.grey.withValues(alpha: 0.2)
                  : Theme.of(context).primaryColor.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isClosed
                      ? Colors.grey.withValues(alpha: 0.1)
                      : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  hour.dayName.isNotEmpty
                      ? hour.dayName.substring(0, 1).toUpperCase()
                      : '?',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isClosed
                        ? Colors.grey
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              title: Text(
                hour.dayName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                isClosed
                    ? (AppLocalizations.of(context)?.closed ?? 'Closed')
                    : is24Hours
                    ? "24 ${AppLocalizations.of(context)?.hours ?? 'Hours'}"
                    : '${hour.startTime} - ${hour.endTime}',
                style: TextStyle(
                  color: isClosed ? Colors.red : Colors.green,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Switch(
                value: !isClosed,

                onChanged: (bool isOpen) {
                  // If turning Open, default to 24 hours (null times) or previous times?
                  // Let's default to null (24h) as per previous logic, or 09:00-18:00
                  _updateHour(
                    index,
                    hour.copyWith(
                      isClosed: !isOpen,
                      startTime: isOpen ? null : null, // 24h default
                      endTime: isOpen ? null : null,
                      allowNullTimes: true,
                    ),
                  );
                },
              ),
              children: [
                if (!isClosed) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: [
                        const Divider(),
                        const SizedBox(height: 8),
                        // 24 Hours Toggle
                        Row(
                          children: [
                            Text(
                              "24 ${AppLocalizations.of(context)?.hours ?? 'Hours'}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            Checkbox(
                              value: is24Hours,
                              activeColor: Theme.of(context).primaryColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (bool? value) {
                                if (value == true) {
                                  _updateHour(
                                    index,
                                    hour.copyWith(
                                      startTime: null,
                                      endTime: null,
                                      allowNullTimes: true,
                                    ),
                                  );
                                } else {
                                  // Default to 09:00 - 18:00 if unchecking 24h
                                  _updateHour(
                                    index,
                                    hour.copyWith(
                                      startTime: '09:00',
                                      endTime: '18:00',
                                    ),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                        if (!is24Hours) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildTimePickerButton(
                                  context,
                                  AppLocalizations.of(
                                        context,
                                      )?.workingHoursStart ??
                                      'Start',
                                  hour.startTime ?? '09:00',
                                  () => _selectTime(context, index, true),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildTimePickerButton(
                                  context,
                                  AppLocalizations.of(
                                        context,
                                      )?.workingHoursEnd ??
                                      'End',
                                  hour.endTime ?? '18:00',
                                  () => _selectTime(context, index, false),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTimePickerButton(
    BuildContext context,
    String label,
    String time,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  time,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
