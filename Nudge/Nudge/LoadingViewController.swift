//
//  LoadingViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/12/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin

class LoadingViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set(false, forKey: "dev")
        // Add code to check preferences to see if the user has logged in
        // If logged in then send to main map
        // Otherwise send them to the login
        // For now, send straight to login
        
    }
    override func viewDidAppear(_ animated: Bool) {
        if let accessToken = AccessToken.current,
            let userId = UserDefaults.standard.string(forKey: "id") {
            // User is logged in, use 'accessToken' here.
            print(userId)
            print(accessToken)
            if userId != "" {
                if UserDefaults.standard.bool(forKey: "termsAccepted") == false {
                    self.performTermSegue()
                } else {
                    if UserDefaults.standard.bool(forKey: "mapPresenceSet") == false {
                        self.performMapPresenceSegue()
                    } else {
                        self.performLoggedInSegue()
                    }
                }
            } else {
                self.performNotLoggedInSegue()
            }
        } else {
            performSegue(withIdentifier: "NotLoggedInSegue", sender: self)
        }
    }

    func performTermSegue() {
        performSegue(withIdentifier: "TermsNotFinishedSegue", sender: self)
    }
    
    func performNotLoggedInSegue() {
        performSegue(withIdentifier: "NotLoggedInSegue", sender: self)
    }
    
    func performLoggedInSegue() {
        performSegue(withIdentifier: "LoggedInSegue", sender: self)
    }
    
    func performMapPresenceSegue() {
        performSegue(withIdentifier: "MapPresenceNotSetSegue", sender: self)
    }
}
