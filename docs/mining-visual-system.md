# Shared mining visual system

`AppColors` owns the application palette. `MiningStyle` aliases those colors
instead of maintaining separate Dashboard/Find values. Cyan is the primary
action, gold identifies Pro, slate is secondary, and text stays white or muted
blue on cave surfaces. Light stone forms keep dark ink for readability.

`MiningStyle.oreAccent` maps ores to their mineral colors. History uses these
accents, while server rank borders use the same six-color sequence.
`MiningNeonPanel` supplies shared dark surfaces, stepped borders and glow.

`GameBackButton` is the shared 48-pixel back control. It is used by the ore
picker, GameHeader (including map details), Help, ore results and server details.
Callers retain navigation ownership; closing a modal or paywall remains a Close
action rather than a Back action.

The ore picker fits portrait and landscape, keeps carousel swipe/arrows/dots,
and commits selection only with Continue. Back cancels selection. History
retains persistent storage and delete/open actions. The server profile editor
is available through the compact avatar in its header; live status and banner
loading remain intact.

Generate review images using test-only memory records:

```powershell
$env:CAPTURE_PREVIEWS = 'true'
flutter test test/navigation_test.dart --name 'Dashboard opens features|reference History and Servers'
```

Previews: `32-ore-picker.png`, `43-history-neon.png`, `44-servers-neon.png` under
`output/previews`. The preview fixtures never seed production History.
