import 'package:flutter/material.dart';
import '../models/station_data.dart';

enum StationPickerType { origin, destination }

class RouteSelectionResult {
  final String? origin;
  final String? destination;

  const RouteSelectionResult({
    this.origin,
    this.destination,
  });
}

/// 1:1 Strict Pure Flutter Recreation of `#custom-station-overlay` from Web Prototype/index.html
class StationPickerBottomSheet extends StatefulWidget {
  final StationPickerType initialType;
  final String? currentOrigin;
  final String? currentDestination;

  const StationPickerBottomSheet({
    super.key,
    required this.initialType,
    this.currentOrigin,
    this.currentDestination,
  });

  static Future<RouteSelectionResult?> show(
    BuildContext context, {
    required StationPickerType pickerType,
    String? currentOrigin,
    String? currentDestination,
  }) {
    return showModalBottomSheet<RouteSelectionResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (ctx) => StationPickerBottomSheet(
        initialType: pickerType,
        currentOrigin: currentOrigin,
        currentDestination: currentDestination,
      ),
    );
  }

  @override
  State<StationPickerBottomSheet> createState() => _StationPickerBottomSheetState();
}

class _StationPickerBottomSheetState extends State<StationPickerBottomSheet> {
  late StationPickerType _currentType;
  String? _selectedOrigin;
  String? _selectedDestination;

  @override
  void initState() {
    super.initState();
    _currentType = widget.initialType;
    _selectedOrigin = widget.currentOrigin;
    _selectedDestination = widget.currentDestination;
  }

  String get _title {
    if (_selectedOrigin != null && _selectedDestination != null) {
      if (_currentType == StationPickerType.origin) {
        return 'Change Origin Station';
      } else {
        return 'Change Destination';
      }
    } else if (_selectedOrigin != null) {
      return 'Select Destination';
    } else if (_selectedDestination != null) {
      return 'Select Origin Station';
    } else {
      return 'Select Origin Station';
    }
  }

  String get _subtitle {
    if (_selectedOrigin != null && _selectedDestination != null) {
      if (_currentType == StationPickerType.origin) {
        return 'Choose a new starting station (Destination is fixed)';
      } else {
        return 'Choose a new destination (Origin is fixed)';
      }
    } else if (_selectedOrigin != null) {
      return 'Where do you want to go?';
    } else if (_selectedDestination != null) {
      return 'Choose starting station (Destination is fixed)';
    } else {
      return 'Select where you want to start your journey';
    }
  }

