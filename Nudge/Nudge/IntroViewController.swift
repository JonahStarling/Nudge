//
//  IntroViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/16/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit

class IntroViewController: UIViewController {
    
    @IBOutlet var titleText: UILabel!
    @IBOutlet var mainText: UILabel!
    @IBOutlet var button: UIButton!
    @IBOutlet var backView: UIView!
    
    var i = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func nextPressed(_ sender: Any) {
        if i == 1 {
            self.titleText.text = "How do you Nudge?"
            self.mainText.text = "Simply hold down on someone's picture."
            self.backView.backgroundColor = UIColor(red: 250/255, green: 32/255, blue: 201/255, alpha: 1.0)
            i = 2
        } else if i == 2 {
            self.titleText.text = "Why Nudge?"
            self.mainText.text = "In this increasingly digital world it's time to start interacting."
            self.button.setTitle("Let's Begin!", for: .normal)
            self.backView.backgroundColor = UIColor(red: 48/255, green: 250/255, blue: 251/255, alpha: 1.0)
            i = 3
        } else {
            performSegue(withIdentifier: "IntroCompleteSegue", sender: self)
        }
    }
}
