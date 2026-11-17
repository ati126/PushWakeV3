# PushWake V4 – AlarmKit-Diagnose

## Ziel
V4 trennt die Fehler bei `requestAuthorization()` und `schedule()` und zeigt an, ob der Info.plist-Eintrag tatsächlich im installierten App-Bundle sichtbar ist. Sie behebt **nicht garantiert** einen iOS- oder Signierungsfehler.

## GitHub
Ersetze `PushWake/AlarmController.swift` und `PushWake/HomeView.swift` sowie `.github/workflows/build.yml`. Achte darauf, dass keine zweite alte Workflow-Datei existiert. Push das Projekt auf `main` und prüfe den erfolgreichen GitHub-Build.

## iPhone
Installiere die neue IPA per Sideloadly. Öffne PushWake und wähle einen Testwecker. Lies anschließend den Abschnitt **ALARMKIT-DIAGNOSE**. Gib die Diagnosezeile weiter (ohne Apple-ID oder Gerätekennungen). Wenn der Fehler schon bei `requestAuthorization()` entsteht, liegt er vor der Wecker-Konfiguration. Falls er erst bei `schedule()` entsteht, ist die Berechtigung bereits erfolgreich erteilt.

Teste Wecker nicht als einzigen Alarm für einen wichtigen Termin. Kamera und Liegestützzähler sind unverändert.
