class StationModel {
  final int index;
  final String nameEn;
  final String nameBn;
  final String code;

  const StationModel({
    required this.index,
    required this.nameEn,
    required this.nameBn,
    required this.code,
  });
}

/// Official Dhaka Metro MRT Line 6 Stations (16 Stations)
class StationData {
  static const List<StationModel> stations = [
    StationModel(index: 0, nameEn: 'Uttara North', nameBn: 'উত্তরা উত্তর', code: 'UN'),
    StationModel(index: 1, nameEn: 'Uttara Center', nameBn: 'উত্তরা সেন্টার', code: 'UC'),
    StationModel(index: 2, nameEn: 'Uttara South', nameBn: 'উত্তরা দক্ষিণ', code: 'US'),
    StationModel(index: 3, nameEn: 'Pallabi', nameBn: 'পল্লবী', code: 'PAL'),
    StationModel(index: 4, nameEn: 'Mirpur 11', nameBn: 'মিরপুর ১১', code: 'M11'),
    StationModel(index: 5, nameEn: 'Mirpur 10', nameBn: 'মিরপুর ১০', code: 'M10'),
    StationModel(index: 6, nameEn: 'Kazipara', nameBn: 'কাজীপাড়া', code: 'KP'),
    StationModel(index: 7, nameEn: 'Shewrapara', nameBn: 'শেওড়াপাড়া', code: 'SP'),
    StationModel(index: 8, nameEn: 'Agargaon', nameBn: 'আগারগাঁও', code: 'AG'),
    StationModel(index: 9, nameEn: 'Bijoy Sarani', nameBn: 'বিজয় সরণি', code: 'BS'),
    StationModel(index: 10, nameEn: 'Farmgate', nameBn: 'ফার্মগেট', code: 'FG'),
    StationModel(index: 11, nameEn: 'Kawran Bazar', nameBn: 'কারওয়ান বাজার', code: 'KB'),
    StationModel(index: 12, nameEn: 'Shahbagh', nameBn: 'শাহবাগ', code: 'SB'),
    StationModel(index: 13, nameEn: 'Dhaka University', nameBn: 'ঢাকা বিশ্ববিদ্যালয়', code: 'DU'),
    StationModel(index: 14, nameEn: 'Secretariat', nameBn: 'বাংলাদেশ সচিবালয়', code: 'SEC'),
    StationModel(index: 15, nameEn: 'Motijheel', nameBn: 'মতিঝিল', code: 'MJ'),
  ];

  static StationModel? getByNameEn(String? name) {
    if (name == null || name.isEmpty) return null;
    final normalized = name.trim().toLowerCase();
    try {
      return stations.firstWhere((s) {
        final sNorm = s.nameEn.toLowerCase();
        if (sNorm == normalized) return true;
        if ((normalized == 'kawran bazar' || normalized == 'karwan bazar') &&
            (sNorm == 'kawran bazar' || sNorm == 'karwan bazar')) {
          return true;
        }
        return false;
      });
    } catch (_) {
      return null;
    }
  }

  /// 1:1 Pure calculation matching calculateFare() from Web Prototype/index.html
  static int calculateFare(String? origin, String? destination) {
    if (origin == null || destination == null || origin.isEmpty || destination.isEmpty) {
      return 0;
    }
    final s1 = getByNameEn(origin);
    final s2 = getByNameEn(destination);
    if (s1 == null || s2 == null) return 0;
    final gap = (s1.index - s2.index).abs();
    if (gap == 0) return 0;
    if (gap <= 2) return 20;
    if (gap <= 5) return 40;
    if (gap <= 11) return 60;
    return 100;
  }
}
