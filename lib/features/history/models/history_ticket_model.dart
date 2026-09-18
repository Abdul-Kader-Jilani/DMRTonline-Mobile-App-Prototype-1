import '../../../shared/models/ticket_model.dart';

enum HistoryStatus {
  completed,
  expired,
  refunded,
}

class HistoryTicketModel {
  final String id;
  final String origin;
  final String destination;
  final int passengerCount;
  final int totalFare;
  final DateTime purchaseTime;
  final HistoryStatus status;

  const HistoryTicketModel({
    required this.id,
    required this.origin,
    required this.destination,
    required this.passengerCount,
    required this.totalFare,
    required this.purchaseTime,
    required this.status,
  });

  static HistoryStatus _mapStatus(TicketStatus status) {
    switch (status) {
      case TicketStatus.completed:
        return HistoryStatus.completed;
      case TicketStatus.expired:
        return HistoryStatus.expired;
      case TicketStatus.refunded:
        return HistoryStatus.refunded;
      default:
        return HistoryStatus.completed;
    }
  }

  factory HistoryTicketModel.fromTicketModel(TicketModel model) {
    return HistoryTicketModel(
      id: model.id,
      origin: model.origin,
      destination: model.destination,
      passengerCount: model.passengerCount,
      totalFare: model.totalFare,
      purchaseTime: model.purchaseTime,
      status: _mapStatus(model.status),
    );
  }

  static List<HistoryTicketModel> getSampleHistory() {
    return [];
  }
}

