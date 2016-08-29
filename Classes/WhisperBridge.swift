//
//  WhisperBridge.swift
//  Conversa
//
//  Created by Edgar Gomez on 3/25/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

import Foundation
import Whisper

@objc public class WhisperBridge: NSObject {
    
    static public func whisper(text: String, backgroundColor: UIColor, toNavigationController: UINavigationController, silenceAfter: NSTimeInterval) {
//        let message = Message(title: text, textColor: backgroundColor, backgroundColor: backgroundColor, images: nil)
//        Whisper(message, to: toNavigationController)
//        
//        if silenceAfter > 0.1 {
//            Silent(toNavigationController, after: silenceAfter)
//        }
    }
    
    static public func shout(text: String, backgroundColor: UIColor, toNavigationController: UINavigationController, silenceAfter: NSTimeInterval) {
//        let announcement = Announcement(title: "Your title", subtitle: "Your subtitle", image: UIImage(named: "avatar"))
//        Shout(announcement, to: toNavigationController)
//        
//        if silenceAfter > 0.1 {
//            Silent(toNavigationController, after: silenceAfter)
//        }
    }
}