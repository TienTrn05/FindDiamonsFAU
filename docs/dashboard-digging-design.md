# Dashboard and digging

The app now opens `/dashboard` after onboarding. Home, Find, History, Skins,
Servers and Maps remain independent tabs; switching tabs preserves the Find
form and selected ore. The Find back button and system Back return to Home.
Existing named routes, including `/find`, still open their respective tabs.

Dashboard links open the existing features. Settings opens Help, where language
and app information live. The Pro card opens the existing paywall and disappears
for verified Pro users.

Home and Find keep the free layout for both entitlements. Pro removes the
purchase controls and the real ad view while reserving their space, so cards,
fields and Help stay at the same size and position. Startup measures and caches
the SDK's adaptive banner height before opening the app; ad loading, failure or
Pro activation does not resize the content area. Measuring a Pro layout does
not request an ad.
Find uses one continuous cave background across the screen, including the
reserved banner space when no ad is displayed. The separate landscape strip
below its actions is removed; the content layout stays fixed.

Find groups player coordinates, world seed and Java version into a world
information panel. Change opens `/find/ores` with the ores supported by the
selected version. Swipe, arrows or pagination dots preview an ore. Continue
commits the selection; Back cancels it. Searching still validates inputs, uses
the existing repository, displays the digging animation and saves results to
History.

## Shared visual system

- `MiningStyle`: aliases the shared `AppColors` palette: saturated cyan actions,
  dark cave surfaces, stone forms with dark ink, steel secondary actions and
  gold Pro accents. See [the shared visual system](mining-visual-system.md).
- `MiningBackground`, `MiningPanel`, `MiningButton`, `PixelBorder`: shared
  backgrounds, stepped corners, borders, spacing and action states. The opt-in
  `vivid` finish adds pixel texture, bevels and localized highlights; `scenery`
  adds cave artwork to the main Dashboard cards.
- `GameBottomNavigation`: six destinations with consistent selected/unselected
  colors and accessible selected states.
- `AppTextStyles` and the existing offline translation catalogs supply typography
  and all new copy in the eight supported languages.

Dashboard and Find have no vertical scroll view. `MiningViewport` fits the complete
composition into the actual space left after safe areas, keyboard, banner ads and
navigation. Short screens use compact spacing and omit supporting descriptions
and decorative scenery before scaling; landscape uses two columns.
Validation messages are included in the height budget. Tests cover 320x568, 390x844,
844x390, tablet, 1.5x text and loaded adaptive banners at 50/90 logical pixels,
including switching to Pro while an ad is displayed.

Titles and labels use bundled Monocraft Bold with additional stroke emphasis;
supporting copy uses Roboto. Dashboard's wordmark uses Pixelify Sans Bold with
dark extrusion, silver/cyan shading, a diamond pickaxe and native pixel gems.
It sits on the left, with a sunlit cave opening and waterfall on the right and
a functional Settings control in the corner, matching the latest reference.
The artwork asset and image generation prompt are recorded in
[`dashboard-artwork.md`](dashboard-artwork.md).

Primary actions use cyan, Pro actions gold, and secondary actions steel gray.
Action panels add luminous beveled borders, pixel highlights and corner glints.
The seed icon is green; diamond blocks and the faceted Pro icon use bright cyan.
`AppPageTransition` supplies a 380 ms directional transition: a short horizontal
glide, staggered opacity and subtle scale give the incoming page depth while the
old page recedes. The incoming scene always paints above the outgoing scene in
both directions. Routes reverse on Back with gentle parallax on the underlying
page. `AppTabTransition` keeps each tab mounted and queues the
last tap during an active slide to prevent jumps. System Reduce Motion disables
the movement.

## Preview

Run the following in PowerShell to refresh the three design previews:

```powershell
$env:CAPTURE_PREVIEWS = 'true'
flutter test test/navigation_test.dart --plain-name 'Dashboard opens features'
```

Images: `output/previews/30-dashboard.png`, `31-find-redesign.png`,
`32-ore-picker.png`.

For previews with a loaded SDK banner (mocked in the widget test):

```powershell
$env:CAPTURE_PREVIEWS = 'true'
flutter test test/navigation_test.dart --plain-name 'mining screens never scroll'
```

Images: `output/previews/37-dashboard-ad.png`, `38-digging-ad.png`.

To render a motion preview (Pillow is required by the encoder):

```powershell
$env:CAPTURE_MOTION = 'true'
flutter test test/navigation_test.dart --plain-name 'capture scene motion preview'
python tool/render_transition_preview.py
```

Animation: `output/previews/41-scene-transition.gif`. Captured frames are stored
in `.dart_tool/scene-motion`; the preview demonstrates both navigation directions.
