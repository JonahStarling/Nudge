//
//  MapPresenceViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/27/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit

class MapPresenceViewController: UIViewController {
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func acceptedMapPresence(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "mapPresence")
        UserDefaults.standard.set(true, forKey: "mapPresenceSet")
        performSegue(withIdentifier: "MapPresenceSegue", sender: self)
    }
    
    @IBAction func deniedMapPresence(_ sender: Any) {
        let alertController = UIAlertController(title: "Are you sure?", message: "Saying no means you won't be able to see anyone and they won't be able to see you.", preferredStyle: .alert)
        let YesAction = UIAlertAction(title: "Yes", style: .default) { action in
            UserDefaults.standard.set(false, forKey: "mapPresence")
            UserDefaults.standard.set(true, forKey: "mapPresenceSet")
            let alertController = UIAlertController(title: "You will not be shown", message: "You can change this setting at anytime by going to the settings screen on your profile.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { action in
                self.performMapPresenceSegue()
            }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: {})
        }
        let NoAction = UIAlertAction(title: "No", style: .default) { action in
            //do nothing
        }
        alertController.addAction(YesAction)
        alertController.addAction(NoAction)
        self.present(alertController, animated: true, completion: {})
    }
    
    func performMapPresenceSegue() {
        performSegue(withIdentifier: "MapPresenceSegue", sender: self)
    }
}
