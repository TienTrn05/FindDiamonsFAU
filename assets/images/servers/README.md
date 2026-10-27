# Server banner GIFs

Public promotional banners downloaded from their respective server listings on 2026-10-23. Artwork belongs to the respective server owners/designers. These are the original animated GIF files, bundled locally so the app does not need to fetch them at runtime.

| File | Server listing | Original image | Dimensions | Frames |
| --- | --- | --- | --- | --- |
| complex.gif | https://minecraftservers.org/server/467177 | https://minecraftservers.org/banners/4671771790734147.gif | 468 × 60 | 109 |
| mystic.gif | https://minecraftservers.org/server/645297 | https://minecraftservers.org/banners/6452971777425602.gif | 468 × 60 | 121 |
| sun.gif | https://minecraftservers.org/server/680119 | https://minecraftservers.org/banners/6801191762383188.gif | 468 × 60 | 216 |
| mchub.gif | https://minecraftservers.org/server/682960 | https://minecraftservers.org/banners/6829601774812969.gif | 468 × 60 | 144 |

`ServerBanner` displays each server's `bannerImage` in the list and in Server Info at the same 468:60 aspect ratio. Flutter's image decoder plays the embedded animation. No gradient or app text is painted over the GIF.

Emerald Valley is a local demo entry without a supplied promotional GIF and retains its static fallback image and demo address. Its website button is disabled until a website is supplied. Bundled player counts and status remain demo snapshots, not live server status.

Connection addresses and websites for the four real servers were checked on 2026-10-23:

- Complex Gaming: https://www.mc-complex.com/ publishes `hub.mc-complex.com` for Java and Bedrock, with Bedrock port 19132. This replaces the demo address; the reference screenshot's `bmc.mc-complex.com` is not the address currently advertised on the official site.
- MysticMC: https://mysticmc.co/ publishes `play.mysticmc.co` for both editions, with Bedrock port 19132.
- SunRealms: https://sunrealms.net/blog/sunrealms-minecraft-server publishes `web.sunrealms.net` for both editions, with Bedrock port 19132.
- McHub: https://minecraftservers.org/server/682960 lists `ms.mchub.com` for both editions and links to https://mchub.com/; the catalog uses the default Bedrock port 19132.

Sharing includes separate Java and Bedrock addresses and ports. Java defaults to port 25565; `javaAddress` and `javaPort` can be set independently in the catalog. The Add Server dialog supplies manual Minecraft steps and does not claim to add a server automatically. Website links open through `url_launcher` in the external application mode: https://pub.dev/documentation/url_launcher/latest/url_launcher/LaunchMode.html.
