# PushWake V3 – Installation

1. Öffne dein GitHub-Repository `ati126/PushWake`.
2. Ersetze `PushWake/HomeView.swift`, `PushWake/CameraTracker.swift` und `PushWake.xcodeproj/project.pbxproj` durch die Versionen aus diesem Paket.
3. Lade zusätzlich den gesamten neuen Ordner `PushWake/Assets.xcassets` mit seinen `Contents.json`-Dateien und `PushWakeIcon.png` hoch (inklusive Unterordner `AppIcon.appiconset`).
4. Committe die Dateien und prüfe GitHub Actions.
5. Lade die neue `PushWake-unsigned.ipa` aus dem grünen Build und installiere sie mit Sideloadly.

## Änderung
- Kamera standardmäßig vorne, in der Vorschau gespiegelt, Vision mit `.leftMirrored` ausgerichtet.
- Klare, feste und bildschirmabhängige Höhe der Kameravorschau (kein versehentliches Zusammenfallen).
- Gesamte Trainingsansicht scrollbar; Button bleibt erreichbar.
- App-Icon (1024 × 1024 PNG) in Xcode-Asset-Katalog integriert.

## Einschränkungen
Build und Verhalten müssen noch auf iOS 26 getestet werden. Pose-Erkennung verlangt weiterhin gut sichtbare Gelenkpunkte; Kamera allein garantiert keine Erkennung. Der bereits beobachtete AlarmKit-Laufzeitfehler ist nicht Bestandteil dieses UI/Kamera-Updates.
