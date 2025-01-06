class Tracker {
  final int id;
  final String name;
  final String cronExpr;
  final String compareMode;
  final String websiteUrl;
  final String selector;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tracker({
    required this.id,
    required this.name,
    required this.cronExpr,
    required this.compareMode,
    required this.websiteUrl,
    required this.selector,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tracker.fromJson(Map<String, dynamic> json) {
    return Tracker(
      id: json['id'],
      name: json['name'],
      cronExpr: json['cronExpr'],
      compareMode: json['compareMode'],
      websiteUrl: json['websiteUrl'],
      selector: json['selector'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
