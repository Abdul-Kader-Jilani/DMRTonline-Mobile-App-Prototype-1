import 'package:intl/intl.dart';

/// Supported status for ticket across entire lifecycle
enum TicketStatus {
  available,
  riding,
  locked,
  completed,
  expired,
  refunded,
}

/// 1:1 Unified Ticket Model matching Web Prototype state structure
class TicketModel {
  final String id;
  final String origin;
  final String destination;
  final int passengerCount;
  final int farePerPerson;
  final int totalFare;
  final TicketStatus status;
  final DateTime purchaseTime;
  final DateTime? completeTime;
  final String paymentMethod;
  final bool exitQrActive;
  final DateTime? qrExpiryTime;
  final DateTime? exitQrExpiryTime;

  const TicketModel({
    required this.id,
    required this.origin,
    required this.destination,
    required this.passengerCount,
    required this.farePerPerson,
    required this.totalFare,
    required this.status,
    required this.purchaseTime,
    this.completeTime,
    this.paymentMethod = 'Mobile Finance (bKash/Nagad)',
    this.exitQrActive = false,
    this.qrExpiryTime,
    this.exitQrExpiryTime,
  });

  DateTime get expiryTime => purchaseTime.add(const Duration(hours: 24));

  String get formattedShortDate {
    return DateFormat('d MMM').format(purchaseTime);
  }

  String get formattedShortExpiry {
    return DateFormat('d MMM').format(expiryTime);
  }

  String get formattedFullPurchaseTime {
    return DateFormat('MMM d, yyyy, hh:mm a').format(purchaseTime);
  }

  String get formattedFullExpiryTime {
    return DateFormat('MMM d, yyyy, hh:mm a').format(expiryTime);
  }

  int get qrDurationSeconds => 60 + (passengerCount - 1) * 20;

  TicketModel copyWith({
    String? id,
    String? origin,
    String? destination,
    int? passengerCount,
    int? farePerPerson,
    int? totalFare,
    TicketStatus? status,
    DateTime? purchaseTime,
    DateTime? completeTime,
    String? paymentMethod,
    bool? exitQrActive,
    DateTime? qrExpiryTime,
    DateTime? exitQrExpiryTime,
  }) {
    return TicketModel(
      id: id ?? this.id,
      origin: origin ?? this.origin,
      destination: destination ?? this.destination,
      passengerCount: passengerCount ?? this.passengerCount,
      farePerPerson: farePerPerson ?? this.farePerPerson,
      totalFare: totalFare ?? this.totalFare,
      status: status ?? this.status,
      purchaseTime: purchaseTime ?? this.purchaseTime,
      completeTime: completeTime ?? this.completeTime,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      exitQrActive: exitQrActive ?? this.exitQrActive,
      qrExpiryTime: qrExpiryTime ?? this.qrExpiryTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'origin': origin,
      'destination': destination,
      'passengerCount': passengerCount,
      'farePerPerson': farePerPerson,
      'totalFare': totalFare,
      'status': status.name,
      'purchaseTime': purchaseTime.toIso8601String(),
      'completeTime': completeTime?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'exitQrActive': exitQrActive,
      'qrExpiryTime': qrExpiryTime?.toIso8601String(),
      'exitQrExpiryTime': exitQrExpiryTime?.toIso8601String(),
    };
  }

  factory TicketModel.fromJson(Map<String, dynamic> json) {
    TicketStatus parsedStatus;
    try {
      parsedStatus = TicketStatus.values.byName(json['status'] as String);
    } catch (_) {
      parsedStatus = TicketStatus.available;
    }

    return TicketModel(
      id: json['id'] as String? ?? 'TKT-0000',
      origin: json['origin'] as String? ?? 'Uttara North',
      destination: json['destination'] as String? ?? 'Motijheel',
      passengerCount: json['passengerCount'] as int? ?? 1,
      farePerPerson: json['farePerPerson'] as int? ?? 60,
      totalFare: json['totalFare'] as int? ?? 60,
      status: parsedStatus,
      purchaseTime: json['purchaseTime'] != null
          ? DateTime.parse(json['purchaseTime'] as String)
          : DateTime.now(),
      completeTime: json['completeTime'] != null
          ? DateTime.parse(json['completeTime'] as String)
          : null,
      paymentMethod: json['paymentMethod'] as String? ?? 'Mobile Finance (bKash/Nagad)',
      exitQrActive: json['exitQrActive'] as bool? ?? false,
      qrExpiryTime: json['qrExpiryTime'] != null
          ? DateTime.parse(json['qrExpiryTime'] as String)
          : null,
      exitQrExpiryTime: json['exitQrExpiryTime'] != null
          ? DateTime.parse(json['exitQrExpiryTime'] as String)
          : null,
    );
  }

  static List<TicketModel> getInitialTickets() {
    return [];
  }

  static List<TicketModel> getInitialHistory() {
    return [];
  }
}
