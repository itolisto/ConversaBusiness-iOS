//
//  WhisperBridge.swift
//  Conversa
//
//  Created by Edgar Gomez on 3/25/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

import UIKit
import Whisper

class WhisperBridge : NSObject {

    @objc static let sharedInstance = WhisperBridge()
    var navigationControllers = [UINavigationController]()

    @objc func whisper(_ text: String, backgroundColor: UIColor, toNavigationController: UINavigationController, silenceAfter: TimeInterval)
    {
        let message = Message(title: text, textColor: UIColor.white, backgroundColor: backgroundColor, images: nil)
        show(whisper: message, to: toNavigationController)

        if silenceAfter > 0.1 {
            hide(whisperFrom: toNavigationController, after: silenceAfter)
        }
    }

    @objc func shout(_ text: String, subtitle: String, backgroundColor: UIColor, toNavigationController: UINavigationController, image: UIImage? = nil, silenceAfter: TimeInterval, action: (() -> Void)? = nil)
    {
        let announcement = Announcement(title: text, subtitle: subtitle, image: image)
        show(shout: announcement, to: toNavigationController, completion: action)

        if silenceAfter > 0.1 {
            hide(whisperFrom: toNavigationController, after: silenceAfter)
        }
    }

    @objc func showPermanentShout(_ title: String, titleColor: UIColor, backgroundColor: UIColor, toNavigationController: UINavigationController)
    {
        let index = navigationControllers.index(of: toNavigationController)
        if index != nil {
            return;
        }
        navigationControllers.append(toNavigationController)
        let message = Message(title: title, textColor: titleColor, backgroundColor: backgroundColor, images: nil)
        // Present a permanent message
        show(whisper: message, to: toNavigationController, action: .present)
    }

    @objc func hidePermanentShout(_ toNavigationController: UINavigationController)
    {
        let index = navigationControllers.index(of: toNavigationController)
        if index != nil {
            navigationControllers.remove(at: index!)
            // Hide a permanent message
            hide(whisperFrom: toNavigationController)
        }
    }
    
}

