class HelpContent {
  const HelpContent({
    required this.restoreHint,
    required this.languages,
    required this.faqs,
    required this.policySections,
    required this.footer,
  });

  factory HelpContent.fromJson(Map<String, dynamic> json) => HelpContent(
    restoreHint: json['restoreHint'] as String,
    languages: (json['languages'] as List)
        .map(
          (item) => HelpLanguage(
            code: item['code'] as String,
            label: item['label'] as String,
            flag: item['flag'] as String,
          ),
        )
        .toList(growable: false),
    faqs: (json['faqs'] as List)
        .map(
          (item) => HelpFaq(
            id: item['id'] as String,
            question: item['question'] as String,
            before: item['before'] as String,
            illustration: item['illustration'] as String,
            after: item['after'] as String,
          ),
        )
        .toList(growable: false),
    policySections: (json['policySections'] as List)
        .map(
          (item) => HelpPolicySection(
            title: item['title'] as String,
            body: item['body'] as String,
            linkLabel: item['linkLabel'] as String,
            url: item['url'] as String,
          ),
        )
        .toList(growable: false),
    footer: json['footer'] as String,
  );

  final String restoreHint;
  final List<HelpLanguage> languages;
  final List<HelpFaq> faqs;
  final List<HelpPolicySection> policySections;
  final String footer;
}

class HelpLanguage {
  const HelpLanguage({
    required this.code,
    required this.label,
    required this.flag,
  });
  final String code;
  final String label;
  final String flag;
}

class HelpFaq {
  const HelpFaq({
    required this.id,
    required this.question,
    required this.before,
    required this.illustration,
    required this.after,
  });
  final String id;
  final String question;
  final String before;
  final String illustration;
  final String after;
}

class HelpPolicySection {
  const HelpPolicySection({
    required this.title,
    required this.body,
    required this.linkLabel,
    required this.url,
  });
  final String title;
  final String body;
  final String linkLabel;
  final String url;
}
