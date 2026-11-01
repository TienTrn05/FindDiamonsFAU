# Home / Find rendering

Home and Find contained several full-scene masks, image opacity layers and
glowing pixel panels. Scaling the entire scene during a tab change required
expensive raster work, even though the catalogs were already cached.

The shared transition now keeps the directional slide and fade without a scale
animation. On native platforms it uses Flutter's `SnapshotWidget` for the brief
transition, releasing the snapshot when both route animations finish. The real
page, fields and scroll position remain mounted. Platform views use permissive
fallback painting, and web/reduced-motion configurations do not take snapshots.

Static backgrounds, the dashboard wordmark and Find footer artwork have separate
repaint boundaries. The wordmark paints its gradient locally instead of using
two `ShaderMask` layers. Panel scenery uses image alpha directly instead of an
extra `Opacity` subtree. Colors, type, button artwork and viewport fitting are
preserved.

Measured using the Dart VM timeline on the connected 1080×2400 Android emulator,
Flutter debug / Impeller OpenGLES, with the normal banner ad present. Each sample
switches History → Home → Find, waits one second per destination and repeats.
Raster time is the duration of `GPURasterizer::Draw`, not end-to-end input latency.

| Screen | Median raster time before, two samples | After, two samples |
| --- | --- | --- |
| History | 14.0 / 16.1 ms | 15.4 / 16.0 ms |
| Home | 32.1 / 26.5 ms | 16.3 / 17.2 ms |
| Find | 28.5 / 39.5 ms | 16.2 / 16.5 ms |

These are observations on one emulator, not a release-device FPS guarantee.
Snapshot creation and emulator scheduling still produce occasional slower
frames. Fullscreen test-ad playback is excluded from the samples.

Validation: analyzer; tab/route directions and rapid navigation; preservation of
form values and server scroll state; dashboard header on three viewport sizes;
Home/Find fitting with ads and enlarged text; small-screen form validation.
