//
//  CreatorViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/21/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit

class CreatorViewController: UIViewController {
    
    @IBOutlet var jonahImage: UIImageView!
    @IBOutlet var johnImage: UIImageView!
    @IBOutlet var nickImage: UIImageView!
    @IBOutlet var tolanImage: UIImageView!
    @IBOutlet var frederickImage: UIImageView!
    
    override func viewDidLoad() {
        // Setup
        self.jonahImage.layer.cornerRadius = 50
        self.johnImage.layer.cornerRadius = 50
        self.nickImage.layer.cornerRadius = 50
        self.tolanImage.layer.cornerRadius = 50
        self.frederickImage.layer.cornerRadius = 50
    }
    
    @IBAction func exitTapped(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
    
    @IBAction func sevenTapDev(_ sender: UITapGestureRecognizer) {
        if UserDefaults.standard.bool(forKey: "dev") == true {
            UserDefaults.standard.set(false, forKey: "dev")
            print("DEV MODE OFF")
        } else {
            UserDefaults.standard.set(true, forKey: "dev")
            print("DEV MODE ON")
        }
    }
}
