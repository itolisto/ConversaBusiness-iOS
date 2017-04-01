//
//  ContentViewController.swift
//  UIPageViewController
//
//  Created by PJ Vea on 3/27/15.
//  Copyright (c) 2015 Vea Software. All rights reserved.
//

import UIKit

class ContentViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var infoTextView: UILabel!
    @IBOutlet weak var viewBackground: UIView!
    
    var pageIndex: Int!
    var titleText: String!
    var imageFile: String!
    var infoText:  String!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = UIImage(named: self.imageFile)
        self.titleLabel.text = self.titleText
        self.infoTextView.text = infoText
    }
    
}
