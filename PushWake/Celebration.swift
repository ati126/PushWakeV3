import SwiftUI
import AVFoundation
import QuartzCore
import UIKit

final class SuccessAudio {
    static let shared = SuccessAudio()
    private var player: AVAudioPlayer?
    private init() {}

    func play() {
        guard let url = Bundle.main.url(forResource: "success", withExtension: "wav") else { return }
        do {
            let audio = AVAudioSession.sharedInstance()
            try audio.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audio.setActive(true)
            player?.stop()
            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.play()
        } catch { print("Completion audio unavailable: \(error.localizedDescription)") }
    }
}

struct SuccessCelebration: View {
    let reduceMotion: Bool
    var body: some View {
        ZStack {
            Color.black.opacity(0.86).ignoresSafeArea()
            if !reduceMotion { ConfettiView().ignoresSafeArea().allowsHitTesting(false) }
            VStack(spacing: 18) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 76)).foregroundStyle(.green)
                Text("Geschafft!")
                    .font(.system(.largeTitle, design: .rounded, weight: .black))
                Text("Dein Ziel ist erreicht.")
                    .font(.headline).foregroundStyle(.secondary)
            }
            .padding(30)
            .accessibilityElement(children: .combine)
        }
        .transition(.opacity)
    }
}

struct ConfettiView: UIViewRepresentable {
    func makeUIView(context: Context) -> ConfettiUIView { ConfettiUIView() }
    func updateUIView(_ uiView: ConfettiUIView, context: Context) {}
}

final class ConfettiUIView: UIView {
    private let emitter = CAEmitterLayer()
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        emitter.emitterShape = .line
        emitter.emitterMode = .surface
        emitter.beginTime = CACurrentMediaTime()
        emitter.emitterCells = [UIColor.systemGreen, UIColor.white, UIColor.systemYellow].map { color in
            let cell = CAEmitterCell()
            cell.contents = Self.dotImage(color: color)?.cgImage
            cell.birthRate = 15
            cell.lifetime = 2.4
            cell.velocity = 190
            cell.velocityRange = 75
            cell.emissionLongitude = .pi
            cell.emissionRange = .pi / 2
            cell.spinRange = 3
            cell.scale = 0.18
            cell.scaleRange = 0.08
            return cell
        }
        layer.addSublayer(emitter)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }
    override func layoutSubviews() {
        super.layoutSubviews()
        emitter.frame = bounds
        emitter.emitterPosition = CGPoint(x: bounds.midX, y: -8)
        emitter.emitterSize = CGSize(width: bounds.width, height: 1)
    }
    private static func dotImage(color: UIColor) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: 14, height: 10))
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(x: 0, y: 0, width: 14, height: 10))
        }
    }
}
