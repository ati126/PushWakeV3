import SwiftUI
import AlarmKit
import AppIntents

// App Intent for the second button of the system alarm.
struct OpenWorkoutIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Liegestütze starten"
    static var description = IntentDescription("Öffnet PushWake für das Training")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(true, forKey: "openWorkoutRequested")
        return .result()
    }
}

@MainActor
final class AlarmController: ObservableObject {
    @Published var hour: Int = UserDefaults.standard.object(forKey: "hour") as? Int ?? 7
    @Published var minute: Int = UserDefaults.standard.object(forKey: "minute") as? Int ?? 0
    @Published var goal: Int = max(1, UserDefaults.standard.object(forKey: "goal") as? Int ?? 5)
    @Published var status = "Noch kein Wecker aktiviert"
    @Published var hasAlarm = false
    @Published var busy = false

    private let idKey = "scheduledAlarmID"

    init() {
        hasAlarm = UserDefaults.standard.string(forKey: idKey) != nil
        if hasAlarm { status = "Wecker geplant – über iOS verwaltet" }
    }

    // These messages identify the failing stage without exposing Apple account data.
    @Published var diagnostic = "Noch keine Alarm-Diagnose ausgeführt"

    func save() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }

        // Validate the Info.plist of the INSTALLED app, not just project settings.
        let usage = (Bundle.main.object(forInfoDictionaryKey: "NSAlarmKitUsageDescription") as? String)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let stateBefore = AlarmManager.shared.authorizationState
        diagnostic = "Schritt 1/3: Info.plist=\(usage.isEmpty ? "FEHLT" : "OK"), Berechtigung vorher=\(stateBefore)"
        if usage.isEmpty {
            status = "AlarmKit-Beschreibung fehlt in der installierten App. Bitte Build/Info.plist prüfen."
            return
        }

        // Distinguish a permission error from an invalid alarm configuration.
        let authorization: AlarmManager.AuthorizationState
        do {
            diagnostic = "Schritt 2/3: Frage Alarm-Berechtigung an … (vorher: \(stateBefore))"
            authorization = try await AlarmManager.shared.requestAuthorization()
        } catch {
            let e = error as NSError
            diagnostic = "FEHLER bei requestAuthorization(): \(e.domain) / \(e.code); vorher=\(stateBefore); nachher=\(AlarmManager.shared.authorizationState); Info.plist=OK"
            status = "Alarm-Berechtigungsanfrage fehlgeschlagen. Siehe Diagnose unten."
            return
        }

        guard authorization == .authorized else {
            diagnostic = "Berechtigung nicht erteilt: \(authorization), aktuell=\(AlarmManager.shared.authorizationState)"
            status = "Alarme sind noch nicht erlaubt. Prüfe die iOS-App-Einstellungen."
            return
        }

        // Preserve the existing alarm until a new one has really been scheduled.
        let newID = UUID()
        let time = Alarm.Schedule.Relative.Time(hour: hour, minute: minute)
        let schedule = Alarm.Schedule.relative(.init(time: time, repeats: .never))
        let alert = AlarmPresentation.Alert(
            title: "Zeit für deine Liegestütze!",
            stopButton: AlarmButton(text: "Stoppen", textColor: .white, systemImageName: "stop.circle"),
            secondaryButton: AlarmButton(text: "Training", textColor: .white, systemImageName: "figure.strengthtraining.traditional"),
            secondaryButtonBehavior: .custom
        )
        let attributes = AlarmAttributes<EmptyAlarmMetadata>(
            presentation: AlarmPresentation(alert: alert),
            metadata: EmptyAlarmMetadata(),
            tintColor: .green
        )
        let configuration: AlarmManager.AlarmConfiguration<EmptyAlarmMetadata> = .alarm(
            schedule: schedule,
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: OpenWorkoutIntent(),
            sound: .default
        )
        do {
            diagnostic = "Schritt 3/3: Berechtigung=authorized; Alarm wird geplant …"
            _ = try await AlarmManager.shared.schedule(id: newID, configuration: configuration)
            if let old = savedID { try? AlarmManager.shared.cancel(id: old) }
            UserDefaults.standard.set(newID.uuidString, forKey: idKey)
            UserDefaults.standard.set(hour, forKey: "hour")
            UserDefaults.standard.set(minute, forKey: "minute")
            UserDefaults.standard.set(goal, forKey: "goal")
            hasAlarm = true
            status = String(format: "Wecker auf %02d:%02d gestellt", hour, minute)
            diagnostic = "ERFOLG: Info.plist=OK, Berechtigung=authorized, Planung erfolgreich"
        } catch {
            let e = error as NSError
            diagnostic = "FEHLER bei schedule(): \(e.domain) / \(e.code); Berechtigung=\(AlarmManager.shared.authorizationState); \(e.localizedDescription)"
            status = "Alarm-Planung fehlgeschlagen. Siehe Diagnose unten."
            hasAlarm = savedID != nil
        }
    }

    func remove() {
        guard let id = savedID else { return }
        do {
            try AlarmManager.shared.cancel(id: id)
            clearLocalAlarm()
            status = "Wecker deaktiviert"
        } catch {
            status = "Abbrechen fehlgeschlagen: \(error.localizedDescription)"
        }
    }

    func finishWorkout() {
        // Cancel is a supported manual stop for an alarm; it also removes the scheduled entry.
        if let id = savedID {
            try? AlarmManager.shared.cancel(id: id)
            clearLocalAlarm()
            status = "Training abgeschlossen!"
        }
    }

    private var savedID: UUID? {
        UserDefaults.standard.string(forKey: idKey).flatMap(UUID.init(uuidString:))
    }
    private func clearLocalAlarm() {
        UserDefaults.standard.removeObject(forKey: idKey)
        hasAlarm = false
    }
}

struct EmptyAlarmMetadata: AlarmMetadata { }
