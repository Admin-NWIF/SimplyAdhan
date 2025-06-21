//
//  AudioManager.swift
//  SimplyAthan
//
//  Created by Usman Hasan on 5/28/25.
//

import AVFoundation

class AudioManager {
    static let shared = AudioManager()
    var player: AVAudioPlayer?
    
    func playAdhan(prayer: String) -> Bool {
        if prayer == Prayers.SUNRISE.rawValue || prayer == Prayers.QIYAM.rawValue {
            return false
        }
        else if prayer == Prayers.FAJR.rawValue {
            guard let url = Bundle.main.url(forResource: "Adhan_fajr", withExtension: "mp3") else { return false }
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.play()
                return true
            } catch {
                print("❌ Failed to play Fajr Adhan: \(error.localizedDescription)")
            }
        } else {
            guard let url = Bundle.main.url(forResource: "Adhan_normal", withExtension: "mp3") else { return false }
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.play()
            } catch {
                print("❌ Failed to play Adhan: \(error.localizedDescription)")
            }
        }
        return true
    }

    func stopAdhan() {
        player?.stop()
    }
}
