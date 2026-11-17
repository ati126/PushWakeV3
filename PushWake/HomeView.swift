import SwiftUI

private let accent = Color(red: 0.48, green: 0.96, blue: 0.43)

struct HomeView: View {
    @EnvironmentObject private var alarms: AlarmController
    @Environment(\.scenePhase) private var scenePhase
    @State private var workoutOpen = false
    @State private var showingHelp = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack {
                        Image(systemName: "alarm.fill").foregroundStyle(accent)
                        Text("PUSHWAKE").font(.headline).tracking(3)
                        Spacer()
                        Image(systemName: "moon.stars.fill").foregroundStyle(.gray)
                    }
                    .padding(.top, 12)

                    Text("Aufstehen.\nDurchstarten.")
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .tracking(-1.5)

                    VStack(alignment: .leading, spacing: 18) {
                        Label("DEIN NÄCHSTER WECKER", systemImage: "clock")
                            .font(.caption.bold()).foregroundStyle(.gray)
                        HStack(spacing: 8) {
                            Picker("Stunde", selection: $alarms.hour) {
                                ForEach(0..<24) { Text(String(format: "%02d", $0)).tag($0) }
                            }.pickerStyle(.wheel).frame(maxWidth: .infinity)
                            Text(":").font(.largeTitle.bold())
                            Picker("Minute", selection: $alarms.minute) {
                                ForEach(0..<60) { Text(String(format: "%02d", $0)).tag($0) }
                            }.pickerStyle(.wheel).frame(maxWidth: .infinity)
                        }
                        .frame(height: 145).clipped()
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Liegestütze").font(.title3.bold())
                                Text("Wähle ein angenehmes Ziel").font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Stepper("\(alarms.goal)", value: $alarms.goal, in: 1...30)
                                .labelsHidden()
                            Text("\(alarms.goal)").font(.title2.bold()).monospacedDigit()
                        }
                        Text(alarms.status).font(.footnote).foregroundStyle(.secondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Label("ALARMKIT-DIAGNOSE", systemImage: "stethoscope")
                                .font(.caption.bold())
                            Text(alarms.diagnostic)
                                .font(.caption)
                                .textSelection(.enabled)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .foregroundStyle(.secondary)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 10))

                        Button {
                            Task { await alarms.save() }
                        } label: {
                            HStack {
                                if alarms.busy { ProgressView().tint(.black) }
                                Image(systemName: "alarm.fill")
                                Text(alarms.hasAlarm ? "Wecker aktualisieren" : "Wecker aktivieren")
                            }
                            .frame(maxWidth: .infinity).padding(16)
                        }
                        .buttonStyle(.plain).font(.headline)
                        .foregroundStyle(.black).background(accent, in: RoundedRectangle(cornerRadius: 16))
                        .disabled(alarms.busy)
                        if alarms.hasAlarm {
                            Button("Wecker löschen", role: .destructive) { alarms.remove() }
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(22)
                    .background(Color.white.opacity(0.07), in: RoundedRectangle(cornerRadius: 24))

                    VStack(alignment: .leading, spacing: 12) {
                        Label("KAMERA TESTEN", systemImage: "camera.viewfinder")
                            .font(.caption.bold()).foregroundStyle(.gray)
                        Text("Teste die Liegestützerkennung, bevor du dich darauf verlässt.")
                            .foregroundStyle(.secondary)
                        Button("Training starten") { workoutOpen = true }
                            .font(.headline).frame(maxWidth: .infinity).padding(16)
                            .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    }
                    .padding(22)
                    .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 24))

                    Text("Hinweis: Die iOS-Systemoberfläche kann den Wecker unabhängig von den Liegestützen stoppen. PushWake benötigt iOS 26 oder neuer.")
                        .font(.caption).foregroundStyle(.gray)
                }
                .padding(22)
            }
            .background(Color(red: 0.055, green: 0.07, blue: 0.08))
            .toolbar(.hidden, for: .navigationBar)
            .fullScreenCover(isPresented: $workoutOpen) { WorkoutView(goal: alarms.goal) }
            .onAppear { checkWorkoutLaunch() }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { checkWorkoutLaunch() }
            }
        }
    }

    private func checkWorkoutLaunch() {
        guard UserDefaults.standard.bool(forKey: "openWorkoutRequested") else { return }
        UserDefaults.standard.removeObject(forKey: "openWorkoutRequested")
        workoutOpen = true
    }
}

