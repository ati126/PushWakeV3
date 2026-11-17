# PushWake V5 – Pose Overlay

## Basis
V4 AlarmKit Diagnose. `AlarmController.swift`, `PushWakeApp.swift`, `.github/workflows/build.yml`, UserDefaults keys and all app assets are unchanged. Only marketing version updated in `.pbxproj`.

## Replace
- `PushWake/PushupCounter.swift` – state machine, smoothing, pose quality, centralized thresholds.
- `PushWake/CameraTracker.swift` – portrait front camera, 2D Vision detection, skeleton preview.
- `PushWake/HomeView.swift` – responsive workout screen + ring + completion trigger (home and alarm config unchanged).
- `PushWake.xcodeproj/project.pbxproj` – includes the two new resources.

## New
- `PushWake/Celebration.swift` – confetti, sound and success overlay.
- `PushWake/success.wav` – original short success chime. Included in Copy Bundle Resources.

## Privacy keys
- `NSCameraUsageDescription` remains present.
- `NSAlarmKitUsageDescription` remains present.
- No microphone permission needed.

## Tests
1. Build through GitHub Actions/Xcode 26.3, resolve any compile errors before sideloading. Xcode is not installed in this environment and successful iOS compilation is NOT verified.
2. Install with Sideloadly; grant camera permission.
3. Stand side-on with full body visible. Check green joints track motion and 1 rep occurs after top -> bottom -> top.
4. Try occlusion/turning away: counter should stop instead of hallucinating reps.
5. Reach a small goal (e.g. 1-3): ring, chime, confetti, automatic return.
6. Test system alarm separately; V4 AlarmKit diagnostic remains unresolved and is unchanged.

## Tuning in `PoseTuning` (`PushupCounter.swift`)
- `confidence`: lower slightly to tolerate weak joints, at cost of false detections.
- `downAngle`, `upAngle`: adjust only if real camera tests suggest valid reps not registering.
- `minimumStableFrames`, `minimumRepInterval`: adjust to avoid double counts.
- `smoothing`: increase for quicker but noisier joints.
- `maximumTorsoTiltDegrees`: depends on camera perspective; use side view.
- `analysisInterval`: lower = more frequent Vision requests / heavier CPU.

## Orientation caveat
Output buffers are rotated to portrait with `videoRotationAngle=90` when supported and passed to Vision with `.up`. Front preview is mirrored once; overlay mirrors X once while mapping normalized bottom-left Vision coordinates to top-left display and accounting for aspectFill crop. Verify on the physical device; if landscape coordinates appear rotated, inspect device-supported rotation angle and EXIF orientation before changing transforms. The overlay deliberately omits under-confident links and displays low-confidence points in gray.

## Audio
`success.wav` is included and is a self-generated short three-tone signal. The app stops the tracked AlarmKit alarm via the pre-existing `finishWorkout()` before playing a short `AVAudioPlayer` cue with `AVAudioSession.Category.playback` + `mixWithOthers`. This does not replace or change iOS system-alarm sounds.

## Sources
- https://developer.apple.com/videos/play/wwdc2020/10653/
- https://developer.apple.com/documentation/vision/detecting-human-body-poses-in-images
- https://developer.apple.com/documentation/vision/vndetecthumanbodyposerequest
- https://developer.apple.com/documentation/vision/vndetecthumanbodypose3drequest
- https://developer.apple.com/documentation/avfoundation/avcaptureconnection/isvideomirrored
- https://developer.apple.com/documentation/avfoundation/avcapturevideodataoutput/alwaysdiscardslatevideoframes
- https://developer.apple.com/documentation/quartzcore/caemitterlayer
- https://developer.apple.com/design/human-interface-guidelines/typography
