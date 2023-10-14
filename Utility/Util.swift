//
//  Util.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 14.10.2023.
//

import Foundation
import UIKit
import FirebaseStorage

class Util {
    static func getStringFromDate(format: String, date: Date) -> String {
       /* let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = format
        //dateFormatter.dateFormat = "YYYY,MMM d,HH:mm:ss"
        
        return dateFormatter.string(from: date)*/
        let calendar = Calendar.current
                let today = calendar.startOfDay(for: Date())
                let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
                
                let dateFormatter = DateFormatter()
                
                if calendar.isDateInToday(date) {
                    // Bugünün tarihi ise, "Bugün" ile saat ve tarih bilgisini döndür
                    dateFormatter.dateFormat = "'Today' HH:mm"
                } else if calendar.isDateInYesterday(date) {
                    // Dünün tarihi ise, "Dün" ile saat ve tarih bilgisini döndür
                    dateFormatter.dateFormat = "'Yesterday' HH:mm"
                } else {
                    // Başka bir tarihte ise, belirtilen formatı kullan
                    dateFormatter.dateFormat = format
                }
                
                return dateFormatter.string(from: date)
    }
    
    static func lockOrientation(_ orientation: UIInterfaceOrientationMask) {
        
        if let delegate = UIApplication.shared.delegate as? AppDelegate {
            delegate.orientationLock = orientation
        }
    }
}
