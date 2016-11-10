//
//  WhisperBridge.swift
//  Conversa
//
//  Created by Edgar Gomez on 3/25/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

import Foundation
import Whisper

@objc open class WhisperBridge: NSObject {
    
    static open func whisper(_ text: String, backgroundColor: UIColor, toNavigationController: UINavigationController, silenceAfter: TimeInterval) {
//        let message = Message(title: text, textColor: backgroundColor, backgroundColor: backgroundColor, images: nil)
//        Whisper(message, to: toNavigationController)
//        
//        if silenceAfter > 0.1 {
//            Silent(toNavigationController, after: silenceAfter)
//        }
    }
    
    static open func shout(_ text: String, backgroundColor: UIColor, toNavigationController: UINavigationController, silenceAfter: TimeInterval) {
//        let announcement = Announcement(title: "Your title", subtitle: "Your subtitle", image: UIImage(named: "avatar"))
//        Shout(announcement, to: toNavigationController)
//        
//        if silenceAfter > 0.1 {
//            Silent(toNavigationController, after: silenceAfter)
//        }
    }
}
