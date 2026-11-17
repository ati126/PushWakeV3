# PushWake (iOS 26+) – kostenloser Liegestütze-Wecker

## Funktionsumfang
- Weckerzeit und Wiederholungsziel (1–30) festlegen
- Einmaligen Systemwecker über Apples AlarmKit planen (iOS 26+)
- Mit zweiter Alarm-Schaltfläche „Training“ die App öffnen
- Lokale Kamerapose-Erkennung über Vision; zählt Ellenbogen-Winkel-Zyklen (runter/hoch)
- Trainingsmodus, Fortschritt, Reset, sicherer Abbruch
- Keine APIs, kein Konto, kein Upload von Videodaten

## Voraussetzung
- Mac mit einer Xcode-Version, die das iOS-26-SDK enthält; iPhone mit iOS 26 oder neuer
- Kostenloser Apple Account genügt für den Test auf dem eigenen iPhone
- Kein kostenpflichtiges Developer-Abo nötig, aber kostenlose Signierung läuft regulär nach 7 Tagen ab

## Installation
1. `PushWake.xcodeproj` auf einem Mac mit Xcode öffnen.
2. iPhone per Kabel verbinden; am Gerät diesem Computer vertrauen, ggf. Entwicklermodus aktivieren.
3. In Xcode Projekt `PushWake` > Target `PushWake` > `Signing & Capabilities`: `Automatically manage signing` aktivieren und das persönliche Apple-Team auswählen.
4. Bundle Identifier bei Bedarf eindeutig ändern (z.B. `de.deinname.pushwake`).
5. iPhone als Ziel wählen und mit ▶︎ Build & Run installieren.
6. Beim ersten Alarm die AlarmKit-Erlaubnis erteilen; beim Training die Kamera erlauben.
7. ZUERST Kamera testen, dann einen Alarm für 2 Minuten später stellen und die Anzeige inklusive Sperrbildschirm testen.

## Wichtige Einschränkungen
- iOS bietet immer Systemoptionen zum Anhalten eines Weckers. Wir dürfen nicht versprechen, dass nur Liegestütze ihn stoppen können.
- Eine App kann eine Kamera nicht still im Hintergrund starten. Der Nutzer öffnet die App über die Schaltfläche "Training".
- Dies ist eine ungetestete, lokal erzeugte Xcode-Quellcodeversion: Auf diesem System sind Xcode und ein iPhone nicht verfügbar. Compiler-, Signierungs- und Laufzeittests müssen auf einem Mac erfolgen.
- Der Zähler basiert auf 2D-Ellenbogen-Winkeln; er kann bei verdeckten Armen oder schwieriger Perspektive Fehler machen. Er ist kein medizinischer oder präziser Fitnesstracker.
- Nur so viele Wiederholungen einstellen, wie angenehm und sicher sind; man kann die Übung jederzeit abbrechen.
- AlarmKit plant hier nur einen EINMALIGEN Alarm; kein automatischer täglicher Wiederholungswecker.

## Hinweise zur Entwicklung
- Target: iOS 26, SwiftUI, Vision, AVFoundation, AlarmKit, AppIntents
- Keine Drittanbieter-Abhängigkeiten.
- Plist-Berechtigungen: `NSCameraUsageDescription`, `NSAlarmKitUsageDescription`
