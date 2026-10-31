# Help screen

Help uses the shared cave, cyan, steel and pixel panel system from Dashboard and
Find Ore. Its fixed banner remains visible as the support content scrolls.

- Restore purchases uses the existing billing callback and request guard.
- View tutorial opens the existing review flow and returns to Help.
- Change language shows the current flag and an inline list with radio states.
  The existing locale controller persists the selected language.
- FAQ expands into a search field and four accordion questions. Search matches
  translated questions and answers. Empty results include a clear action.
- Privacy Policy opens the existing three-section content in a stepped dialog,
  with a scrolling body and a fixed OK action. Policy text and links retain the
  existing preview content from the Help JSON data.
- Ad privacy choices retain the existing consent-service integration.

New Help copy is translated into the eight supported languages. Pixel card
emblems are drawn in Flutter; the banner is a local raster image.

## Banner provenance

Saved asset: `assets/images/help_cave.png`.

Generated with the built-in `imagegen` tool and copied into the repository. The
user's screenshot was visual guidance for the design.

Final prompt:

> Use case: stylized-concept. Asset type: background illustration for an existing mobile mining app Help screen, no UI. Create a wide landscape 3:2 illustration of a beautiful block-built voxel mining cave. Dark midnight navy stone blocks, faceted glowing cyan diamond crystal clusters on the far left foreground and upper right wall, a small blocky friendly miner with brown hair teal shirt carrying a warm amber lantern at the far right edge. Inspired by polished pixel-art voxel sandbox games. Keep the middle 60 percent dark and uncluttered for a heading overlaid in code. Perspective ground across the bottom with a path into a deep cavern. Rich pixel textures, moody cyan lighting, small warm amber highlights. The illustration fills the entire frame, no black border, no text, no letters, no phone frame, no buttons, no watermark. Composition matches a game help page header; the miner is on the far right, cyan crystal clusters frame the left and upper right, center is usable dark negative space. This is a brand-new artwork asset, not a UI screenshot.

## Previews

```powershell
$env:CAPTURE_PREVIEWS = 'true'
flutter test test/navigation_test.dart --plain-name 'Help opens FAQ'
```

The four reference states are exported to `output/previews/33-help-overview.png`,
`34-help-languages.png`, `35-help-faq.png` and `36-help-policy.png`.
