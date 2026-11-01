import '../../../core/network/app_image_cache.dart';
import '../models/server_catalog.dart';

Future<void> prepareServerImages(ServerCatalog catalog) async {
  final urls = {
    for (final server in catalog.servers)
      if (server.bannerUrl != null) server.bannerUrl.toString(),
  };
  await AppImageCache.shared.preload(urls);
  await Future.wait(urls.map(prepareAppImageFrame));
}
