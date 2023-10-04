//
//  Audio.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 30.09.2023.
//

import UIKit
import MessageKit


class Audio : AudioItem {
    var url: URL
    
    var duration: Float = 0.0
    
    var size: CGSize
    
    init(url: URL, duration: Float, size: CGSize) {
        self.url = url
        self.duration = duration
        self.size = size
    }
}
