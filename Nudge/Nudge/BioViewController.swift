//
//  BioViewController.swift
//  Nudge
//
//  Created by Jonah Starling on 2/18/17.
//  Copyright © 2017 In The Belly. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase

class BioViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet var bio: UITextView!
    
    let ref = FIRDatabase.database().reference().child("users")
    var userId = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.userId = UserDefaults.standard.string(forKey: "id")!
        self.hideKeyboardWhenTappedAround()
        self.bio.delegate = self
    }
    
    @IBAction func finishedPressed(_ sender: Any) {
        ref.child(userId).child("bio").setValue(self.bio.text)
        performSegue(withIdentifier: "TermsSegue", sender: self)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n") {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
}
