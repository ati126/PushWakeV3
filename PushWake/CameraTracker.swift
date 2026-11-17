import SwiftUI
import AVFoundation
import Vision
import ImageIO
import UIKit

final class CameraTracker: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    let session = AVCaptureSession()
    @Published private(set) var count = 0
    @Published private(set) var message = "Kamera wird vorbereitet …"
    @Published private(set) var authorized = false
    @Published private(set) var snapshot = PoseSnapshot()

    private let captureQueue = DispatchQueue(label: "pushwake.capture", qos: .userInitiated)
    private let output = AVCaptureVideoDataOutput()
    private let request = VNDetectHumanBodyPoseRequest()
    private var counter = PushupCounter()
    private var configured = false
    private var active = false
    private var lastAnalysis = -100.0

    func start() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] permission in
            guard let self else { return }
            DispatchQueue.main.async {
                self.authorized = permission
                if !permission { self.message = "Kamera in den Einstellungen erlauben" }
            }
            guard permission else { return }
            self.captureQueue.async { self.configureAndStart() }
        }
    }

    private func configureAndStart() {
        if !configured {
            session.beginConfiguration()
            session.sessionPreset = .vga640x480
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let input = try? AVCaptureDeviceInput(device: camera), session.canAddInput(input) else {
                session.commitConfiguration()
                DispatchQueue.main.async { self.message = "Frontkamera nicht verfügbar" }
                return
            }
            session.addInput(input)
            output.alwaysDiscardsLateVideoFrames = true
            output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            guard session.canAddOutput(output) else {
                session.commitConfiguration()
                DispatchQueue.main.async { self.message = "Kamera-Ausgabe nicht verfügbar" }
                return
            }
            session.addOutput(output)
            // Processing receives upright portrait buffers without mirroring.
            // Preview is mirrored separately, so overlay flips X once.
            if let conn = output.connection(with: .video) {
                if conn.isVideoRotationAngleSupported(90) { conn.videoRotationAngle = 90 }
                if conn.isVideoMirroringSupported {
                    conn.automaticallyAdjustsVideoMirroring = false
                    conn.isVideoMirrored = false
                }
            }
            output.setSampleBufferDelegate(self, queue: captureQueue)
            session.commitConfiguration()
            configured = true
        }
        active = true
        if !session.isRunning { session.startRunning() }
    }

    func stop() {
        captureQueue.async {
            self.active = false
            if self.session.isRunning { self.session.stopRunning() }
        }
    }

    func reset() {
        captureQueue.async {
            self.counter.reset()
            DispatchQueue.main.async {
                self.count = 0
                self.message = "Startposition einnehmen"
                self.snapshot = PoseSnapshot()
            }
        }
    }

    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
                       from connection: AVCaptureConnection) {
        guard active, let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let time = ProcessInfo.processInfo.systemUptime
        guard time - lastAnalysis >= PoseTuning.analysisInterval else { return }
        lastAnalysis = time
        let size = CGSize(width: CVPixelBufferGetWidth(buffer), height: CVPixelBufferGetHeight(buffer))
        do {
            // Buffer is physically rotated into portrait by the output connection.
            try VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .up).perform([request])
            let result: CounterResult
            if let pose = request.results?.first { result = counter.ingest(pose, now: time, imageSize: size) }
            else { result = counter.noBody() }
            DispatchQueue.main.async {
                self.count = result.count
                self.message = result.message
                self.snapshot = result.snapshot
            }
        } catch {
            DispatchQueue.main.async { self.message = "Vision-Fehler: \(error.localizedDescription)" }
        }
    }
}

// Separate preview + CAShapeLayers: no video frame copies and no SwiftUI per-joint views.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    let snapshot: PoseSnapshot

    func makeUIView(context: Context) -> SkeletonPreviewView {
        let view = SkeletonPreviewView()
        view.previewLayer.session = session
        return view
    }
    func updateUIView(_ view: SkeletonPreviewView, context: Context) {
        if view.previewLayer.session !== session { view.previewLayer.session = session }
        view.draw(snapshot: snapshot)
    }
}

final class SkeletonPreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }

    private let lines = CAShapeLayer()
    private let strongDots = CAShapeLayer()
    private let weakDots = CAShapeLayer()
    private var current = PoseSnapshot()
    private typealias J = BodyJoint
    private let links: [(J,J)] = [
        (.leftShoulder,.rightShoulder),(.leftShoulder,.leftElbow),(.leftElbow,.leftWrist),
        (.rightShoulder,.rightElbow),(.rightElbow,.rightWrist),
        (.leftShoulder,.leftHip),(.rightShoulder,.rightHip),(.leftHip,.rightHip),
        (.leftHip,.leftKnee),(.leftKnee,.leftAnkle),(.rightHip,.rightKnee),(.rightKnee,.rightAnkle)
    ]

    override init(frame: CGRect) {
        super.init(frame: frame)
        previewLayer.videoGravity = .resizeAspectFill
        lines.strokeColor = UIColor.systemGreen.cgColor
        lines.fillColor = UIColor.clear.cgColor
        lines.lineWidth = 3
        lines.lineCap = .round
        strongDots.fillColor = UIColor.systemGreen.cgColor
        weakDots.fillColor = UIColor.systemGray.withAlphaComponent(0.6).cgColor
        layer.addSublayer(lines)
        layer.addSublayer(strongDots)
        layer.addSublayer(weakDots)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override func layoutSubviews() {
        super.layoutSubviews()
        for shape in [lines, strongDots, weakDots] { shape.frame = bounds }
        if let conn = previewLayer.connection {
            if conn.isVideoRotationAngleSupported(90) { conn.videoRotationAngle = 90 }
            if conn.isVideoMirroringSupported {
                conn.automaticallyAdjustsVideoMirroring = false
                conn.isVideoMirrored = true
            }
        }
        render()
    }

    func draw(snapshot: PoseSnapshot) { current = snapshot; render() }

    private func render() {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let size = current.imageSize
        let scale = max(bounds.width / max(1,size.width), bounds.height / max(1,size.height))
        let drawnWidth = size.width * scale, drawnHeight = size.height * scale
        let xOffset = (bounds.width - drawnWidth)/2, yOffset = (bounds.height-drawnHeight)/2
        func location(_ joint: J) -> CGPoint? {
            guard let p = current.points[joint] else { return nil }
            // Vision bottom-left -> top-left, then mirror only for selfie preview.
            return CGPoint(x: (1-p.location.x)*drawnWidth+xOffset,
                           y: (1-p.location.y)*drawnHeight+yOffset)
        }
        let linePath = UIBezierPath(), greenPath = UIBezierPath(), grayPath = UIBezierPath()
        for (a,b) in links {
            guard let x = location(a), let y = location(b),
                  let pa = current.points[a], let pb = current.points[b],
                  pa.confidence >= PoseTuning.confidence && pb.confidence >= PoseTuning.confidence else { continue }
            linePath.move(to: x); linePath.addLine(to: y)
        }
        for (name, item) in current.points {
            guard let point = location(name) else { continue }
            let dot = item.confidence >= PoseTuning.confidence ? greenPath : grayPath
            dot.append(UIBezierPath(ovalIn: CGRect(x: point.x-4, y: point.y-4, width: 8, height: 8)))
        }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        lines.path = linePath.cgPath
        strongDots.path = greenPath.cgPath
        weakDots.path = grayPath.cgPath
        CATransaction.commit()
    }
}
