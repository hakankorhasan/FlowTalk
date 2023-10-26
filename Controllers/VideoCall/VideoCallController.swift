//
//  VideoCallController.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 24.10.2023.
//

import UIKit

class VideoCallController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        startDemo()
    }

    func startDemo() {
        DispatchQueue.main.asyncAfter(deadline: .now()+2, execute: {
            let callManager = CallManager()
            let id = UUID()
            callManager.startCall(id: id, handle: "Ali Yatmaz")
        })
    }
}
