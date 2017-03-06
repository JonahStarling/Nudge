//
//  TermsViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/21/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit
import FBSDKLoginKit

class TermsViewController: UIViewController {
    
    @IBOutlet var termsView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let pdfURL = Bundle.main.url(forResource: "TermsOfUse", withExtension: "pdf", subdirectory: nil, localization: nil)  {
            do {
                let data = try Data(contentsOf: pdfURL)
                self.termsView.load(data, mimeType: "application/pdf", textEncodingName:"", baseURL: pdfURL.deletingLastPathComponent())
            }
            catch {
                // catch errors here
            }
            
        }
    }
    
    @IBAction func declinedTerms(_ sender: Any) {
        let loginManager = FBSDKLoginManager()
        loginManager.logOut()
        UserDefaults.standard.set(false, forKey: "termsAccepted")
        performSegue(withIdentifier: "DeniedTermsSegue", sender: self)
    }
    
    @IBAction func acceptedTerms(_ sender: Any) {
        UserDefaults.standard.set(true, forKey: "termsAccepted")
        performSegue(withIdentifier: "IntroSegue", sender: self)
    }
}
