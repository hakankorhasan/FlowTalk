//
//  AudioRecorder.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 2.10.2023.
//


import Foundation
import AVFoundation
import Foundation
import AVFoundation

class AudioRecorder: NSObject, AVAudioRecorderDelegate {
    
    static let shared = AudioRecorder()
        
    var recorder: AVAudioRecorder?
    var player: AVAudioPlayer?
    var timer: Timer?
    var url: URL?
    var audioLevel: Float = 0.0

    func startRecording(audiofilename: String) {
        // Ses kaydetme işlemleri burada
        player?.stop()
        if let recorder = self.recorder{
            if recorder.isRecording{
                self.recorder?.pause()
            }
            else{
                self.recorder?.record()
            }
        }
        else{
            initializeRecorder(audioFile: audiofilename)
        }
    }

    func stopRecording() {
        // Ses kaydetmeyi durdurma işlemleri burada
        self.recorder?.stop()
        let session = AVAudioSession.sharedInstance()
        try! session.setActive(false)
        self.url = self.recorder?.url
        self.recorder = nil
        timer?.invalidate()
        timer = nil
    }

    func initializeRecorder(audioFile: String) {
        // Ses kaydediciyi başlatma işlemleri burada
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, options: .defaultToSpeaker)
        let directory =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        var recordSetting = [AnyHashable: Any]()
        recordSetting[AVFormatIDKey] = kAudioFormatMPEG4AAC
        recordSetting[AVSampleRateKey] = 16000.0
        recordSetting[AVNumberOfChannelsKey] = 1
        if let filePath = directory.first?.appendingPathComponent(audioFile), let audioRecorder = try? AVAudioRecorder(url: filePath, settings: (recordSetting as? [String : Any] ?? [:])){
                print(filePath)
                
            self.recorder = audioRecorder
            self.recorder?.delegate = self
            self.recorder?.isMeteringEnabled = true
            self.recorder?.prepareToRecord()
            self.recorder?.record()
        }
        //filepath is an optional URL
    }

    func playAudio() {
        // Ses çalma işlemleri burada
    }
    
    @objc func playerDidFinishPlaying() {
        // Çalma işlemi tamamlandığında yapılması gereken işlemler burada
        self.player?.stop()
    }
    
    func deleteAudioFileWithName(_ fileName: String) {
        let fileManager = FileManager.default
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let fileURL = documentsDirectory.appendingPathComponent(fileName)
        
        do {
            try fileManager.removeItem(at: fileURL)
            print("Dosya silindi: \(fileName)")
        } catch {
            print("Dosya silinemedi: \(error)")
        }
    }
        
}
