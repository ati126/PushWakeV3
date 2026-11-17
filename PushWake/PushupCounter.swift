import Foundation
import Vision
import CoreGraphics

// Tune this single block when testing on a real device.
enum PoseTuning {
    static let confidence: Float = 0.36
    static let overlayConfidence: Float = 0.25
    static let smoothing: CGFloat = 0.38 // EMA: 0 = frozen, 1 = unfiltered
    static let upAngle: Double = 153
    static let downAngle: Double = 108
    static let minimumStableFrames = 3
    static let minimumRepInterval: TimeInterval = 0.65
    static let maximumMissingFrames = 8
    static let maximumTorsoTiltDegrees: Double = 45
    static let minimumBodyLength: CGFloat = 0.22
    static let minimumShoulderHipAnkleAlignment: Double = 48
    static let analysisInterval: TimeInterval = 0.085
}

typealias BodyJoint = VNHumanBodyPoseObservation.JointName

struct TrackedJoint {
    var location: CGPoint // Vision normalized coordinates, origin bottom-left
    var confidence: Float
}

struct PoseSnapshot {
    var points: [BodyJoint: TrackedJoint] = [:]
    var imageSize: CGSize = CGSize(width: 480, height: 640)
}

struct CounterResult {
    let count: Int
    let message: String
    let snapshot: PoseSnapshot
}

struct PushupCounter {
    private enum Phase { case waitingForTop, top, bottom }
    private var phase: Phase = .waitingForTop
    private var proposed: Phase?
    private var matchingFrames = 0
    private var missingFrames = 0
    private var lastRep: TimeInterval = -100
    private var smoothed: [BodyJoint: CGPoint] = [:]
    private(set) var count = 0

    mutating func reset() {
        count = 0; phase = .waitingForTop; proposed = nil
        matchingFrames = 0; missingFrames = 0; lastRep = -100
        smoothed.removeAll()
    }

    mutating func noBody() -> CounterResult {
        missingFrames += 1
        if missingFrames > PoseTuning.maximumMissingFrames { proposed = nil; matchingFrames = 0; phase = .waitingForTop; smoothed.removeAll() }
        return CounterResult(count: count, message: "Kein Körper erkannt – etwas weiter zurück", snapshot: PoseSnapshot())
    }

    mutating func ingest(_ pose: VNHumanBodyPoseObservation, now: TimeInterval, imageSize: CGSize) -> CounterResult {
        guard let raw = try? pose.recognizedPoints(.all) else { return noBody() }
        missingFrames = 0
        var joints: [BodyJoint: TrackedJoint] = [:]
        for (name, point) in raw {
            guard point.confidence >= PoseTuning.overlayConfidence else { continue }
            let pos = point.location
            let smooth: CGPoint
            if let previous = smoothed[name] {
                let k = PoseTuning.smoothing
                smooth = CGPoint(x: previous.x + (pos.x - previous.x) * k,
                                 y: previous.y + (pos.y - previous.y) * k)
            } else { smooth = pos }
            smoothed[name] = smooth
            joints[name] = TrackedJoint(location: smooth, confidence: point.confidence)
        }
        let snap = PoseSnapshot(points: joints, imageSize: imageSize)
        func report(_ s: String) -> CounterResult { CounterResult(count: count, message: s, snapshot: snap) }
        typealias Side = (BodyJoint, BodyJoint, BodyJoint, BodyJoint, BodyJoint)
        let sides: [Side] = [(.leftShoulder, .leftElbow, .leftWrist, .leftHip, .leftAnkle),
                             (.rightShoulder, .rightElbow, .rightWrist, .rightHip, .rightAnkle)]
        var selected: Side?
        var best: Float = -1
        for side in sides {
            guard let a = joints[side.0], let b = joints[side.1], let c = joints[side.2],
                  let d = joints[side.3], let e = joints[side.4] else { continue }
            let conf = min(a.confidence, b.confidence, c.confidence, d.confidence, e.confidence)
            if conf > best { best = conf; selected = side }
        }
        guard let side = selected, best >= PoseTuning.confidence else {
            proposed = nil; matchingFrames = 0
            return report("Seitlich zur Kamera – Arme, Hüfte und Füße zeigen")
        }
        let shoulder = joints[side.0]!.location, elbow = joints[side.1]!.location
        let wrist = joints[side.2]!.location, hip = joints[side.3]!.location
        let ankle = joints[side.4]!.location
        let bodyLength = hypot(shoulder.x - ankle.x, shoulder.y - ankle.y)
        if bodyLength < PoseTuning.minimumBodyLength { return report("Weiter zurück – ganzer Körper muss sichtbar sein") }
        // Ratio in portrait sensor coordinates: use the pixel aspect ratio to avoid distorted angles.
        let ratio = imageSize.width / max(1, imageSize.height)
        func vec(_ x: CGPoint, _ y: CGPoint) -> CGVector {
            CGVector(dx: (x.x-y.x) * ratio, dy: x.y-y.y)
        }
        func angle(_ a: CGVector, _ b: CGVector) -> Double? {
            let denom = hypot(a.dx, a.dy) * hypot(b.dx, b.dy)
            guard denom > 0.00001 else { return nil }
            return Double(acos(max(-1, min(1, (a.dx*b.dx + a.dy*b.dy)/denom))) * 180 / .pi)
        }
        let axis = vec(ankle, shoulder)
        let tilt = Double(atan2(abs(axis.dy), abs(axis.dx)) * 180 / .pi)
        guard tilt <= PoseTuning.maximumTorsoTiltDegrees else {
            proposed = nil; matchingFrames = 0
            return report("Seitlich aufstellen – Körper waagerecht ins Bild")
        }
        if let alignment = angle(vec(shoulder, hip), vec(ankle, hip)),
           alignment < PoseTuning.minimumShoulderHipAnkleAlignment {
            proposed = nil; matchingFrames = 0
            return report("Körper strecken – Schulter, Hüfte und Beine ausrichten")
        }
        guard let elbowDegrees = angle(vec(shoulder, elbow), vec(wrist, elbow)) else {
            return report("Ellbogen nicht sichtbar – leicht drehen")
        }
        let detection: Phase?
        if elbowDegrees >= PoseTuning.upAngle { detection = .top }
        else if elbowDegrees <= PoseTuning.downAngle { detection = .bottom }
        else { detection = nil }
        if let detection {
            if proposed == detection { matchingFrames += 1 }
            else { proposed = detection; matchingFrames = 1 }
            if matchingFrames >= PoseTuning.minimumStableFrames && phase != detection {
                switch (phase, detection) {
                case (.waitingForTop, .top): phase = .top
                case (.top, .bottom): phase = .bottom
                case (.bottom, .top):
                    if now - lastRep >= PoseTuning.minimumRepInterval { count += 1; lastRep = now }
                    phase = .top
                default: break
                }
            }
        } else { proposed = nil; matchingFrames = 0 }
        let instruction = phase == .bottom ? "Jetzt hochdrücken" : "Langsam absenken"
        return report("Armwinkel \(Int(elbowDegrees.rounded()))° · \(instruction)")
    }
}
