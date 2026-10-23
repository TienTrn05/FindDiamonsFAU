# Game font candidates

Downloaded and previewed on 2026-10-23. The app's active font was not changed.

The comparison uses the actual TTF files rendered by Flutter, at 24 logical pixels and regular weight. The image is exported at 1.5x resolution. Equal nominal sizes have different apparent heights; Jersey 15 would need a larger size in production.

| Font | Official source | Download | License file |
| --- | --- | --- | --- |
| Monocraft | https://github.com/IdreesInc/Monocraft | https://raw.githubusercontent.com/IdreesInc/Monocraft/main/dist/Monocraft-ttf/Monocraft.ttf | Monocraft-LICENSE.txt |
| Miracode v1.0 | https://github.com/IdreesInc/Miracode | https://github.com/IdreesInc/Miracode/releases/tag/v1.0 | Miracode-LICENSE.txt |
| Jersey 15 | https://github.com/scfried/soft-type-jersey | https://raw.githubusercontent.com/google/fonts/main/ofl/jersey15/Jersey15-Regular.ttf | Jersey15-OFL.txt |

All three downloaded font files are accompanied by their upstream SIL Open Font License 1.1 notices. Keep the applicable notices when bundling fonts with the app.

Visual assessment: Monocraft Regular is the closest of these candidates to the reference image. Miracode smooths the pixel shapes into angular outlines and is an alternative worth testing at small sizes. The exact reference font cannot be established from a screenshot alone.

The files' character maps were checked with Windows GlyphTypeface against `Tọa độ Hạt giống Lịch sử`:

- Monocraft: missing `ọ đ ộ ạ ố ị ử`.
- Miracode: missing `ọ đ ộ ạ ố ị ử`.
- Jersey 15: missing `ọ ộ ạ ố ị ử`.

If adopted across the app, missing Vietnamese glyphs need a fallback font. Letter spacing, regular weight, text sizes and fitting should be checked in the real layouts. Avoid synthetic bold for the reference appearance.
