//
//  MapViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 10/19/16.
//  Copyright © 2016 In The Belly. All rights reserved.
//

import UIKit
import GoogleMaps
import FirebaseDatabase
import FacebookCore
import Kingfisher
import AudioToolbox
import FBSDKLoginKit

class MapViewController: UIViewController, GMSMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource, UICollectionViewDelegate, UICollectionViewDataSource {
    
    @IBOutlet var mapView: GMSMapView!
    
    @IBOutlet var topView: UIView!
    @IBOutlet var numberOfRecentNudges: UILabel!
    
    @IBOutlet var nudgeListButton: UIButton!
    @IBOutlet var nudgeListView: UIView!
    @IBOutlet var nudgeTableView: UITableView!
    @IBOutlet var noNudgesLabel: UILabel!
    
    @IBOutlet var profileButton: UIButton!
    @IBOutlet var privacyButton: UIButton!
    @IBOutlet var privacyView: UIView!
    
    @IBOutlet var mapPresenceView: UIView!
    
    @IBOutlet var goLiveView: UIView!
    
    @IBOutlet var userView: UIView!
    @IBOutlet var userViewHeight: NSLayoutConstraint!
    @IBOutlet var userCollection: UICollectionView!
    @IBOutlet var noUsersView: UIView!
    
    @IBOutlet var smallProfileView: UIView!
    @IBOutlet var smallProfileViewHeight: NSLayoutConstraint!
    @IBOutlet var profileImage: UIImageView!
    @IBOutlet var firstName: UILabel!
    @IBOutlet var lastName: UILabel!
    @IBOutlet var age: UILabel!
    
    var nudgeListOpen = false
    var initialNudgeListViewHeight = CGFloat(0)
    var initialSmallProfileViewHeight = CGFloat(0)
    var initialUserViewHeight = CGFloat(0)
    var privacyStatus = false
    var selectedUser = ""
    let userId = UserDefaults.standard.string(forKey: "id")
    var usersInArea: [String] = []
    var recentNudges: [String:Int] = [:]
    var userLive = false
    var blockedUsers: [String] = []
    var blockedByUsers: [String] = []
    
