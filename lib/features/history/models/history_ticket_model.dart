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
    return [
      HistoryTicketModel(
        id: 'TKT-1001',
        origin: 'Uttara North',
        destination: 'Motijheel',
        passengerCount: 1,
        totalFare: 100,
        purchaseTime: DateTime(2026, 9, 11, 9, 30),
        status: HistoryStatus.completed,
      ),
      HistoryTicketModel(
        id: 'TKT-1002',
        origin: 'Farmgate',
        destination: 'Shahbagh',
        passengerCount: 2,
        totalFare: 40,
        purchaseTime: DateTime(2026, 9, 8, 17, 45),
        status: HistoryStatus.completed,
      ),
      HistoryTicketModel(
        id: 'TKT-1003',
        origin: 'Pallabi',
        destination: 'Agargaon',
        passengerCount: 1,
        totalFare: 40,
        purchaseTime: DateTime(2026, 9, 2, 8, 15),
        status: HistoryStatus.expired,
      ),
      HistoryTicketModel(
        id: 'TKT-1004',
        origin: 'Mirpur 10',
        destination: 'Secretariat',
        passengerCount: 1,
        totalFare: 60,
        purchaseTime: DateTime(2026, 8, 28, 11, 20),
        status: HistoryStatus.refunded,
      ),
    ];
  }
}

