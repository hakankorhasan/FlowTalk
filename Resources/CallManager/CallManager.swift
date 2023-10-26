//
//  CallManager.swift
//  FlowTalk
//
//  Created by Hakan Körhasan on 26.10.2023.
//

import Foundation
import CallKit

final class CallManager: NSObject, CXProviderDelegate {
    
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let callController = CXCallController()
    
    override init() {
        super.init()
        provider.setDelegate(self, queue: nil)
    }
    
    public func reportIncomingCall(id: UUID, handle: String) {
        print("report incoming")
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        provider.reportNewIncomingCall(with: id, update: update) { error in
            if let error {
                print(String(describing: error))
            } else {
                print("call reported")
            }
        }
    }
    
    public func startCall(id: UUID, handle: String) {
        print("start calling")
        let  handle = CXHandle(type: .generic, value: handle)
        let action = CXStartCallAction(call: id, handle: handle)
        let transaction = CXTransaction(action: action)
        callController.request(transaction) { error in
            if let error {
                print(String(describing: error))
            } else {
                print("call started")
            }
        }
    }
    
    func providerDidReset(_ provider: CXProvider) {
        
    }
    
}
