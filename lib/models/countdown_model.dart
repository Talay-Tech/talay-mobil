/// Countdown Model
///
/// Zamanlayıcı ayarlarını temsil eden model.
/// Admin panel üzerinden yönetilen geri sayım bilgilerini içerir.

class CountdownSettings {
  final String id;
  final bool isActive;
  final String mainTitle;
  final String? subTitle;
  final String? description;
  final DateTime targetDate;
  final String expiredMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CountdownSettings({
    required this.id,
    required this.isActive,
    required this.mainTitle,
    this.subTitle,
    this.description,
    required this.targetDate,
    required this.expiredMessage,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CountdownSettings.fromJson(Map<String, dynamic> json) {
    return CountdownSettings(
      id: json['id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      mainTitle: json['main_title'] as String,
      subTitle: json['sub_title'] as String?,
      description: json['description'] as String?,
      targetDate: DateTime.parse(json['target_date'] as String),
      expiredMessage: json['expired_message'] as String? ?? 'Süre doldu',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_active': isActive,
      'main_title': mainTitle,
      'sub_title': subTitle,
      'description': description,
      'target_date': targetDate.toIso8601String(),
      'expired_message': expiredMessage,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Hedef tarihe kalan süreyi hesapla
  RemainingTime getRemainingTime() {
    final now = DateTime.now();
    if (now.isAfter(targetDate)) {
      return RemainingTime.expired();
    }

    final difference = targetDate.difference(now);

    // Toplam günleri yıl, ay, gün olarak parçala
    int totalDays = difference.inDays;
    int years = totalDays ~/ 365;
    int remainingDaysAfterYears = totalDays % 365;
    int months = remainingDaysAfterYears ~/ 30;
    int days = remainingDaysAfterYears % 30;
    int hours = difference.inHours % 24;

    return RemainingTime(
      years: years,
      months: months,
      days: days,
      hours: hours,
      isExpired: false,
    );
  }
}

/// Kalan süre bilgisi
class RemainingTime {
  final int years;
  final int months;
  final int days;
  final int hours;
  final bool isExpired;

  const RemainingTime({
    required this.years,
    required this.months,
    required this.days,
    required this.hours,
    required this.isExpired,
  });

  factory RemainingTime.expired() {
    return const RemainingTime(
      years: 0,
      months: 0,
      days: 0,
      hours: 0,
      isExpired: true,
    );
  }

  @override
  String toString() {
    if (isExpired) return 'Expired';
    return '$years yıl, $months ay, $days gün, $hours saat';
  }
}
