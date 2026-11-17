# PushWake Diagnose V2

Diese Version ist noch nicht auf einem iPhone getestet. Die bereits erfolgreich kompilierte Projektstruktur bleibt erhalten.

## Änderungen
- Liegestützzähler: wählt die am besten erkannte Körperseite; zeigt Armwinkel an; etwas tolerantere Winkel und Sichtbarkeitsschwelle.
- AlarmKit: zeigt bei Fehlversuchen Error-Domain, Error-Code und Fehlermeldung an.
- Vorhandener Eintrag NSAlarmKitUsageDescription bleibt bestehen.

## Hochladen
Die beiden Swift-Dateien unter PushWake/ im GitHub-Repository durch die beigefügten Dateien ersetzen. Die Workflow-Datei nicht ändern.

## Funktionstest
1. Zuerst in PushWake die Training-Ansicht öffnen, seitlich mit gutem Licht die Gelenke sichtbar machen, nur wenige komfortable Wiederholungen testen und den Winkeltext beobachten. Wenn der Winkel sich nicht ändert, stimmt die Körpererkennung/Kameraausrichtung nicht.
2. Danach auf Wecker aktivieren tippen und **genauen** Status im Feld unter der Liegestützzahl notieren.
3. Vor jedem realen Weckversuch weiterhin einen normalen iOS-Wecker als Backup setzen.

Hinweis: Beim Software-Build wird die Installierbarkeit oder Funktionsfähigkeit der Kamera und AlarmKit nicht automatisch geprüft.
