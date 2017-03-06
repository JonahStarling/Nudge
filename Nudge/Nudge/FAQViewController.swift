//
//  FAQViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/22/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit

class FAQViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet var faqTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.faqTable.delegate = self
        self.faqTable.dataSource = self
    }

    @IBAction func exitPressed(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = faqTable.dequeueReusableCell(withIdentifier: "FAQCell", for: indexPath) as! FAQCell
        if indexPath.row == 0 {
            cell.faqTitle.text = "Is my location being tracked all the time?"
            cell.faqResponse.text = "No, your location is only being tracked while you are in the app. In the future you will have the option to be tracked when you have the app open or in the background. At that point in time we will also have more safety and privacy features in place so you feel safe and comfortable using the app."
        } else if indexPath.row == 1 {
            cell.faqTitle.text = "What happens when I leave the app?"
            cell.faqResponse.text = "For now, when you leave the app your pin will turn grey and stay where you last were. In the future you will have the option of having your pin disappear when you leave or have it follow you even when your app isn't open."
        } else if indexPath.row == 2 {
            cell.faqTitle.text = "What does the colors around people's pictures mean?"
            cell.faqResponse.text = "These colors describe your relationship with that person. White means you have nudged each other less than 3 times, green means you have nudged each other between 3 and 50 times, pink is between 50 and 200, and blue is anything over 200. These values may change in the future, but the purpose will remain the same. At a glance of the map you can see the people you nudge the most. In the future there will be incentives for reaching a new tier with someone."
        } else if indexPath.row == 3 {
            cell.faqTitle.text = "I nudged them. Now what?"
            cell.faqResponse.text = "Talk to them or don't talk to them, the decision is in your court. The nudge itself is a small interaction that can potentially spark an interaction in real life. The whole point of Nudge is to embrace the now and interact with those around you."
        }
        cell.faqTitle.sizeToFit()
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
}