  void _onStationTap(String stationName) {
    if (stationName == _selectedOrigin) {
      // Clicked on already selected origin -> unselect it!
      setState(() {
        _selectedOrigin = null;
        _currentType = StationPickerType.origin;
      });
      return;
    }

    if (stationName == _selectedDestination) {
      // Clicked on already selected destination -> unselect it!
      setState(() {
        _selectedDestination = null;
        _currentType = StationPickerType.destination;
      });
      return;
    }

    // Clicked on a new station
    setState(() {
      if (_currentType == StationPickerType.origin) {
        _selectedOrigin = stationName;
        if (_selectedDestination == null) {
          _currentType = StationPickerType.destination;
        }
      } else {
        _selectedDestination = stationName;
        if (_selectedOrigin == null) {
          _currentType = StationPickerType.origin;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final originIdx = _selectedOrigin != null
        ? StationData.stations.indexWhere((s) => s.nameEn == _selectedOrigin)
        : -1;
    final destIdx = _selectedDestination != null
        ? StationData.stations.indexWhere((s) => s.nameEn == _selectedDestination)
        : -1;

    final hasBoth = originIdx >= 0 && destIdx >= 0;
    final minIdx = hasBoth ? (originIdx < destIdx ? originIdx : destIdx) : -1;
    final maxIdx = hasBoth ? (originIdx > destIdx ? originIdx : destIdx) : -1;

    return Center(
      child: Container(
        width: 350,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: const Color(0xFFBEC9C3), // var(--color-outline-variant)
            width: 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40003328),
              blurRadius: 28,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Title (.modal-header)
              Text(
                _title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF005140), // var(--color-primary)
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle
              Text(
                _subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: Color(0xFF3E4945), // var(--color-on-surface-variant)
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // Scrollable Metro Line Schematic (#station-schematic-list)
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: StationData.stations.length,
                  itemBuilder: (context, idx) {
                    final station = StationData.stations[idx];
                    final isOrigin = station.nameEn == _selectedOrigin;
                    final isDest = station.nameEn == _selectedDestination;

                    // Track Highlighting
                    final isNodeActive = (hasBoth && idx >= minIdx && idx <= maxIdx) ||
                        isOrigin ||
                        isDest;
                    final isTopSegInRange = hasBoth && (idx - 1 >= minIdx && idx <= maxIdx);
                    final isBotSegInRange = hasBoth && (idx >= minIdx && idx + 1 <= maxIdx);

                    // Calculate preview fare
                    int? previewFare;
                    if (!isOrigin && !isDest) {
                      if (_selectedOrigin != null && _selectedDestination == null) {
                        previewFare = StationData.calculateFare(_selectedOrigin, station.nameEn);
                      } else if (_selectedOrigin == null && _selectedDestination != null) {
                        previewFare = StationData.calculateFare(station.nameEn, _selectedDestination);
                      } else if (hasBoth) {
                        previewFare = _currentType == StationPickerType.origin
                            ? StationData.calculateFare(station.nameEn, _selectedDestination)
                            : StationData.calculateFare(_selectedOrigin, station.nameEn);
                      }
                    }

                    Color? rowBg;
                    if (isOrigin) {
                      rowBg = const Color(0x1A10B981); // .schematic-row--origin
                    } else if (isDest) {
                      rowBg = const Color(0x14EF4444); // .schematic-row--destination
                    }

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _onStationTap(station.nameEn),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: rowBg,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          constraints: const BoxConstraints(minHeight: 58),
                          child: Row(
                            children: [
                              // Metro Rail Column (.schematic-line-col width 40px)
                              SizedBox(
                                width: 40,
                                height: 58,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Top Track Segment (.schematic-line-segment--top)
                                    if (idx > 0)
                                      Positioned(
                                        top: 0,
                                        bottom: 29,
                                        width: 4,
                                        child: Container(
                                          color: isTopSegInRange
                                              ? const Color(0xFF005140)
                                              : Colors.transparent,
                                        ),
                                      ),

                                    // Bottom Track Segment (.schematic-line-segment--bottom)
                                    if (idx < StationData.stations.length - 1)
                                      Positioned(
                                        top: 29,
                                        bottom: 0,
                                        width: 4,
                                        child: Container(
                                          color: isBotSegInRange
                                              ? const Color(0xFF005140)
                                              : Colors.transparent,
                                        ),
                                      ),

                                    // Station Node Circle (.schematic-node)
                                    Container(
                                      width: 14,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isNodeActive
                                            ? const Color(0xFF005140)
                                            : Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFF005140),
                                          width: 3,
                                        ),
                                        boxShadow: isNodeActive
                                            ? const [
                                                BoxShadow(
                                                  color: Color(0x66005140),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Station Names & Badges (.schematic-details)
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: idx < StationData.stations.length - 1
                                        ? const Border(
                                            bottom: BorderSide(
                                              color: Color(0x0D000000),
                                              width: 1,
                                            ),
                                          )
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Names (.schematic-names)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              station.nameEn,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF181C1A),
                                                height: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              station.nameBn,
                                              style: const TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: Color(0xFF3E4945),
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),

                                      // Badges Column (.schematic-badge-col)
                                      if (isOrigin)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0x2610B981), // .schematic-info-badge--here
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'You Are Here',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF059669),
                                            ),
                                          ),
                                        )
                                      else if (isDest)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0x1AEF4444), // .schematic-info-badge--dest
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Destination',
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFFEF4444),
                                            ),
                                          ),
                                        )
                                      else if (previewFare != null && previewFare > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 3,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF005140), // .schematic-badge
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '$previewFare৳',
                                            style: const TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),

              // Bottom Action Button: OK when both selected, Cancel otherwise
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                      RouteSelectionResult(
                        origin: _selectedOrigin,
                        destination: _selectedDestination,
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    hasBoth ? 'OK' : 'Cancel',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: hasBoth
                          ? const Color(0xFF005140) // Primary Green
                          : const Color(0xFFBA1A1A), // Error Red
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
