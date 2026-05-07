extension StringExtensions on String {
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  bool get isValidPassword {
    return length >= 6;
  }

  bool get isValidDoctorCode {
    return length == 6 && RegExp(r'^[A-Z0-9]{6}$').hasMatch(this);
  }

  bool get isNotEmpty {
    return trim().isNotEmpty;
  }

  String get capitalizeFirst {
    return isEmpty ? '' : '${this[0].toUpperCase()}${substring(1)}';
  }

  String get toTitleCase {
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).join(' ');
  }

  String get removeAllWhitespace {
    return replaceAll(RegExp(r'\s+'), '');
  }
}

extension IntExtensions on int {
  String get toPercentageString {
    return '$this%';
  }

  bool get isEven => this % 2 == 0;
  bool get isOdd => this % 2 != 0;

  String get formatAsCurrency {
    return '\$$toString()';
  }
}

extension DoubleExtensions on double {
  String get toPercentageString {
    return toStringAsFixed(1) + '%';
  }

  String get toPercentageStringNoDecimal {
    return toStringAsFixed(0) + '%';
  }

  bool get isEqualZero => this == 0.0;
  bool get isGreaterThanZero => this > 0.0;
  bool get isLessThanZero => this < 0.0;

  String get formatAsCurrency {
    return '\$${toStringAsFixed(2)}';
  }
}

extension DateTimeExtensions on DateTime {
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  String get formattedDate {
    return '$day/$month/$year';
  }

  String get formattedTime {
    return '$hour:${minute.toString().padLeft(2, '0')}';
  }

  String get formattedDateTime {
    return '$day/$month/$year $hour:${minute.toString().padLeft(2, '0')}';
  }

  bool get isPast {
    return isBefore(DateTime.now());
  }

  bool get isFuture {
    return isAfter(DateTime.now());
  }

  int get getDaysDifference {
    final now = DateTime.now();
    return difference(DateTime(now.year, now.month, now.day)).inDays.abs();
  }
}

extension ListExtensions<T> on List<T> {
  bool get isNullOrEmpty => isEmpty;

  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  List<T> removeDuplicates() {
    return toSet().toList();
  }
}

extension MapExtensions<K, V> on Map<K, V> {
  bool get isNullOrEmpty => isEmpty;

  bool containsKeyICase(String key) {
    return keys.any((k) => k.toString().toLowerCase() == key.toLowerCase());
  }
}
