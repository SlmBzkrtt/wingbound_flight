import AVFoundation
import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var audioPlayers: [String: [AVAudioPlayer]] = [:]
  private var playerIndices: [String: Int] = [:]

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    let audioChannel = FlutterMethodChannel(
      name: "com.selimbozkurt.wingbound/audio",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    audioChannel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      if call.method == "preload",
         let args = call.arguments as? [String: Any],
         let id = args["id"] as? String,
         let typedData = args["wav"] as? FlutterStandardTypedData {
        var pool: [AVAudioPlayer] = []
        for _ in 0..<4 {
          if let player = try? AVAudioPlayer(data: typedData.data) {
            player.prepareToPlay()
            pool.append(player)
          }
        }
        self.audioPlayers[id] = pool
        self.playerIndices[id] = 0
        result(true)
      } else if call.method == "play",
                let args = call.arguments as? [String: Any],
                let id = args["id"] as? String,
                let pool = self.audioPlayers[id],
                !pool.isEmpty {
        let idx = (self.playerIndices[id] ?? 0) % pool.count
        self.playerIndices[id] = idx + 1
        let player = pool[idx]
        if let vol = args["volume"] as? Double {
          player.volume = Float(vol)
        }
        player.currentTime = 0
        player.play()
        result(true)
      } else {
        result(false)
      }
    }

    RegisterGeneratedPlugins(registry: flutterViewController)

    super.awakeFromNib()
  }
}
