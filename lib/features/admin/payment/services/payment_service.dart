import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  final _db = FirebaseFirestore.instance;

    String _ordinalSuffix(int number) {
    if (number >= 11 && number <= 13) {
      return "th";
    }

    switch (number % 10) {
      case 1:
        return "st";
      case 2:
        return "nd";
      case 3:
        return "rd";
      default:
        return "th";
    }
  }

  String _buildScheduleText(int frequency, int? dueDay) {
    switch (frequency) {
      case 1:
        return "Daily";

      case 2:
        return "Weekly";

      case 3:
        if (dueDay == null) return "Monthly";
        return "Every $dueDay${_ordinalSuffix(dueDay)} of the Month";

      case 4:
        if (dueDay == null) return "Yearly";

        // Convert 1–12 into month names
        const months = [
          "",
          "January",
          "February",
          "March",
          "April",
          "May",
          "June",
          "July",
          "August",
          "September",
          "October",
          "November",
          "December",
        ];

        if (dueDay < 1 || dueDay > 12) return "Yearly";

        return "Every ${months[dueDay]}";

      case 5:
        return "One-time";

      default:
        return "Unknown";
    }
  }

  String _buildFrequencyText(int frequency) {
    switch (frequency) {
      case 1:
        return "Daily";

      case 2:
        return "Weekly";

      case 3:
        return "Monthly";

      case 4:
        return "Yearly";

      case 5:
        return "One-time";

      default:
        return "Unknown";
    }
  }

  Future<List<Map<String, dynamic>>> fetchPaymentCategories() async {
    final querySnapshot =
        await _db.collection('payment_categories').get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();

      // Safely extract values with correct types
      final String id = data['categoryId'] ?? '';
      final String name = data['categoryName'] ?? '';
      final String description = data['categoryDescription'] ?? '';

      final num amount = (data['defaultFee'] ?? 0).toInt();
      final int dueDay = (data['dueDayOfMonth'] ?? 0).toInt();
      final int frequency = (data['frequency'] ?? 0).toInt();

      final bool isEnabled = data['isEnabled'] ?? false;

      // Build readable frequency text
      final String frequencyText = _buildScheduleText(frequency, dueDay);

      return {
        'id': id,
        'name': name,
        'description': description,
        'amount': amount,
        'dueDay': frequencyText,
        'dueTime': dueDay,
        'frequencyId': frequency,
        'frequency': _buildFrequencyText(frequency),
        'isActive': isEnabled,
      };
    }).toList();
  }

  Future<void> deletePaymentCategory(String id) async {
    // Delete document with categoryId == id
    final query = await _db
        .collection('payment_categories')
        .where('categoryId', isEqualTo: id)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.delete();
    }
  }

  Future<void> updatePaymentCategory(
      String id, Map<String, dynamic> updatedData) async {
    final query = await _db
        .collection('payment_categories')
        .where('categoryId', isEqualTo: id)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      await query.docs.first.reference.update(updatedData);
    }
  }
}
