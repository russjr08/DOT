//
//  ViewController.swift
//  Destiny Objective Tracker
//
//  Created by Russell Richardson on 8/1/18.
//  Copyright © 2018 Russell Richardson. All rights reserved.
//

import UIKit
import AuthenticationServices
import SafariServices

class LoginViewController: UIViewController {
    
    var sfAuthSession: SFAuthenticationSession?
    let defaults = UserDefaults.init()


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        if(defaults.string(forKey: "oauthtoken") != nil) {            
            self.launchMainViewController()
        }
    }
    
    
    @IBAction func loginBtnClicked(_ sender: Any) {
        let oauth_url = "https://www.bungie.net/en/oauth/authorize?client_id=24297&response_type=code"

        sfAuthSession = SFAuthenticationSession.init(url: URL(string: oauth_url)!, callbackURLScheme: "DestinyObjTracker://oauth-callback", completionHandler: self.acceptToken)
        
        self.sfAuthSession?.start()
        
    }
    
    func acceptToken(callBack: URL?, error: Error?) {
        guard error == nil, let successURL = callBack else {
            return
        }
        
        let oauthtoken = NSURLComponents(string: (successURL.absoluteString))?.queryItems?.filter({$0.name == "code"}).first
        
        print(oauthtoken?.value ?? "No Token Found")
        
        if((oauthtoken?.value) == nil) {
            let alert = UIAlertController.init(title: "Login Error", message: "Whoops! That didn't work. Give it another try when you're ready.", preferredStyle: .alert)
            alert.addAction(UIAlertAction.init(title: "OK", style: UIAlertAction.Style.default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        } else {
            self.defaults.set(oauthtoken?.value, forKey: "oauthtoken")
            
            self.launchMainViewController()
        }
        
        

    }
    
    func launchMainViewController() {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let newViewController = storyBoard.instantiateViewController(withIdentifier: "MainTabController") as! UITabBarController
        self.present(newViewController, animated: true, completion: nil)
    }
    

}

