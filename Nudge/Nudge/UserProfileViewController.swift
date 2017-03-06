//
//  UserProfileViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/12/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import Kingfisher
import FBSDKLoginKit

class UserProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UITextFieldDelegate, UITextViewDelegate {
    
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var age: UILabel!
    @IBOutlet var firstName: UILabel!
    @IBOutlet var lastName: UILabel!
    @IBOutlet var bio: UILabel!
    
    @IBOutlet var statsCollection: UICollectionView!
    @IBOutlet var greenLevelCollection: UICollectionView!
    @IBOutlet var greenLevelMessage: UIView!
    @IBOutlet var pinkLevelCollection: UICollectionView!
    @IBOutlet var pinkLevelMessage: UIView!
    @IBOutlet var blueLevelConnection: UICollectionView!
    @IBOutlet var blueLevelMessage: UIView!
    
    @IBOutlet var settingsButton: UIButton!
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var closeButton: UIButton!
    
    @IBOutlet var bioEdit: UITextView!
    @IBOutlet var ageEdit: UITextField!
    @IBOutlet var firstEdit: UITextField!
    @IBOutlet var lastEdit: UITextField!
    
    @IBOutlet var bioSpacing: NSLayoutConstraint!
    @IBOutlet var bioEditSpacing: NSLayoutConstraint!
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var contentView: UIView!
    
    let ref = FIRDatabase.database().reference(withPath: "users")
    let userId = UserDefaults.standard.string(forKey: "id")
    var editMode = false
    var greenUsers:[String] = []
    var pinkUsers:[String] = []
    var blueUsers:[String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideKeyboardWhenTappedAround()
        // Profile Image Setup
        self.profileImage.layer.cornerRadius = 90
        self.profileImage.layer.borderWidth = 5
        self.profileImage.layer.borderColor = UIColor.white.cgColor
        let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(self.userId!)/picture?height=320&width=320")
        self.profileImage.kf.setImage(with: facebookProfileUrl)
        self.ref.child(self.userId!).observe(.value, with: { snapshot in
            if let firstNameText = snapshot.childSnapshot(forPath: "firstName").value as? String {
                if firstNameText == "" {
                    self.firstName.text = snapshot.childSnapshot(forPath: "name").value as? String
                    self.firstName.sizeToFit()
                    self.firstName.font = self.firstName.font.withSize(48)
                } else {
                    self.firstName.text = firstNameText
                }
            } else {
                self.firstName.text = snapshot.childSnapshot(forPath: "name").value as? String
                self.firstName.sizeToFit()
                self.firstName.font = self.firstName.font.withSize(48)
            }
            // Last Name
            if let lastNameHidden = snapshot.childSnapshot(forPath: "lastNameHidden").value as? Bool {
                if lastNameHidden == false {
                    self.lastName.text = snapshot.childSnapshot(forPath: "lastName").value as? String
                }
            } else {
                self.lastName.text = snapshot.childSnapshot(forPath: "lastName").value as? String
            }
            // Age
            self.age.text = snapshot.childSnapshot(forPath: "age").value as? String
            // Bio
            if let bioText = snapshot.childSnapshot(forPath: "bio").value as? String {
                self.bio.text = bioText
                self.bio.sizeToFit()
            } else {
                self.bio.text = "No bio? Mysterious..."
                self.bio.sizeToFit()
            }
        })
        // Stats Collection
        self.statsCollection.delegate = self
        self.statsCollection.dataSource = self
        // Scroll View Setup
        self.scrollView.layer.cornerRadius = 20
        // Nudgeship Views Setup
        self.greenLevelCollection.delegate = self
        self.greenLevelCollection.dataSource = self
        self.pinkLevelCollection.delegate = self
        self.pinkLevelCollection.dataSource = self
        self.blueLevelConnection.delegate = self
        self.blueLevelConnection.dataSource = self
        // Edit View Setup
        self.firstEdit.layer.cornerRadius = 5
        self.firstEdit.delegate = self
        self.lastEdit.layer.cornerRadius = 5
        self.lastEdit.delegate = self
        self.ageEdit.layer.cornerRadius = 5
        self.ageEdit.delegate = self
        self.bioEdit.layer.cornerRadius = 5
        self.bioEdit.delegate = self
    }
    
