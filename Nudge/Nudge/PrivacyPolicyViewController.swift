//
//  PrivacyPolicyViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/22/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit

class PrivacyPolicyViewController: UIViewController {
    
    @IBOutlet var privacyView: UIWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let pdfURL = Bundle.main.url(forResource: "PrivacyPolicy", withExtension: "pdf", subdirectory: nil, localization: nil)  {
            do {
                let data = try Data(contentsOf: pdfURL)
                self.privacyView.load(data, mimeType: "application/pdf", textEncodingName:"", baseURL: pdfURL.deletingLastPathComponent())
            }
            catch {
                // catch errors here
            }
            
        }
    }
    
    @IBAction func exitPressed(_ sender: Any) {
        dismiss(animated: true, completion: {})
    }
}
