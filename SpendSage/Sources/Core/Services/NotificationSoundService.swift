import AVFoundation
import UIKit
import UserNotifications

enum AppNotificationSoundStyle: String, CaseIterable {
    case off
    case miau
    case playful

    init(rawPreference: String) {
        self = AppNotificationSoundStyle(rawValue: rawPreference.lowercased()) ?? .playful
    }

    var bundledFileName: String? {
        switch self {
        case .off:
            return nil
        case .miau:
            return "miau"
        case .playful:
            return "playful"
        }
    }

    var displayName: String {
        switch self {
        case .off:
            return "Silencio"
        case .miau:
            return "Miau"
        case .playful:
            return "Juguetón"
        }
    }

    var notificationSound: UNNotificationSound? {
        guard let bundledFileName else { return nil }
        return UNNotificationSound(named: UNNotificationSoundName("\(bundledFileName).caf"))
    }
}

@MainActor
final class NotificationSoundPreviewService {
    static let shared = NotificationSoundPreviewService()

    private var player: AVAudioPlayer?

    private init() {}

    func play(style: AppNotificationSoundStyle) {
        guard let bundledFileName = style.bundledFileName else { return }
        guard let url = Bundle.main.url(forResource: bundledFileName, withExtension: "caf") else {
            fallback(style: style)
            return
        }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true, options: [])

            player = try AVAudioPlayer(contentsOf: url)
            player?.prepareToPlay()
            player?.volume = 1
            player?.play()
        } catch {
            fallback(style: style)
        }
    }

    private func fallback(style: AppNotificationSoundStyle) {
        let generator = UINotificationFeedbackGenerator()
        switch style {
        case .off:
            break
        case .miau:
            generator.notificationOccurred(.warning)
        case .playful:
            generator.notificationOccurred(.success)
        }
    }
}
