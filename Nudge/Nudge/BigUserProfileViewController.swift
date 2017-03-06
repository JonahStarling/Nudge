//
//  BigUserProfileViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/10/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit
import FirebaseDatabase
import Kingfisher
import AudioToolbox

class BigUserProfileViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var userProfileView: UIView!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var firstName: UILabel!
    @IBOutlet var lastName: UILabel!
    @IBOutlet var age: UILabel!
    @IBOutlet var userBio: UILabel!
    @IBOutlet var statsCollection: UICollectionView!
    @IBOutlet var statsCollectionHeight: NSLayoutConstraint!
    @IBOutlet var blockButton: UIButton!
    @IBOutlet var reportButton: UIButton!
    
    @IBOutlet var imageRoundView: UIView!
    @IBOutlet var outsideView: UIView!
    @IBOutlet var scrollView: UIScrollView!
    
    var selectedUser = ""
    let userId = UserDefaults.standard.string(forKey: "id")
    let ref = FIRDatabase.database().reference(withPath: "users")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // User Profile View Setup
        self.userProfileView.layer.cornerRadius = 25
        // Profile Image
        let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(self.selectedUser)/picture?height=320&width=320")
        self.profileImage.kf.setImage(with: facebookProfileUrl)
        self.profileImage.layer.cornerRadius = 90
        self.profileImage.layer.borderWidth = 8
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            var count = 0
            if let foundCount = snapshot.childSnapshot(forPath: self.userId!).childSnapshot(forPath: "usersNudged").childSnapshot(forPath: self.selectedUser).childSnapshot(forPath: "count").value as? Int {
                count = foundCount
            }
            if count < 3 {
                self.profileImage.layer.borderColor = UIColor.white.cgColor
            } else if count < 50 {
                self.profileImage.layer.borderColor = UIColor(red: 41/255, green: 253/255, blue: 47/255, alpha: 1.0).cgColor
            } else if count < 200 {
                self.profileImage.layer.borderColor = UIColor(red: 250/255, green: 32/255, blue: 201/255, alpha: 1.0).cgColor
            } else {
                self.profileImage.layer.borderColor = UIColor(red: 48/255, green: 250/255, blue: 251/255, alpha: 1.0).cgColor
            }
        })
        self.imageRoundView.layer.cornerRadius = 90
        self.ref.child(self.selectedUser).observe(.value, with: { snapshot in
            // Age
            self.age.text = snapshot.childSnapshot(forPath: "age").value as? String
            // First Name
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
            // Bio
            if let tempBioText = snapshot.childSnapshot(forPath: "bio").value as? String {
                var bioText = tempBioText
                if bioText == "" {
                    bioText = "Everyone deserves a bio. This user thought it would be cool to not put one so we thought we would help out."
                }
                self.userBio.text = bioText
                self.userBio.sizeToFit()
            } else {
                self.userBio.text = "No bio? Mysterious..." 
                self.userBio.sizeToFit()
            }
        })
        // Stats Collection View Setup
        self.statsCollection.delegate = self
        self.statsCollection.dataSource = self
        // Scroll View Setup
        self.scrollView.layer.cornerRadius = 25
        // Block and Report Setup
        self.blockButton.layer.cornerRadius = 5
        self.blockButton.layer.borderColor = UIColor.lightGray.cgColor
        self.blockButton.layer.borderWidth = 1
        self.reportButton.layer.cornerRadius = 5
        self.reportButton.layer.borderColor = UIColor.lightGray.cgColor
        self.reportButton.layer.borderWidth = 1
    }
    
    @IBAction func outsideViewTapped(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
    
    @IBAction func userSwippedDown(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
    
    @IBAction func blockUserPressed(_ sender: Any) {
        self.blockUser()
        let alertController = UIAlertController(title: "User Blocked", message: "This user will no longer be able to see you and you will no longer be able to see them. To unblock this user go to your settings page.", preferredStyle: .alert)
        let OKAction = UIAlertAction(title: "Ok", style: .default) { action in }
        alertController.addAction(OKAction)
        self.present(alertController, animated: true, completion: {})
    }
    
    @IBAction func reportUserPressed(_ sender: Any) {
        let reportRef = FIRDatabase.database().reference(withPath: "reportedUsers")
        let alertController = UIAlertController(title: "Report User", message: "Select what you are reporting this user for.", preferredStyle: .alert)
        let imageReportAction = UIAlertAction(title: "Inappropriate Picture", style: .default) { action in
            self.blockUser()
            reportRef.child(self.selectedUser).setValue("Inappropriate Picture")
            let alertController = UIAlertController(title: "User Reported", message: "This user has been reported for an innapropriate picture and has been blocked. To unblock this user go to your settings page.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "Ok", style: .default) { action in }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: {})
        }
        let bioReportAction = UIAlertAction(title: "Inappropriate Bio/Profile", style: .default) { action in
            self.blockUser()
            reportRef.child(self.selectedUser).setValue("Inappropriate Bio/Profile")
            let alertController = UIAlertController(title: "User Reported", message: "This user has been reported for an innapropriate bio/profile and has been blocked. To unblock this user go to your settings page.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "Ok", style: .default) { action in }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: {})
        }
        let abusiveBehaviorAction = UIAlertAction(title: "Abusive Behavior", style: .default) { action in
            self.blockUser()
            reportRef.child(self.selectedUser).setValue("Abusive Behavior")
            let alertController = UIAlertController(title: "User Reported", message: "This user has been reported for an abusive behavior and has been blocked. To unblock this user go to your settings page.", preferredStyle: .alert)
            let OKAction = UIAlertAction(title: "Ok", style: .default) { action in }
            alertController.addAction(OKAction)
            self.present(alertController, animated: true, completion: {})
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { action in }
        alertController.addAction(imageReportAction)
        alertController.addAction(bioReportAction)
        alertController.addAction(abusiveBehaviorAction)
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true) {}
    }
    
    func blockUser() {
        self.ref.child(self.userId!).child("blocked").child(self.selectedUser).setValue(Int(NSDate().timeIntervalSince1970))
        self.ref.child(self.selectedUser).child("blockedBy").child(self.userId!).setValue(Int(NSDate().timeIntervalSince1970))
    }
    
    @IBAction func profileImageNudge(_ sender: UILongPressGestureRecognizer) {
        self.profileImage.layer.borderWidth = 90
        if sender.state != .ended {
            return
        }
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        self.profileImage.layer.borderWidth = 8
        self.nudgeMainUserLogic()
    }
    
    func nudgeMainUserLogic() {
        // Main User Logic
        self.ref.child(self.userId!).observeSingleEvent(of: .value, with: { snapshot in
            // Get when the last nudge happened
            // Check to see if you have ever nudged this person before
            if snapshot.childSnapshot(forPath: "usersNudged").hasChild(self.selectedUser) {
                if let lastNudge = snapshot.childSnapshot(forPath: "usersNudged").childSnapshot(forPath: self.selectedUser).childSnapshot(forPath: "time").value as? Int,
                    let youNudgedLast = snapshot.childSnapshot(forPath: "usersNudged").childSnapshot(forPath: self.selectedUser).childSnapshot(forPath: "youNudgedLast").value as? Bool {
                    // If it was more than 24 hours --OR-- They were not the last nudge
                    if lastNudge + 86400 <= Int(NSDate().timeIntervalSince1970) || youNudgedLast == false {
                        // Check for the current count
                        if let currentCount = snapshot.childSnapshot(forPath: "usersNudged").childSnapshot(forPath: self.selectedUser).childSnapshot(forPath: "count").value as? Int {
                            print("Successful Nudge")
                            self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("count").setValue(currentCount+1)
                            if let currentHighestStreak = snapshot.childSnapshot(forPath: "highestStreak").value as? Int {
                                if currentHighestStreak < currentCount {
                                    self.ref.child(self.userId!).child("highestStreak").setValue(currentCount)
                                }
                            }
                        } else {
                            print("Firebase Database: count not found")
                            self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("count").setValue(1)
                        }
                        self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("time").setValue(Int(NSDate().timeIntervalSince1970))
                        self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("youNudgedLast").setValue(true)
                        self.ref.child(self.selectedUser).child("usersNudged").child(self.userId!).child("youNudgedLast").setValue(false)
                        // Update the number of nudges they have sent
                        if let sentCount = snapshot.childSnapshot(forPath: "nudgesSent").value as? Int {
                            self.ref.child(self.userId!).child("nudgesSent").setValue(sentCount+1)
                        } else {
                            self.ref.child(self.userId!).child("nudgesSent").setValue(1)
                        }
                        self.nudgeOtherUserLogic()
                    } else {
                        // You nudged them last
                        // You must wait either 24 hours
                        // Or you must wait till they nudge you back
                        print("You can't nudge them yet")
                        // TODO: Print message to user
                        let alertController = UIAlertController(title: "Not Yet", message: "You have to wait 24 hours OR until this user nudges you back.", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
                            //Cool
                        }
                        alertController.addAction(OKAction)
                        self.present(alertController, animated: true, completion: {
                            //Yup
                        })
                    }
                } else {
                    print("Firebase Database: time or youNudgedLast not found")
                    self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("count").setValue(1)
                    self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("time").setValue(Int(NSDate().timeIntervalSince1970))
                    self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("youNudgedLast").setValue(true)
                    self.ref.child(self.selectedUser).child("usersNudged").child(self.userId!).child("youNudgedLast").setValue(false)
                    // Update the number of nudges they have sent
                    if let sentCount = snapshot.childSnapshot(forPath: "nudgesSent").value as? Int {
                        self.ref.child(self.userId!).child("nudgesSent").setValue(sentCount+1)
                    } else {
                        self.ref.child(self.userId!).child("nudgesSent").setValue(1)
                    }
                    self.nudgeOtherUserLogic()
                }
            } else {
                // You've never nudged the person before and this is the first time
                print("firstTimeEver")
                self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("count").setValue(1)
                self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("time").setValue(Int(NSDate().timeIntervalSince1970))
                self.ref.child(self.userId!).child("usersNudged").child(self.selectedUser).child("youNudgedLast").setValue(true)
                self.ref.child(self.selectedUser).child("usersNudged").child(self.userId!).child("youNudgedLast").setValue(false)
                // Update the number of nudges they have sent
                if let sentCount = snapshot.childSnapshot(forPath: "nudgesSent").value as? Int {
                    self.ref.child(self.userId!).child("nudgesSent").setValue(sentCount+1)
                } else {
                    self.ref.child(self.userId!).child("nudgesSent").setValue(1)
                }
                self.nudgeOtherUserLogic()
            }
        })
    }
    
    func nudgeOtherUserLogic() {
        // Other User Logic
        // Update who they've been nudged by recently
        self.ref.child(self.selectedUser).child("recentNudges").child(self.userId!).setValue(Int(NSDate().timeIntervalSince1970))
        self.ref.child(self.selectedUser).observeSingleEvent(of: .value, with: { snapshot in
            if let currentCount = snapshot.childSnapshot(forPath: "nudgesReceived").value as? Int {
                self.ref.child(self.selectedUser).child("nudgesReceived").setValue(currentCount+1)
            } else {
                self.ref.child(self.selectedUser).child("nudgesReceived").setValue(1)
            }
        })
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 4
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "StatCell", for: indexPath) as! StatCell
        cell.roundView.layer.cornerRadius = 20
        cell.roundView.layer.borderWidth = 12
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
        self.ref.child(self.selectedUser).observe(.value, with: { snapshot in
            if indexPath.row == 0 {
                if let sentNudges = snapshot.childSnapshot(forPath: "nudgesSent").value as? Int {
                    cell.number.text = String(sentNudges)
                } else {
                    self.ref.child(self.selectedUser).child("nudgesSent").setValue(0)
                }
            } else if indexPath.row == 1 {
                if let receivedNudges = snapshot.childSnapshot(forPath: "nudgesReceived").value as? Int {
                    cell.number.text = String(receivedNudges)
                } else {
                    self.ref.child(self.selectedUser).child("nudgesReceived").setValue(0)
                }
            } else if indexPath.row == 2 {
                if let highestStreak = snapshot.childSnapshot(forPath: "highestStreak").value as? Int {
                    cell.number.text = String(highestStreak)
                } else {
                    self.ref.child(self.selectedUser).child("highestStreak").setValue(0)
                }
            } else if indexPath.row == 3 {
                cell.number.text = String(snapshot.childSnapshot(forPath: "usersNudged").children.allObjects.count)
            }
        })
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: IndexPath) -> CGSize {
        self.statsCollectionHeight.constant = self.statsCollection.frame.width
        let size = CGSize(width: (self.statsCollection.frame.width/2.0)-0.1, height: (self.statsCollection.frame.width/2.0)-0.1)
        return size
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath) as! StatCell
        self.ref.child(self.selectedUser).observeSingleEvent(of: .value, with: { snapshot in
            if indexPath.row == 0 {
                if cell.number.text == "Nudges Sent" {
                    if let sentNudges = snapshot.childSnapshot(forPath: "nudgesSent").value as? Int {
                        cell.number.text = String(sentNudges)
                    } else {
                        self.ref.child(self.selectedUser).child("nudgesSent").setValue(0)
                    }
                    cell.number.font = cell.number.font.withSize(42)
                } else {
                    cell.number.text = "Nudges Sent"
                    cell.number.font = cell.number.font.withSize(24)
                }
            } else if indexPath.row == 1 {
                if cell.number.text == "Nudges Received" {
                    if let receivedNudges = snapshot.childSnapshot(forPath: "nudgesReceived").value as? Int {
                        cell.number.text = String(receivedNudges)
                    } else {
                        self.ref.child(self.selectedUser).child("nudgesReceived").setValue(0)
                    }
                    cell.number.font = cell.number.font.withSize(42)
                } else {
                    cell.number.text = "Nudges Received"
                    cell.number.font = cell.number.font.withSize(24)
                }
            } else if indexPath.row == 2 {
                if cell.number.text == "Highest Streak" {
                    if let highestStreak = snapshot.childSnapshot(forPath: "highestStreak").value as? Int {
                        cell.number.text = String(highestStreak)
                    } else {
                        self.ref.child(self.selectedUser).child("highestStreak").setValue(0)
                    }
                    cell.number.font = cell.number.font.withSize(42)
                } else {
                    cell.number.text = "Highest Streak"
                    cell.number.font = cell.number.font.withSize(24)
                }
            } else if indexPath.row == 3 {
                if cell.number.text == "Users Reached" {
                    cell.number.text = String(snapshot.childSnapshot(forPath: "usersNudged").children.allObjects.count)
                    cell.number.font = cell.number.font.withSize(42)
                } else {
                    cell.number.text = "Users Reached"
                    cell.number.font = cell.number.font.withSize(24)
                }
            }
        })
    }
}
