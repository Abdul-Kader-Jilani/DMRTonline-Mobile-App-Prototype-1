class UserProfileModel {
  final String id;
  final String authId;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String gender; // 'male', 'female', 'prefer_not_to_say', ''
  final String dob; // 'YYYY-MM-DD'
  final String? avatarUrl;

  const UserProfileModel({
    this.id = '',
    this.authId = '',
    this.fullName = '',
    this.email = '',
    this.phoneNumber = '',
    this.gender = 'male',
    this.dob = '1995-05-15',
    this.avatarUrl,
  });

  UserProfileModel copyWith({
    String? id,
    String? authId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? gender,
    String? dob,
    String? avatarUrl,
    bool clearAvatar = false,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      authId: authId ?? this.authId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      gender: gender ?? this.gender,
      dob: dob ?? this.dob,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
    );
  }

  String get genderDisplay {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'prefer_not_to_say':
        return 'Prefer not to say';
      default:
        return '';
    }
  }

  String get dobDisplay {
    if (dob.isEmpty) return '';
    try {
      final parts = dob.split('-');
      if (parts.length == 3) {
        final year = int.parse(parts[0]);
        final month = int.parse(parts[1]);
        final day = int.parse(parts[2]);
        const months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return '${months[month - 1]} ${day.toString().padLeft(2, '0')}, $year';
      }
    } catch (_) {}
    return dob;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authId': authId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'gender': gender,
      'dob': dob,
      'avatarUrl': avatarUrl,
    };
  }

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String? ?? json['passenger_id'] as String? ?? '',
      authId: json['authId'] as String? ?? json['auth_id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? json['name'] as String? ?? 'Dhaka Transit User',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? json['phone_number'] as String? ?? '',
      gender: json['gender'] as String? ?? 'male',
      dob: json['dob'] as String? ?? '1995-05-15',
      avatarUrl: json['avatarUrl'] as String? ?? json['avatar_url'] as String?,
    );
  }
}
