import '../../../core/models/search_record.dart';

class HistoryData {
  const HistoryData({required this.emptyMessage, required this.searches});
  factory HistoryData.fromJson(Map<String, dynamic> json) => HistoryData(
    emptyMessage: json['emptyMessage'] as String,
    searches: (json['searches'] as List)
        .map((e) => SearchRecord.fromJson(e as Map<String, dynamic>))
        .toList(growable: false),
  );
  final String emptyMessage;
  final List<SearchRecord> searches;
}
