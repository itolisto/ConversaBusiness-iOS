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
        //self.titleLabel.textColor = Colors.blackColor()
        self.infoTextView.text = infoText
        self.viewBackground.backgroundColor = UIColor(red: 0.22, green: 1.00, blue: 0.47, alpha: 1.0)
    }
    
}
