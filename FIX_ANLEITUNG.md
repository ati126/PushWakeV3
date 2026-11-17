# PushWake – AlarmKit-Korrektur (17.11.2026)

Der letzte GitHub-Actions-Build verwendete erfolgreich Xcode 26.3 mit iOS-SDK 26.2.

## GitHub aktualisieren
1. Öffne im Repository die Datei `PushWake/AlarmController.swift`.
2. Ersetze ihren gesamten Inhalt durch den Inhalt von `AlarmController_fixed.swift` (separat bereitgestellt) oder aus diesem Paket `PushWake/PushWake/AlarmController.swift`.
3. Commit changes. Dein bestehender `.github/workflows/build.yml`-Workflow startet bei entsprechendem Push oder manuell über Actions.

## Änderungen
- `.stopButton` ersetzt durch expliziten `AlarmButton`
- `metadata: EmptyAlarmMetadata()` zu `AlarmAttributes` hinzugefügt
- Alarmkonfiguration explizit typisiert

Dieser Patch wurde statisch anhand des Buildlogs und der Apple-API-Dokumentation überprüft; ohne macOS/Xcode hier nicht lokal kompiliert. Mögliche weitere Compiler- oder Laufzeitprobleme bleiben offen.
