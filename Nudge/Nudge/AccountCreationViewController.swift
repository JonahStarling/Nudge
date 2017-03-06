//
//  AccountCreationViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/17/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FBSDKLoginKit

class AccountCreationViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet var firstName: UITextField!
    @IBOutlet var lastName: UITextField!
    @IBOutlet var age: UITextField!
    
    let ref = FIRDatabase.database().reference().child("users")
    let banRef = FIRDatabase.database().reference().child("bannedUsers")
    var userId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.userId = UserDefaults.standard.string(forKey: "id")!
        self.hideKeyboardWhenTappedAround()
        self.firstName.delegate = self
        self.firstName.layer.cornerRadius = 5
        self.lastName.delegate = self
        self.lastName.layer.cornerRadius = 5
        self.age.delegate = self
        self.age.layer.cornerRadius = 5
        self.banRef.observeSingleEvent(of: .value, with: { snapshot in
            var found = false
            for item in snapshot.children {
                let data = item as! FIRDataSnapshot
                if data.key == self.userId {
                    found = true
                }
            }
            if found == true {
                let alertController = UIAlertController(title: "You have been banned", message: "You have been caught breaking our terms of use. Please contact help@simplynudge.com for more information.", preferredStyle: .alert)
                let OKAction = UIAlertAction(title: "OK", style: .default) { action in
                    self.logOutUser()
                    self.performInvalidSegue()
                }
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: {})
            }
        })
    }
    
    func performInvalidSegue() {
        performSegue(withIdentifier: "InvalidAgeSegue", sender: self)
    }
    
    @IBAction func finishedTapped(_ sender: Any) {
        if self.firstName.text == "" || self.age.text == "" {
            let alertController = UIAlertController(title: "Not Finished", message: "You must put in at least your first name and age.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) {action in}
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: {})
        } else if Int(self.age.text!)! < 13 {
            let alertController = UIAlertController(title: "Woah There", message: "Children under the age of 13 are not allowed. You are now being logged out.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "OK", style: .default) { action in
                self.logOutUser()
            }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: {})
        } else {
            ref.child(userId).child("firstName").setValue(self.firstName.text)
            ref.child(userId).child("lastName").setValue(self.lastName.text)
            ref.child(userId).child("age").setValue(self.age.text)
            performSegue(withIdentifier: "BioSegue", sender: self)
        }
    }
    
    func logOutUser() {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
}

extension UIViewController {
    func hideKeyboardWhenTappedAround() {
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
}