struct WorkoutView: View {
    @EnvironmentObject private var alarms: AlarmController
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var tracker = CameraTracker()
    @State private var completed = false
    let goal: Int

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 18) {
                    HStack {
                        Label("PUSHWAKE", systemImage: "alarm.fill")
                            .font(.headline.weight(.heavy)).tracking(2)
                            .foregroundStyle(accent)
                        Spacer()
                        Button("Beenden") { dismiss() }
                            .foregroundStyle(.orange)
                    }
                    .padding(.top, 8)
                    Text(completed ? "Ziel erreicht!" : "Liegestütze")
                        .font(.system(.largeTitle, design: .rounded, weight: .black))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .minimumScaleFactor(0.75)
                    ZStack(alignment: .topLeading) {
                        CameraPreview(session: tracker.session, snapshot: tracker.snapshot)
                            .accessibilityLabel("Gespiegelte Frontkamera mit Skelettlinien")
                        Label("Frontkamera · Live", systemImage: "camera.fill")
                            .font(.caption.weight(.semibold))
                            .padding(9)
                            .background(.black.opacity(0.72), in: Capsule())
                            .padding(12)
                        if !tracker.authorized {
                            Text("Kameraberechtigung benötigt")
                                .font(.callout).padding(12)
                                .background(.black.opacity(0.85), in: Capsule())
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                    .frame(height: max(210, min(geometry.size.height * 0.41, 370)))
                    .clipShape(RoundedRectangle(cornerRadius: 24))

                    ZStack {
                        Circle().stroke(Color.white.opacity(0.11), lineWidth: 11)
                        Circle().trim(from: 0, to: CGFloat(min(tracker.count, goal)) / CGFloat(max(goal,1)))
                            .stroke(accent, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(reduceMotion ? nil : .easeOut(duration: 0.28), value: tracker.count)
                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(tracker.count)").font(.system(size: 54, weight: .black, design: .rounded))
                                .foregroundStyle(accent).contentTransition(.numericText())
                            Text("/ \(goal)").font(.title3).foregroundStyle(.secondary)
                        }
                        .monospacedDigit()
                    }
                    .frame(width: 148, height: 148)
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(tracker.count) von \(goal) Liegestützen")
                    Text(tracker.message)
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, minHeight: 42)
                    Button("Zähler zurücksetzen") { tracker.reset() }
                        .font(.headline).frame(maxWidth: .infinity).padding(16)
                        .background(Color.white.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                        .disabled(completed)
                    Text("Körper seitlich und vollständig im Bild halten. Alle Joints müssen sichtbar sein.")
                        .font(.footnote).foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 28)
            }
            .scrollIndicators(.hidden)
            .background(Color(red: 0.055, green: 0.07, blue: 0.08))
        }
        .overlay {
            if completed { SuccessCelebration(reduceMotion: reduceMotion) }
        }
        .onAppear { tracker.start() }
        .onDisappear { tracker.stop() }
        .onChange(of: tracker.count) { _, newCount in
            guard newCount >= goal, !completed else { return }
            completed = true
            tracker.stop()
            // Stop system alarm BEFORE playing the completion sound.
            alarms.finishWorkout()
            SuccessAudio.shared.play()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            Task { @MainActor in
                try? await Task.sleep(for: .seconds(2.8))
                dismiss()
            }
        }
    }
}
