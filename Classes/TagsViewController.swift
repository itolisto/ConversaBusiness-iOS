//
//  TagsViewController.swift
//  ConversaBusiness
//
//  Created by Edgar Gomez on 3/26/16.
//  Copyright © 2016 Conversa. All rights reserved.
//

import UIKit
import Parse
import TFBubbleItUp

class TagsViewController: UIViewController, TFBubbleItUpViewDelegate {
    
    @IBOutlet var bubbleItUpView: TFBubbleItUpView!
    var tags : NSArray = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // Set bubbleItUpDelegate delegate
        self.bubbleItUpView.bubbleItUpDelegate = self
        self.bubbleItUpView.setPlaceholderText("")
        let validation = TFBubbleItUpValidation.testEmptiness()
        TFBubbleItUpViewConfiguration.itemValidation = validation
        TFBubbleItUpViewConfiguration.numberOfItems = .Quantity(5)
        TFBubbleItUpViewConfiguration.keyboardType = UIKeyboardType.Alphabet
        TFBubbleItUpViewConfiguration.autoCapitalization = UITextAutocapitalizationType.None
        
//        self.bubbleItUpView.addStringItem("ales@thefuntasty.com")
//        self.bubbleItUpView.removeStringItem("ales@thefuntasty.com")
//        self.textLabel.text = view.validStrings().joinWithSeparator(", ")
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        DatabaseManager.sharedInstance().newConnection().asyncReadWithBlock({ (transaction) in
            self.tags = YapTag.getAllTagsWithTransaction(transaction);
            }) {
                for(tag) in self.tags {
                    self.bubbleItUpView.addStringItem(tag.tag)
                }
        }
    }
    
    // MARK:- TFBubbleItUpDelegate
    func bubbleItUpViewDidFinishEditingBubble(view: TFBubbleItUpView, text: String, index: Int) {
        NSLog("\nbubbleItUpViewDidFinishEditingBubble text:  %@", text)
        NSLog("\nbubbleItUpViewDidFinishEditingBubble index: %i", index)
        if text.characters.count > 0 {
//            DatabaseManager.sharedInstance().newConnection().asyncReadWriteWithBlock({ (transaction) in
//                let newTag : YapTag = YapTag(uniqueId: NSUUID().UUIDString)
//                newTag.tag = text
//                newTag.accountUniqueId = Account.currentUser()?.objectId
//                newTag.saveWithTransaction(transaction)
//                }
//            )
        }
    }
    
    func bubbleItUpViewDidDeleteBubbles(view: TFBubbleItUpView, text: String, actualIndex: Int, otherIndex: Int) {
        if otherIndex == -1 {
            // Only one tag deleted
            NSLog("\nbubbleItUpViewDidDeleteBubbles 1index: %i", actualIndex)
            NSLog("\nbubbleItUpViewDidDeleteBubbles 2index: %i", otherIndex)
        } else {
            // Two tags deleted
            NSLog("\nbubbleItUpViewDidDeleteBubbles 1index: %i", actualIndex)
            NSLog("\nbubbleItUpViewDidDeleteBubbles 2index: %i", otherIndex)
        }
    }
    
}