class CompanyPolicy {
  final int id;
  final String title;
  final String category;
  final String version;
  final String summary;
  final String content;
  final String updatedAt;
  final String updatedBy;

  CompanyPolicy({
    required this.id,
    required this.title,
    required this.category,
    required this.version,
    required this.summary,
    required this.content,
    required this.updatedAt,
    required this.updatedBy,
  });

  factory CompanyPolicy.fromJson(Map<String, dynamic> json) {
    return CompanyPolicy(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      title: json['title']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      version: json['version']?.toString() ?? 'v1.0',
      summary: json['summary']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      updatedAt: json['updatedAt']?.toString() ?? '',
      updatedBy: json['updatedBy']?.toString() ?? 'LogiLead HR Operations',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id > 0) 'id': id,
      'title': title,
      'category': category,
      'version': version,
      'summary': summary,
      'content': content,
      'updatedAt': updatedAt,
      'updatedBy': updatedBy,
    };
  }
}
