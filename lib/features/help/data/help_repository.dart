import '../../../core/data/json_asset_source.dart';
import '../models/help_content.dart';

abstract interface class HelpRepository {
  Future<HelpContent> load();
}

class JsonHelpRepository implements HelpRepository {
  const JsonHelpRepository({this.source = const JsonAssetSource()});
  final JsonAssetSource source;

  @override
  Future<HelpContent> load() async =>
      HelpContent.fromJson(await source.read('assets/data/help/help.json'));
}
