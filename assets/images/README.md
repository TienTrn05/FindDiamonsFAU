# Illustration asset

`adventurer.png` is an original illustration generated with the built-in imagegen tool for this Flutter onboarding. It approximates the visual subject of the supplied reference; it is not a crop of that reference. Saved project path: `assets/images/adventurer.png`.

Final prompt:

> Use case: stylized-concept. Asset type: mobile app paywall hero background, portrait 1024x1536. Primary request: vibrant polished voxel game illustration of a square block adventurer with brown block hair, green eyes, teal short sleeved shirt, gray trousers, holding a diamond turquoise and white pixel sword diagonally toward upper left. Low angle dramatic close-up, character large centered, head near top, torso fills frame, grassy cube hills and block trees under vivid clear blue sky, warm sunshine from left, appealing Minecraft-like voxel render. Keep important character in top two thirds; lower third grassy foreground will be covered by a UI panel. No text, no UI, no logos, no watermark. This is an in-app raster illustration only.

Ore art is drawn by `lib/common/widgets/ore_art.dart`. Tutorial illustrations are Flutter widgets in `lib/features/onboarding/presentation/tutorial_pages.dart`. Skin characters and navigation icons are native Flutter canvas graphics in `lib/common/widgets/`, using `core/theme/character_palette.dart`. All assets are bundled locally.

## Route backgrounds and map cover

The following assets were generated using the **built-in imagegen tool** and copied into the project. The reference screenshots were visual guidance, not cropped assets.

Saved path: `assets/images/block_landscape.png`.

Final prompt:

> Use case: stylized-concept. Generate one polished portrait game environment background bitmap asset for a mobile app, 1024x1536 composition. Voxel block world reminiscent of classic block building games, viewed from a grassy hill toward tall stepped stone cliffs and terraced green hills with square-leaf trees, a small bright blue lake at the lower right, and pale blue sky with rectangular white clouds at the upper third. Crisp low-resolution pixel texture on all cubic surfaces, ambient daylight, recognizable block geometry, calm green and sky blue palette. The landscape fills edge to edge. No characters, no words, no letters, no text, no UI, no watermarks, no borders. It will be used behind a mobile history list and character selection grid. Match the supplied app references' block terrain visual mood, not photorealistic, not rounded 3D toy style.

Saved path: `assets/images/warehouse.png`.

Final prompt:

> Use case: stylized-concept. Asset type: square mobile game map cover thumbnail, 1024x1024. A moody abandoned warehouse interior entirely built of textured cubic voxel blocks, reminiscent of a classic block-building game. Long low perspective corridor through dark stone brick floors, block brick walls and thick square pillars, stacked wooden cubic crates, metal grate details, dim cool white overhead square lights, far doorway disappearing in shadow. Slightly desaturated gray palette with muted brown crates. Atmospheric eerie exploration but no violence and no creatures. Crisp pixel textures and sharp block geometry, recognizable game screenshot appearance. Composition must remain readable when shown as a small cropped portrait thumbnail. No people, no characters, no letters, no text, no UI, no title, no border, no watermark.

Help banner: `assets/images/help_cave.png`, generated with the built-in imagegen tool. See [the complete prompt and usage](../../docs/help-design.md#banner-provenance).
