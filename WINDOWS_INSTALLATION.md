# PushWake: kostenlos von Windows auf dein iPhone (experimenteller Weg)

Dieser Weg benötigt keinen eigenen Mac, aber einen kostenlosen GitHub-Account, einen kostenlosen Apple-Account, einen Windows-PC und ein iPhone mit iOS 26 oder neuer.

## 1. Cloud-Build auf GitHub
1. Gehe auf https://github.com/new und erstelle ein Repository (öffentlich: GitHub-hosted Standard-Runner sind im Allgemeinen kostenlos; bei privaten Repositories gelten Kontingente/Billing-Regeln). Speichere keine Passwörter oder privaten Daten im Repository.
2. Lade **den Inhalt des Ordners PushWake** hoch, sodass `PushWake.xcodeproj` und `.github/workflows/ios-unsigned-ipa.yml` im Wurzelverzeichnis deines Repositories liegen. GitHub Web-Upload kann versteckte Ordner/Dateipfade unpraktisch machen; alternativ Git lokal installieren und `git add .`, Commit und Push verwenden.
3. Öffne im Repository **Actions** -> **Build PushWake unsigned IPA** -> **Run workflow**.
4. Falls der Build fehlschlägt, öffne das Log. Das Projekt ist bisher nicht auf einem Mac kompiliert worden; es können noch Swift-/AlarmKit-Fehler vorhanden sein. Achte darauf, dass der macOS-Runner ein Xcode mit iOS-26-SDK verwendet; ggf. Workflow-Runner/Xcode-Version anpassen.
5. Wenn der Build erfolgreich ist, lade unter **Artifacts** `PushWake-unsigned-ipa.zip` herunter und entpacke darin `PushWake-unsigned.ipa`.

## 2. Windows-Installation
1. Lade Sideloadly von https://sideloadly.io/ und installiere gegebenenfalls die von Sideloadly geforderten offiziellen Apple-Treiber (iTunes/iCloud).
2. Verbinde das iPhone per USB mit Windows, entsperre es und vertraue dem Computer.
3. Ziehe `PushWake-unsigned.ipa` nach Sideloadly, wähle dein iPhone, melde dich über die App bei deinem Apple-Account an und starte die Signierung/Installation.
4. Falls iOS dazu auffordert: Einstellungen -> Datenschutz & Sicherheit -> Entwicklermodus aktivieren; Gerät neu starten. Unter Einstellungen -> Allgemein -> VPN & Geräteverwaltung die eigene Entwickler-App vertrauen.
5. Öffne PushWake, erlaube Kamera und – falls verfügbar – Alarme. Teste zuerst die Liegestützerkennung, dann einen Testwecker in wenigen Minuten.

## Grenzen
- Unsigned IPA -> Signierung mit einem kostenlosen Apple-Account ist ein experimenteller Workflow und keine Erfolgsgarantie. Manche Entitlements bzw. AlarmKit-Funktionen können durch kostenlose Signierung oder Sideloading eingeschränkt sein.
- Die App wird mit kostenlosem Account nur etwa **7 Tage** laufen, bevor sie erneut signiert werden muss. Sideloadly bietet eine Refresh-Funktion, die von Windows/iPhone-Erreichbarkeit abhängt.
- Ein GitHub-Workflow braucht für echtes iPhone einen Xcode-Build mit `iphoneos`, kein Simulator-Build.
- Die iOS-Systemalarm-Oberfläche besitzt eine Stoppmöglichkeit. Kameraerkennung muss bei geöffneter App laufen. **Bitte zusätzlich den normalen iPhone-Wecker verwenden, bis PushWake über mehrere Tage zuverlässig getestet wurde.**
- Nimm dir ein angenehmes Liegestützziel und höre bei Schmerzen oder Unwohlsein auf.