    let locationManager = CLLocationManager()
    let ref = FIRDatabase.database().reference(withPath: "users")
    let banRef = FIRDatabase.database().reference(withPath: "bannedUsers")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.set(false, forKey: "dev")
        // Privacy Setup
        self.privacyView.isHidden = true
        // Small Profile View Setup
        self.initialSmallProfileViewHeight = self.smallProfileViewHeight.constant
        self.smallProfileViewHeight.constant = 0
        // User View Setup
        self.initialUserViewHeight = self.userViewHeight.constant
        self.userCollection.delegate = self
        self.userCollection.dataSource = self
        // Nudge List View Setup
        self.nudgeListView.isHidden = true
        self.nudgeTableView.dataSource = self
        self.nudgeTableView.delegate = self
        // Recent Nudge Count
        self.numberOfRecentNudges.layer.cornerRadius = 12
        self.numberOfRecentNudges.layer.borderWidth = 2
        self.numberOfRecentNudges.layer.borderColor = UIColor.white.cgColor
        // Location Manager Setup
        self.locationManager.delegate = self
        //self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = 3
        self.locationManager.startUpdatingLocation()
        // Map View Setup
        self.mapView.delegate = self
        self.mapView.isMyLocationEnabled = true
        self.mapView.settings.scrollGestures = false
        self.mapView.settings.rotateGestures = true
        self.mapView.settings.tiltGestures = false
        self.mapView.settings.zoomGestures = true
        self.mapView.settings.compassButton = true
        self.mapView.isIndoorEnabled = false
        self.mapView.setMinZoom(17.0, maxZoom: 20.0)
        if (self.userId! == "10207886730035668" && UserDefaults.standard.bool(forKey: "dev") == true) {
            self.mapView.setMinZoom(1.0, maxZoom: 20.0)
            self.mapView.settings.scrollGestures = true
            self.mapView.settings.myLocationButton = true
        }
        self.mapView.animate(toZoom: 18.0)
        // Try to stylize the map to our custom dark look
        do {
            if let styleURL = Bundle.main.url(forResource: "mapstyle", withExtension: "json") {
                mapView.mapStyle = try GMSMapStyle(contentsOfFileURL: styleURL)
            } else {
                NSLog("Unable to find mapstyle.json")
            }
        } catch {
            NSLog("The style definition could not be loaded: \(error)")
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        // Get recent nudges
        self.ref.child(userId!).observe(.value, with: { snapshot in
            var highVal = 0
            for item in snapshot.childSnapshot(forPath: "recentNudges").children {
                let snapshotData = item as! FIRDataSnapshot
                if let count = snapshotData.value as? Int {
                    self.recentNudges[snapshotData.key] = count
                    if highVal < count {
                        highVal = count
                    }
                }
                
            }
            // Update number of new nudges text
            if self.recentNudges.count == 0 {
                self.numberOfRecentNudges.text = ""
                self.numberOfRecentNudges.isHidden = true
            } else {
                self.numberOfRecentNudges.isHidden = false
                self.numberOfRecentNudges.text = String(self.recentNudges.count)
            }
            self.nudgeTableView.reloadData()
        })
        if self.userLive == false {
            self.nudgeListButton.isEnabled = false
            self.privacyButton.isEnabled = false
        } else {
            self.startObserving()
        }
        self.ref.child(self.userId!).child("live").observe(.value, with: { snapshot in
            if let live = snapshot.value as? Bool {
                self.userLive = live
                if live == false {
                    self.goLiveView.isHidden = false
                    self.privacyButton.isEnabled = false
                    self.nudgeListButton.isEnabled = false
                }
            }
        })
        self.banRef.observe(.value, with: { snapshot in
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
                    self.performBannedSegue()
                }
                alertController.addAction(OKAction)
                self.present(alertController, animated: true, completion: {})
            }
        })
        self.ref.child(self.userId!).observeSingleEvent(of: .value, with: { snapshot in
            for blockedUser in snapshot.childSnapshot(forPath: "blocked").children {
                let blockedUserData = blockedUser as! FIRDataSnapshot
                self.blockedUsers.append(blockedUserData.key)
            }
            for blockedByUser in snapshot.childSnapshot(forPath: "blockedBy").children {
                let blockedByUserData = blockedByUser as! FIRDataSnapshot
                self.blockedByUsers.append(blockedByUserData.key)
            }
        })
        if UserDefaults.standard.bool(forKey: "mapPresence") == true {
            self.mapPresenceView.isHidden = true
            self.privacyButton.isEnabled = true
            self.nudgeListButton.isEnabled = true
            if (self.userId! == "10207886730035668" && UserDefaults.standard.bool(forKey: "dev") == true) {
                self.mapView.setMinZoom(1.0, maxZoom: 20.0)
                self.mapView.settings.scrollGestures = true
                self.mapView.settings.myLocationButton = true
                self.startObserving()
            } else if (self.userId! == "10207886730035668" && UserDefaults.standard.bool(forKey: "dev") == false) {
                self.mapView.setMinZoom(17.0, maxZoom: 20.0)
                self.mapView.settings.scrollGestures = false
                self.mapView.settings.myLocationButton = false
                let locationValue:CLLocationCoordinate2D = self.locationManager.location!.coordinate
                self.ref.child(self.userId!).child("lat").setValue(locationValue.latitude)
                self.ref.child(self.userId!).child("lon").setValue(locationValue.longitude)
                self.mapView.animate(toLocation: locationValue)
            }
            
        } else {
            self.mapPresenceView.isHidden = false
            self.privacyButton.isEnabled = false
            self.nudgeListButton.isEnabled = false
        }
        super.viewWillAppear(true)
    }
    
    override func viewWillLayoutSubviews() {
        if self.userLive == false {
            self.nudgeListButton.isEnabled = false
            self.privacyButton.isEnabled = false
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        self.ref.removeAllObservers()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "BigUserProfileSegue" {
            if let destination = segue.destination as? BigUserProfileViewController {
                destination.selectedUser = self.selectedUser
            }
        }
    }
    
    @IBAction func profileButton(_ sender: Any) {
        if self.smallProfileViewHeight.constant != CGFloat(0) {
            self.smallProfileViewHeight.constant = 0
            self.userViewHeight.constant = self.initialUserViewHeight
            self.selectedUser = ""
        }
        performSegue(withIdentifier: "UserProfileSegue", sender: self)
    }
    
    @IBAction func nudgeListButton(_ sender: Any) {
        if self.nudgeListOpen {
            self.noNudgesLabel.isHidden = true
            self.nudgeListView.isHidden = true
            self.nudgeListOpen = false
        } else {
            if self.smallProfileViewHeight.constant != CGFloat(0) {
                self.smallProfileViewHeight.constant = 0
                self.userViewHeight.constant = self.initialUserViewHeight
                self.selectedUser = ""
            }
            if self.recentNudges.count == 0 {
                self.noNudgesLabel.isHidden = false
            } else {
                self.noNudgesLabel.isHidden = true
            }
            self.nudgeListView.isHidden = false
            self.nudgeListOpen = true
        }
    }
    
    @IBAction func privacyButton(_ sender: Any) {
        if self.privacyStatus {
            self.privacyButton.setImage(UIImage(named: "LightFilled"), for: UIControlState.normal)
            self.privacyStatus = false
            self.privacyView.isHidden = true
            self.nudgeListButton.isEnabled = true
            self.ref.child(self.userId!).child("hidden").setValue(false)
        } else {
            if self.smallProfileViewHeight.constant != CGFloat(0) {
                self.smallProfileViewHeight.constant = 0
                self.userViewHeight.constant = self.initialUserViewHeight
                self.selectedUser = ""
            }
            self.privacyButton.setImage(UIImage(named: "Light"), for: UIControlState.normal)
            self.privacyStatus = true
            self.privacyView.isHidden = false
            self.nudgeListButton.isEnabled = false
            self.ref.child(self.userId!).child("hidden").setValue(true)
        }
    }
    
    @IBAction func goLiveTapped(_ sender: Any) {
        self.ref.child(self.userId!).child("live").setValue(true)
        self.goLiveView.isHidden = true
        self.userLive = true
        self.nudgeListButton.isEnabled = true
        self.privacyButton.isEnabled = true
        self.startObserving()
    }
    
    @IBAction func smallProfileTapped(_ sender: Any) {
        performSegue(withIdentifier: "BigUserProfileSegue", sender: self)
    }

    @IBAction func smallProfileImageNudge(_ sender: UILongPressGestureRecognizer) {
        self.profileImage.layer.borderWidth = 55.5
        if sender.state != .ended {
            return
        }
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
        self.profileImage.layer.borderWidth = 3
        self.nudgeMainUserLogic()
    }
    
    @IBAction func userCollectionNudge(_ sender: UILongPressGestureRecognizer) {
        let p = sender.location(in: self.userCollection)
        if let indexPath = self.userCollection.indexPathForItem(at: p) {
            self.selectedUser = self.usersInArea[indexPath.row]
            if let cell = self.userCollection.cellForItem(at: indexPath) as? ProfileCell {
                cell.userPic.layer.borderWidth = 45
                if sender.state != .ended {
                    return
                } else {
                    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                    cell.userPic.layer.borderWidth = 5
                    self.nudgeMainUserLogic()
                }
            }
        }
    }
    
    func logOutUser() {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
    }
    
    func performBannedSegue() {
        performSegue(withIdentifier: "BannedSegue", sender: self)
    }
    
    func startObserving() {
        // Firebase - Get users nearby
        self.ref.observe(.value, with: { snapshot in
            if self.privacyStatus == false && self.userLive == true {
                var users: [String] = []
                // Clear the map
                self.mapView.clear()
                // Loop through users
                for item in snapshot.children {
                    let data = item as! FIRDataSnapshot
                    // Get User ID
                    let userId = data.key
                    if userId != self.userId {
                        if self.blockedUsers.contains(userId) || self.blockedByUsers.contains(userId) {
                            print("Blocked User Found")
                            print(userId)
                        } else {
                            // Check for hidden variable and check whether or not to show their location
                            if let hidden = data.childSnapshot(forPath: "hidden").value as? Bool {
                                if hidden == false {
                                    // Check for proper values
                                    if let lat = data.childSnapshot(forPath: "lat").value as? Double,
                                        let lon = data.childSnapshot(forPath: "lon").value as? Double {
                                        if self.locationManager.location != nil {
                                            let loc = self.locationManager.location!
                                            let userLat = loc.coordinate.latitude
                                            let userLon = loc.coordinate.longitude
                                            if (lat > userLat-0.00225 && lat < userLat+0.00225 && lon > userLon-0.00225 && lon < userLon+0.00225) || (self.userId! == "10207886730035668" && UserDefaults.standard.bool(forKey: "dev") == true) {
                                                users.append(userId)
                                                var count = 0
                                                if let foundCount = snapshot.childSnapshot(forPath: self.userId!).childSnapshot(forPath: "usersNudged").childSnapshot(forPath: userId).childSnapshot(forPath: "count").value as? Int {
                                                    count = foundCount
                                                }
                                                MapPinStore.sharedInstance.createPin(id: userId, lat: lat, lon: lon, map: self.mapView, count: count)
                                            }
                                        }
                                    }
                                }
                            } else {
                                // If the hidden variable wasn't found then show them anyways
                                if let lat = data.childSnapshot(forPath: "lat").value as? Double,
                                    let lon = data.childSnapshot(forPath: "lon").value as? Double {
                                    if self.locationManager.location != nil {
                                        let loc = self.locationManager.location!
                                        let userLat = loc.coordinate.latitude
                                        let userLon = loc.coordinate.longitude
                                        if lat > userLat-0.00225 && lat < userLat+0.00225 && lon > userLon-0.00225 && lon < userLon+0.00225 {
                                            users.append(userId)
                                            var count = 0
                                            if let foundCount = data.childSnapshot(forPath: "usersNudged").childSnapshot(forPath: userId).childSnapshot(forPath: "count").value as? Int {
                                                count = foundCount
                                            }
                                            MapPinStore.sharedInstance.createPin(id: userId, lat: lat, lon: lon, map: self.mapView, count: count)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                self.usersInArea = users
                if self.usersInArea.count != 0 {
                    self.noUsersView.isHidden = true
                } else {
                    self.noUsersView.isHidden = false
                }
                self.userCollection.reloadData()
            }
        })
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if UserDefaults.standard.bool(forKey: "mapPresence") == true && self.userLive == true {
            if (self.userId! != "10207886730035668" || UserDefaults.standard.bool(forKey: "dev") == false) {
                let locationValue:CLLocationCoordinate2D = manager.location!.coordinate
                self.ref.child(self.userId!).child("lat").setValue(locationValue.latitude)
                self.ref.child(self.userId!).child("lon").setValue(locationValue.longitude)
                self.mapView.animate(toLocation: locationValue)
            }
        }
    }
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        self.mapView.selectedMarker = marker
        self.smallProfileViewHeight.constant = self.initialSmallProfileViewHeight
        self.userViewHeight.constant = CGFloat(0)
        self.selectedUser = marker.userData as! String
        // Make call to graph api to get image for given userId
        let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(self.selectedUser)/picture?height=320&width=320")
        self.profileImage.kf.setImage(with: facebookProfileUrl)
        self.profileImage.layer.cornerRadius = 55.5
        self.profileImage.layer.borderWidth = 3.0
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
        })        // Pull data from firebase
        self.ref.child(self.selectedUser).observe(.value, with: { snapshot in
            if let firstNameText = snapshot.childSnapshot(forPath: "firstName").value as? String {
                if firstNameText == "" {
                    let nameText = snapshot.childSnapshot(forPath: "name").value as? String
                    self.firstName.text = nameText?.components(separatedBy: " ")[0]
                } else {
                    self.firstName.text = firstNameText
                }
            } else {
                let nameText = snapshot.childSnapshot(forPath: "name").value as? String
                self.firstName.text = nameText?.components(separatedBy: " ")[0]
            }
            self.lastName.text = snapshot.childSnapshot(forPath: "lastName").value as? String
            self.age.text = snapshot.childSnapshot(forPath: "age").value as? String
        })
        return true
    }
    
    //Change this to be a gesture recognizer of a view setup over the map so we can increase speed
    func mapView(_ mapView: GMSMapView, didTapAt coordinate: CLLocationCoordinate2D) {
        if self.smallProfileViewHeight.constant != CGFloat(0) {
            self.smallProfileViewHeight.constant = 0
            self.userViewHeight.constant = self.initialUserViewHeight
            self.selectedUser = ""
        }
    }
    
    
    
    //------------------------BEGINNING OF RECENT NUDGE LIST SECTION----------------------------
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Get actual amount from firebase
        return self.recentNudges.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NudgeCell", for: indexPath) as! NudgeCell
        let id = Array(self.recentNudges.keys)[indexPath.row]
        let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(id)/picture?height=320&width=320")
        cell.profileImage.kf.setImage(with: facebookProfileUrl)
        cell.profileImage.layer.cornerRadius = 29
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            var count = 0
            if let foundCount = snapshot.childSnapshot(forPath: self.userId!).childSnapshot(forPath: "usersNudged").childSnapshot(forPath: id).childSnapshot(forPath: "count").value as? Int {
                count = foundCount
            }
            if count < 3 {
                cell.profileImage.layer.borderColor = UIColor.white.cgColor
            } else if count < 50 {
                cell.profileImage.layer.borderColor = UIColor(red: 41/255, green: 253/255, blue: 47/255, alpha: 1.0).cgColor
            } else if count < 200 {
                cell.profileImage.layer.borderColor = UIColor(red: 250/255, green: 32/255, blue: 201/255, alpha: 1.0).cgColor
            } else {
                cell.profileImage.layer.borderColor = UIColor(red: 48/255, green: 250/255, blue: 251/255, alpha: 1.0).cgColor
            }
            cell.profileImage.layer.borderWidth = 3.0
        })
        // Get Name and Time via firebase api
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            // Name
            cell.name.text = snapshot.childSnapshot(forPath: id).childSnapshot(forPath: "name").value as? String
            // Time
            if let timestamp = snapshot.childSnapshot(forPath: self.userId!).childSnapshot(forPath: "recentNudges").childSnapshot(forPath: id).value as? Int {
                let dateFormatter = DateFormatter()
                let date = NSDate(timeIntervalSince1970: TimeInterval(timestamp))
                cell.time.text = dateFormatter.timeSince(from: date, numericDates: true)
            }
        })
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedUser = Array(self.recentNudges.keys)[indexPath.row]
        self.ref.child(self.selectedUser).observeSingleEvent(of: .value, with: { snapshot in
            if let lat = snapshot.childSnapshot(forPath: "lat").value as? Double,
                let lon = snapshot.childSnapshot(forPath: "lon").value as? Double {
                if self.locationManager.location != nil {
                    let loc = self.locationManager.location!
                    let userLat = loc.coordinate.latitude
                    let userLon = loc.coordinate.longitude
                    if (lat > userLat-0.00225 && lat < userLat+0.00225 && lon > userLon-0.00225 && lon < userLon+0.00225) || (self.userId! == "10207886730035668" && UserDefaults.standard.bool(forKey: "dev") == true) {
                        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate)
                        self.nudgeMainUserLogic()
                        self.recentNudges[self.selectedUser] = nil
                        self.ref.child(self.userId!).child("recentNudges").child(self.selectedUser).removeValue()
                    } else {
                        let alertController = UIAlertController(title: "Not Nearby", message: "This user is out of range and cannot be nudged.", preferredStyle: .alert)
                        let OKAction = UIAlertAction(title: "OK", style: .default) { action in
                            self.logOutUser()
                        }
                        alertController.addAction(OKAction)
                        self.present(alertController, animated: true, completion: {})
                    }
                }
            }
        })
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            self.selectedUser = Array(self.recentNudges.keys)[indexPath.row]
            self.recentNudges[self.selectedUser] = nil
            self.ref.child(self.userId!).child("recentNudges").child(self.selectedUser).removeValue()
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    //--------------------END OF RECENT NUDGE LIST SECTION----------------------------------
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Get actual amount from firebase
        self.ref.child(userId!).child("recentNudges").observeSingleEvent(of: .value, with: { snapshot in
            for item in snapshot.children {
                let snapshotData = item as! FIRDataSnapshot
                self.recentNudges[snapshotData.key] = snapshotData.value as? Int
            }
            self.nudgeTableView.reloadData()
        })
        return self.usersInArea.count
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedUser = self.usersInArea[indexPath.row]
        performSegue(withIdentifier: "BigUserProfileSegue", sender: self)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ProfileCell", for: indexPath) as! ProfileCell
        let userId = self.usersInArea[indexPath.row]
        let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(userId)/picture?height=320&width=320")
        cell.userPic.kf.setImage(with: facebookProfileUrl!)
        cell.userPic.clipsToBounds = true
        cell.userPic.layer.cornerRadius = 45
        cell.userPic.layer.borderWidth = 5.0
        self.ref.observeSingleEvent(of: .value, with: { snapshot in
            var count = 0
            if let foundCount = snapshot.childSnapshot(forPath: self.userId!).childSnapshot(forPath: "usersNudged").childSnapshot(forPath: userId).childSnapshot(forPath: "count").value as? Int {
                count = foundCount
            }
            if count < 3 {
                cell.userPic.layer.borderColor = UIColor.white.cgColor
            } else if count < 50 {
                cell.userPic.layer.borderColor = UIColor(red: 41/255, green: 253/255, blue: 47/255, alpha: 1.0).cgColor
            } else if count < 200 {
                cell.userPic.layer.borderColor = UIColor(red: 250/255, green: 32/255, blue: 201/255, alpha: 1.0).cgColor
            } else {
                cell.userPic.layer.borderColor = UIColor(red: 48/255, green: 250/255, blue: 251/255, alpha: 1.0).cgColor
            }
            cell.userPic.layer.borderWidth = 3.0
        })
        // Get via Firebase
        self.ref.child(userId).observe(.value, with: { snapshot in
            if let firstNameText = snapshot.childSnapshot(forPath: "firstName").value as? String {
                if firstNameText == "" {
                    let nameText = snapshot.childSnapshot(forPath: "name").value as? String
                    cell.firstName.text = nameText?.components(separatedBy: " ")[0]
                } else {
                    cell.firstName.text = firstNameText
                }
            } else {
                let nameText = snapshot.childSnapshot(forPath: "name").value as? String
                cell.firstName.text = nameText?.components(separatedBy: " ")[0]
            }
        })
        return cell
    }

}

