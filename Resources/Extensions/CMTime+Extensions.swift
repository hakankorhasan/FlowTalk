//
//  CMTime+Extensions.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 14.10.2023.
//

import AVFoundation

extension CMTime {
    func getTimeString() -> String? {
        let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!

                let totalSeconds = CMTimeGetSeconds(self)
                guard !(totalSeconds.isNaN || totalSeconds.isInfinite) else {
                    return "Bilinmiyor"
                }
                let date = Date(timeIntervalSince1970: totalSeconds)

                let dateFormatter = DateFormatter()
                
                if calendar.isDateInToday(date) {
                    // Bugünün tarihi ise, saat bilgisini döndür
                    dateFormatter.dateFormat = "'Today' HH:mm"
                } else if calendar.isDateInYesterday(date) {
                    // Dünün tarihi ise, "Dün" bilgisini ekler
                    dateFormatter.dateFormat = "HH:mm"
                    return "Yesterday " + dateFormatter.string(from: date)
                } else {
                    // Başka bir tarihte ise, tam tarih ve saat bilgisini döndür
                    dateFormatter.dateFormat = "dd/MM/yyyy HH:mm"
                }
                
                return dateFormatter.string(from: date)
        /*let totalSeconds = CMTimeGetSeconds(self)
        guard !(totalSeconds.isNaN || totalSeconds.isInfinite) else {
            return nil
        }
        let hours = Int(totalSeconds / 3600)
        let minutes = Int(totalSeconds / 60) % 60
        let seconds = Int(totalSeconds.truncatingRemainder(dividingBy: 60))
        if hours > 0 {
            return String(format: "%i:%02i:%02i",arguments: [hours, minutes, seconds])
        } else {
            return String(format: "%02i:%02i", arguments: [minutes, seconds])
        }*/
    }
}
