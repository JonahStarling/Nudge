//
//  SettingsViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/18/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit
import FBSDKLoginKit
import FirebaseDatabase

class SettingsViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var logoutButton: UIButton!
    @IBOutlet var mapPresenceButton: UIButton!
    @IBOutlet var mapPresenceView: UIView!
    
    @IBOutlet var blockedUsersView: UIView!
    @IBOutlet var blockedUsersCollection: UICollectionView!
    @IBOutlet var noUsersBlocked: UILabel!
    
    var blockedUsers: [String] = []
    let ref = FIRDatabase.database().reference(withPath: "users")
    let userId = UserDefaults.standard.string(forKey: "id")
    
    override func viewDidLoad() {
        // Setup
        self.logoutButton.layer.cornerRadius = 5
        self.mapPresenceView.layer.cornerRadius = 5
        self.blockedUsersView.layer.cornerRadius = 5
        self.blockedUsersCollection.layer.cornerRadius = 5
        self.noUsersBlocked.layer.cornerRadius = 5
        self.blockedUsersCollection.delegate = self
        self.blockedUsersCollection.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if UserDefaults.standard.bool(forKey: "mapPresence") == true {
            self.mapPresenceButton.setTitle("ON", for: .normal)
            self.mapPresenceButton.setTitleColor(UIColor(red: 41/255, green: 253/255, blue: 47/255, alpha: 1.0), for: .normal)
        } else {
            self.mapPresenceButton.setTitle("OFF", for: .normal)
            self.mapPresenceButton.setTitleColor(UIColor(red: 196/255, green: 26/255, blue: 22/255, alpha: 1.0), for: .normal)
        }
        super.viewWillAppear(true)
    }
    
    @IBAction func logoutTapped(_ sender: Any) {
        self.logOutUser()
    }
    
    @IBAction func mapPresenceTapped(_ sender: Any) {
        if UserDefaults.standard.bool(forKey: "mapPresence") == true {
            self.mapPresenceButton.setTitle("OFF", for: .normal)
            self.mapPresenceButton.setTitleColor(UIColor(red: 196/255, green: 26/255, blue: 22/255, alpha: 1.0), for: .normal)
            UserDefaults.standard.set(false, forKey: "mapPresence")
        } else {
            self.mapPresenceButton.setTitle("ON", for: .normal)
            self.mapPresenceButton.setTitleColor(UIColor(red: 41/255, green: 253/255, blue: 47/255, alpha: 1.0), for: .normal)
            UserDefaults.standard.set(true, forKey: "mapPresence")
        }
    }
    
    @IBAction func exitTapped(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
    
    func logOutUser() {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        performSegue(withIdentifier: "StartSegue", sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        self.ref.child(self.userId!).child("blocked").observeSingleEvent(of: .value, with: { snapshot in
            self.blockedUsers = []
            for item in snapshot.children {
                let snapshotData = item as! FIRDataSnapshot
                self.blockedUsers.append(snapshotData.key)
            }
            if self.blockedUsers.count != 0 {
                self.blockedUsersCollection.reloadData()
                self.noUsersBlocked.isHidden = true
            } else {
                self.blockedUsersCollection.reloadData()
                self.noUsersBlocked.isHidden = false
            }
        })
        return self.blockedUsers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BlockedCell", for: indexPath) as! BlockedCell
        let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(self.blockedUsers[indexPath.row])/picture?height=320&width=320")
        cell.userImage.kf.setImage(with: facebookProfileUrl)
        cell.userImage.layer.cornerRadius = 35
        cell.userImage.layer.borderWidth = 5
        cell.userImage.layer.borderColor = UIColor.white.cgColor
        return cell
    }
    
    @IBAction func blockedUserTapped(_ sender: UITapGestureRecognizer) {
        let p = sender.location(in: self.blockedUsersCollection)
        if let indexPath = self.blockedUsersCollection.indexPathForItem(at: p) {
            print(self.blockedUsers[indexPath.row])
            let alertController = UIAlertController(title: "Unblock User", message: "Would you like to unblock this user?", preferredStyle: .alert)
            let YesAction = UIAlertAction(title: "Yes", style: .default) { action in
                self.ref.child(self.userId!).child("blocked").child(self.blockedUsers[indexPath.row]).removeValue()
                self.ref.child(self.blockedUsers[indexPath.row]).child("blockedBy").child(self.userId!).removeValue()
            }
            let NoAction = UIAlertAction(title: "No", style: .default) { action in }
            alertController.addAction(YesAction)
            alertController.addAction(NoAction)
            self.present(alertController, animated: true, completion: {})
        }
    }
    
}