    @IBAction func closeButtonTapped(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
    
    @IBAction func infoButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "AboutSegue", sender: self)
    }
    
    @IBAction func settingsButtonTapped(_ sender: Any) {
        performSegue(withIdentifier: "SettingsSegue", sender: self)
    }
    
    @IBAction func editButtonTapped(_ sender: Any) {
        if self.editMode {
            // Move Bio
            self.bioSpacing.priority = 800
            self.bioEditSpacing.priority = 700
            // Enable Other Buttons
            self.closeButton.isEnabled = true
            self.settingsButton.isEnabled = true
            self.infoButton.isEnabled = true
            // First Name
            self.firstEdit.isHidden = true
            self.firstName.isHidden = false
            ref.child(userId!).child("firstName").setValue(self.firstEdit.text)
            // Last Name
            self.lastEdit.isHidden = true
            self.lastName.isHidden = false
            ref.child(userId!).child("lastName").setValue(self.lastEdit.text)
            // Age
            self.ageEdit.isHidden = true
            self.age.isHidden = false
            if Int(self.ageEdit.text!)! < 13 {
                let alertController = UIAlertController(title: "Woah There", message: "Are you sure you put in your age correctly?", preferredStyle: .alert)
                let YesAction = UIAlertAction(title: "YES", style: .default) { action in
                    let alertController = UIAlertController(title: "Goodbye", message: "Children under the age of 13 are not allowed. You are now being logged out.", preferredStyle: .alert)
                    let OKAction = UIAlertAction(title: "OK", style: .default) { action in
                        self.logOutUser()
                    }
                    alertController.addAction(OKAction)
                    self.present(alertController, animated: true, completion: {})
                }
                let NoAction = UIAlertAction(title: "NO", style: .default) { action in }
                alertController.addAction(YesAction)
                alertController.addAction(NoAction)
                self.present(alertController, animated: true, completion: {})
            } else {
                ref.child(userId!).child("age").setValue(self.ageEdit.text)
            }
            // Bio
            self.bioEdit.isHidden = true
            self.bio.isHidden = false
            ref.child(userId!).child("bio").setValue(self.bioEdit.text)
            // Change Mode
            self.editMode = false
        } else {
            // Move Bio
            self.bioSpacing.priority = 700
            self.bioEditSpacing.priority = 800
            // Disable other buttons
            self.closeButton.isEnabled = false
            self.settingsButton.isEnabled = false
            self.infoButton.isEnabled = false
            // First Name
            self.firstEdit.isHidden = false
            self.firstName.isHidden = true
            self.firstEdit.text = self.firstName.text
            // Last Name
            self.lastEdit.isHidden = false
            self.lastName.isHidden = true
            self.lastEdit.text = self.lastName.text
            // Age
            self.ageEdit.isHidden = false
            self.age.isHidden = true
            self.ageEdit.text = self.age.text
            // Bio
            self.bioEdit.isHidden = false
            self.bio.isHidden = true
            self.bioEdit.text = self.bio.text
            self.editMode = true
        }
    }
    
    func logOutUser() {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        performSegue(withIdentifier: "InvalidUserAgeSegue", sender: self)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == self.statsCollection {
            return 4
        } else if collectionView == self.greenLevelCollection {
            self.ref.child(self.userId!).child("usersNudged").observeSingleEvent(of: .value, with: { snapshot in
                self.greenUsers = []
                for item in snapshot.children {
                    let snapshotData = item as! FIRDataSnapshot
                    if let nudgeCount = snapshotData.childSnapshot(forPath: "count").value as? Int {
                        if nudgeCount > 2 && nudgeCount <= 49 {
                            self.greenUsers.append(snapshotData.key)
                        }
                    }
                }
                if self.greenUsers.count != 0 {
                    self.greenLevelMessage.isHidden = true
                    self.greenLevelCollection.reloadData()
                } else {
                    self.greenLevelMessage.isHidden = false
                }
            })
            return self.greenUsers.count
        } else if collectionView == self.pinkLevelCollection {
            self.ref.child(self.userId!).child("usersNudged").observeSingleEvent(of: .value, with: { snapshot in
                self.pinkUsers = []
                for item in snapshot.children {
                    let snapshotData = item as! FIRDataSnapshot
                    if let nudgeCount = snapshotData.childSnapshot(forPath: "count").value as? Int {
                        if nudgeCount > 49 && nudgeCount <= 199 {
                            self.pinkUsers.append(snapshotData.key)
                        }
                    }
                }
                if self.pinkUsers.count != 0 {
                    self.pinkLevelMessage.isHidden = true
                    self.pinkLevelCollection.reloadData()
                } else {
                    self.pinkLevelMessage.isHidden = false
                }
            })
            return self.pinkUsers.count
        } else if collectionView == self.blueLevelConnection {
            self.ref.child(self.userId!).child("usersNudged").observeSingleEvent(of: .value, with: { snapshot in
                self.blueUsers = []
                for item in snapshot.children {
                    let snapshotData = item as! FIRDataSnapshot
                    if let nudgeCount = snapshotData.childSnapshot(forPath: "count").value as? Int {
                        if nudgeCount > 199 {
                            self.blueUsers.append(snapshotData.key)
                        }
                    }
                }
                if self.blueUsers.count != 0 {
                    self.blueLevelMessage.isHidden = true
                    self.blueLevelConnection.reloadData()
                } else {
                    self.blueLevelMessage.isHidden = false
                }
            })
            return self.blueUsers.count
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == self.statsCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatCell", for: indexPath) as! StatCell
            cell.roundView.layer.cornerRadius = 20
            cell.roundView.layer.borderWidth = 5
            if indexPath.row == 0 {
                cell.roundView.layer.borderColor = UIColor(red: 41/255, green: 253/255, blue: 47/255, alpha: 1.0).cgColor
                cell.statView.backgroundColor = UIColor(red: 41/255, green: 253/255, blue: 47/255, alpha: 1.0)
            } else if indexPath.row == 1 {
                cell.roundView.layer.borderColor = UIColor(red: 250/255, green: 32/255, blue: 201/255, alpha: 1.0).cgColor
                cell.statView.backgroundColor = UIColor(red: 250/255, green: 32/255, blue: 201/255, alpha: 1.0)
            } else if indexPath.row == 2 {
                cell.roundView.layer.borderColor = UIColor(red: 48/255, green: 250/255, blue: 251/255, alpha: 1.0).cgColor
                cell.statView.backgroundColor = UIColor(red: 48/255, green: 250/255, blue: 251/255, alpha: 1.0)
            } else {
                cell.roundView.layer.borderColor = UIColor.white.cgColor
                cell.statView.backgroundColor = UIColor.white
            }
            self.ref.child(self.userId!).observe(.value, with: { snapshot in
                if indexPath.row == 0 {
                    if let sentNudges = snapshot.childSnapshot(forPath: "nudgesSent").value as? Int {
                        cell.number.text = String(sentNudges)
                    } else {
                        self.ref.child(self.userId!).child("nudgesSent").setValue(0)
                    }
                } else if indexPath.row == 1 {
                    if let receivedNudges = snapshot.childSnapshot(forPath: "nudgesReceived").value as? Int {
                        cell.number.text = String(receivedNudges)
                    } else {
                        self.ref.child(self.userId!).child("nudgesReceived").setValue(0)
                    }
                } else if indexPath.row == 2 {
                    if let highestStreak = snapshot.childSnapshot(forPath: "highestStreak").value as? Int {
                        cell.number.text = String(highestStreak)
                    } else {
                        self.ref.child(self.userId!).child("highestStreak").setValue(0)
                    }
                } else if indexPath.row == 3 {
                    cell.number.text = String(snapshot.childSnapshot(forPath: "usersNudged").children.allObjects.count)
                }
            })
            return cell
        } else if collectionView == self.greenLevelCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GreenLevelCell", for: indexPath) as! GreenLevelCell
            let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(self.greenUsers[indexPath.row])/picture?height=320&width=320")
            cell.profileImage.kf.setImage(with: facebookProfileUrl)
            cell.profileImage.layer.cornerRadius = 48
            cell.profileImage.layer.borderWidth = 5
            cell.profileImage.layer.borderColor = UIColor.lightGray.cgColor
            return cell
        } else if collectionView == self.pinkLevelCollection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PinkLevelCell", for: indexPath) as! PinkLevelCell
            let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(self.pinkUsers[indexPath.row])/picture?height=320&width=320")
            cell.profileImage.kf.setImage(with: facebookProfileUrl)
            cell.profileImage.layer.cornerRadius = 48
            cell.profileImage.layer.borderWidth = 5
            cell.profileImage.layer.borderColor = UIColor.lightGray.cgColor
            return cell
        } else if collectionView == self.blueLevelConnection {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BlueLevelCell", for: indexPath) as! BlueLevelCell
            let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(self.blueUsers[indexPath.row])/picture?height=320&width=320")
            cell.profileImage.kf.setImage(with: facebookProfileUrl)
            cell.profileImage.layer.cornerRadius = 48
            cell.profileImage.layer.borderWidth = 5
            cell.profileImage.layer.borderColor = UIColor.lightGray.cgColor
            return cell
        } else {
            return UICollectionViewCell()
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        if collectionView == self.statsCollection {
            let size = CGSize(width: (self.statsCollection.frame.width/4.0)-0.1, height: (self.statsCollection.frame.width/4.0)-0.1)
            return size
        } else {
            return CGSize(width: 108, height: 108)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        if collectionView == self.statsCollection {
            let cell = collectionView.cellForItem(at: indexPath) as! StatCell
            self.ref.child(self.userId!).observe(.value, with: { snapshot in
                if indexPath.row == 0 {
                    if cell.number.text == "Nudges Sent" {
                        if let sentNudges = snapshot.childSnapshot(forPath: "nudgesSent").value as? Int {
                            cell.number.text = String(sentNudges)
                        } else {
                            self.ref.child(self.userId!).child("nudgesSent").setValue(0)
                        }
                        cell.number.font = cell.number.font.withSize(21)
                    } else {
                        cell.number.text = "Nudges Sent"
                        cell.number.font = cell.number.font.withSize(12)
                    }
                } else if indexPath.row == 1 {
                    if cell.number.text == "Nudges Received" {
                        if let receivedNudges = snapshot.childSnapshot(forPath: "nudgesReceived").value as? Int {
                            cell.number.text = String(receivedNudges)
                        } else {
                            self.ref.child(self.userId!).child("nudgesReceived").setValue(0)
                        }
                        cell.number.font = cell.number.font.withSize(21)
                    } else {
                        cell.number.text = "Nudges Received"
                        cell.number.font = cell.number.font.withSize(12)
                    }
                } else if indexPath.row == 2 {
                    if cell.number.text == "Highest Streak" {
                        if let highestStreak = snapshot.childSnapshot(forPath: "highestStreak").value as? Int {
                            cell.number.text = String(highestStreak)
                        } else {
                            self.ref.child(self.userId!).child("highestStreak").setValue(0)
                        }
                        cell.number.font = cell.number.font.withSize(21)
                    } else {
                        cell.number.text = "Highest Streak"
                        cell.number.font = cell.number.font.withSize(12)
                    }
                } else if indexPath.row == 3 {
                    if cell.number.text == "People Nudged" {
                        cell.number.text = String(snapshot.childSnapshot(forPath: "usersNudged").children.allObjects.count)
                        cell.number.font = cell.number.font.withSize(21)
                    } else {
                        cell.number.text = "People Nudged"
                        cell.number.font = cell.number.font.withSize(12)
                    }
                }
            })
        }
    }
}
