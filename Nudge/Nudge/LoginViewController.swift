//
//  LoginViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/12/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit
import GoogleMaps
import FacebookLogin
import FacebookCore
import Firebase
import FirebaseDatabase

class LoginViewController: UIViewController, CLLocationManagerDelegate, LoginButtonDelegate {
    
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup
        self.locationManager.delegate = self
        //self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.requestWhenInUseAuthorization()
        
        let loginButton = LoginButton(readPermissions: [.publicProfile, .email, .userFriends])
        loginButton.center = view.center
        loginButton.delegate = self
        view.addSubview(loginButton)
    }
    
    func loginButtonDidCompleteLogin(_ loginButton: LoginButton, result: LoginResult) {
        switch result {
        case .failed(let error):
            print(error)
        case .cancelled:
            print("User cancelled login.")
        case .success( _, _, _):
            let connection = GraphRequestConnection()
            connection.add(GraphRequest(graphPath: "/me", parameters: ["fields":"name,id"])) { httpResponse, result in
                switch result {
                case .success(let response):
                    print("Graph Request Succeeded: \(response)")
                    let ref = FIRDatabase.database().reference(withPath: "users")
                    let response = response.dictionaryValue
                    let userId = response?["id"] as! String
                    UserDefaults.standard.set(userId, forKey:"id")
                    ref.observeSingleEvent(of: .value, with: { snapshot in
                        if snapshot.hasChild(userId) {
                            self.alreadyExists()
                            UserDefaults.standard.set(true, forKey:"mapPresence")
                            UserDefaults.standard.set(true, forKey: "mapPresenceSet")
                            UserDefaults.standard.set(true, forKey: "termsAccepted")
                        } else {
                            let name = response?["name"] as! String
                            ref.child(userId).child("name").setValue(name as String)
                            let firstName = name.components(separatedBy: " ")[0]
                            let lastName = name.components(separatedBy: " ")[1]
                            ref.child(userId).child("firstName").setValue(firstName)
                            ref.child(userId).child("lastName").setValue(lastName)
                            ref.child(userId).child("lastNameHidden").setValue(false)
                            ref.child(userId).child("lat").setValue(0.0)
                            ref.child(userId).child("lon").setValue(0.0)
                            ref.child(userId).child("hidden").setValue(false)
                            ref.child(userId).child("bio").setValue("No bio? Mysterious...")
                            ref.child(userId).child("age").setValue("21")
                            print(userId)
                            self.finishedDownloading()
                        }
                    })
                case .failed(let error):
                    print("Graph Request Failed: \(error)")
                }
            }
            connection.start()
        }
    }
    
    func finishedDownloading() {
        performSegue(withIdentifier: "AccountCreationSegue", sender: self)
    }
    
    func alreadyExists() {
        performSegue(withIdentifier: "AccountExistsSegue", sender: self)
    }
    
    func loginButtonDidLogOut(_ loginButton: LoginButton) {
        //Nope
        print("logged out")
    }
}