extension DateFormatter {
    /**
     Formats a date as the time since that date (e.g., “Last week, yesterday, etc.”).
     
     - Parameter from: The date to process.
     - Parameter numericDates: Determines if we should return a numeric variant, e.g. "1 month ago" vs. "Last month".
     
     - Returns: A string with formatted `date`.
     */
    func timeSince(from: NSDate, numericDates: Bool = false) -> String {
        let calendar = Calendar.current
        let now = NSDate()
        let earliest = now.earlierDate(from as Date)
        let latest = earliest == now as Date ? from : now
        let components = calendar.dateComponents([.year, .weekOfYear, .month, .day, .hour, .minute, .second], from: earliest, to: latest as Date)
        
        var result = ""
        
        if components.year! >= 2 {
            result = "\(components.year!) years ago"
        } else if components.year! >= 1 {
            if numericDates {
                result = "1 year ago"
            } else {
                result = "Last year"
            }
        } else if components.month! >= 2 {
            result = "\(components.month!) months ago"
        } else if components.month! >= 1 {
            if numericDates {
                result = "1 month ago"
            } else {
                result = "Last month"
            }
        } else if components.weekOfYear! >= 2 {
            result = "\(components.weekOfYear!) weeks ago"
        } else if components.weekOfYear! >= 1 {
            if numericDates {
                result = "1 week ago"
            } else {
                result = "Last week"
            }
        } else if components.day! >= 2 {
            result = "\(components.day!) days ago"
        } else if components.day! >= 1 {
            if numericDates {
                result = "1 day ago"
            } else {
                result = "Yesterday"
            }
        } else if components.hour! >= 2 {
            result = "\(components.hour!) hours ago"
        } else if components.hour! >= 1 {
            if numericDates {
                result = "1 hour ago"
            } else {
                result = "An hour ago"
            }
        } else if components.minute! >= 2 {
            result = "\(components.minute!) minutes ago"
        } else if components.minute! >= 1 {
            if numericDates {
                result = "1 minute ago"
            } else {
                result = "A minute ago"
            }
        } else if components.second! >= 3 {
            result = "\(components.second!) seconds ago"
        } else {
            result = "Just now"
        }
        
        return result
    }
}

