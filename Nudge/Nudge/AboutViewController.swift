//
//  AboutViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/18/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit

class AboutViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet var aboutTopicsTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Setup
        self.aboutTopicsTable.delegate = self
        self.aboutTopicsTable.dataSource = self
    }
    
    @IBAction func exitPressed(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = aboutTopicsTable.dequeueReusableCell(withIdentifier: "AboutCell", for: indexPath) as! AboutCell
        if indexPath.row == 0 {
            cell.aboutImage.image = UIImage(named: "UserFilled")
            cell.label.text = "Nudge Policy"
        } else if indexPath.row == 1 {
            cell.aboutImage.image = UIImage(named: "DocumentFilled")
            cell.label.text = "Privacy Policy"
        } else if indexPath.row == 2 {
            cell.aboutImage.image = UIImage(named: "AboutFilled")
            cell.label.text = "Frequently Asked Questions"
        } else if indexPath.row == 3 {
            cell.aboutImage.image = UIImage(named: "UserMaleFilled")
            cell.label.text = "The Creators"
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            performSegue(withIdentifier: "NudgePolicySegue", sender: self)
        } else if indexPath.row == 1 {
            performSegue(withIdentifier: "PrivacyPolicySegue", sender: self)
        } else if indexPath.row == 2 {
            performSegue(withIdentifier: "FAQSegue", sender: self)
        } else if indexPath.row == 3 {
            performSegue(withIdentifier: "CreatorSegue", sender: self)
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
