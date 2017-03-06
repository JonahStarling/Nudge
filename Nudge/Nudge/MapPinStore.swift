//
//  MapPinStore.swift
//  Nudge
//
//  Created by Jonah Starling on 2/15/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit
import GoogleMaps

class MapPinStore {
    
    static let sharedInstance:MapPinStore = MapPinStore()
    var allPins = [GMSMarker]()
    
    func addPin(pin: GMSMarker) {
        self.allPins.append(pin)
    }
    
    func createPin(id: String, lat: Double, lon: Double, map: GMSMapView, count: Int) {
        let loc = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let marker = GMSMarker(position: loc)
        marker.userData = id
        let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(id)/picture?height=320&width=320")
        let iconImageView = UIImageView()
        iconImageView.kf.setImage(with: facebookProfileUrl!)
        marker.iconView = iconImageView
        marker.iconView?.bounds.size.height = 50.0
        marker.iconView?.bounds.size.width = 50.0
        marker.iconView?.layer.borderWidth = 2.0
        if count < 3 {
            marker.iconView?.layer.borderColor = UIColor.white.cgColor
        } else if count < 50 {
            marker.iconView?.layer.borderColor = UIColor(red: 41/255, green: 253/255, blue: 47/255, alpha: 1.0).cgColor
        } else if count < 200 {
            marker.iconView?.layer.borderColor = UIColor(red: 250/255, green: 32/255, blue: 201/255, alpha: 1.0).cgColor
        } else {
            marker.iconView?.layer.borderColor = UIColor(red: 48/255, green: 250/255, blue: 251/255, alpha: 1.0).cgColor
        }
        marker.iconView?.layer.cornerRadius = 25
        marker.iconView?.clipsToBounds = true
        marker.isFlat = false
        marker.map = map
    }
    
    func removePinWithId(id: String) {
        var i = 0
        for pin in self.allPins {
            if pin.userData as! String == id {
                self.allPins.remove(at: i)
            }
            i += 1
        }
    }
    
    func updateOrAddPin(id: String, lat: Double, lon: Double, map: GMSMapView) {
        var pinFound = false
        for pin in self.allPins {
            if pin.userData as! String == id {
                let loc = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                pin.position = loc
                pinFound = true
            }
        }
        if pinFound == false {
            let loc = CLLocationCoordinate2D(latitude: lat, longitude: lon)
            let marker = GMSMarker(position: loc)
            marker.userData = id
            let facebookProfileUrl = URL(string: "http://graph.facebook.com/\(id)/picture?height=320&width=320")
            let iconImageView = UIImageView()
            iconImageView.kf.setImage(with: facebookProfileUrl!)
            marker.iconView = iconImageView
            marker.iconView?.bounds.size.height = 50.0
            marker.iconView?.bounds.size.width = 50.0
            marker.iconView?.layer.borderWidth = 2.0
            marker.iconView?.layer.borderColor = UIColor.white.cgColor
            marker.iconView?.layer.cornerRadius = 25
            marker.iconView?.clipsToBounds = true
            marker.isFlat = false
            marker.map = map
        }
    }
    
    func changePinLocation(id: String, lat: Double, lon: Double) {
        for pin in self.allPins {
            if pin.userData as! String == id {
                let loc = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                pin.position = loc
            }
        }
    }
}
