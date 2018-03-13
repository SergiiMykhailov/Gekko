//
//  AuthenticationViewController.swift
//  Gekko
//
//  Created by Aleksandr Saliyenko on 3/13/18.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import LocalAuthentication

class AuthenticationViewController : UIViewController {
    
    // MARK: Overriden methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let userDefaults = UserDefaults.standard
        
        publicKey = userDefaults.string(forKey:BTCTradeUAAccountSettingsViewController.PublicKeySettingsKey)
        privateKey = userDefaults.string(forKey:BTCTradeUAAccountSettingsViewController.PrivateKeySettingsKey)
        
        if isAuthorized {
            authenticationWithTouchID()
        }
        
    }
    
    //MARK: Internal methods
    
    fileprivate var isAuthorized:Bool {
        return publicKey != nil && !publicKey!.isEmpty && privateKey != nil && !privateKey!.isEmpty
    }
    
    func authenticationWithTouchID() {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = "Use Passcode"
        
        var authError: NSError?
        let reasonString = "To access the secure data"
        
        if localAuthenticationContext.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &authError) {
            
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reasonString) { (success, evaluateError) in
                
                if success {
                    //TODO: User authenticated successfully, take appropriate action
                    self.performSegue(withIdentifier: AuthenticationViewController.ShowNavigationControllerSegueName, sender: self)
                }
                else {
                    //TODO: User did not authenticate successfully, look at error and take appropriate action
//                    localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reasonString, reply: { (success, evaluateError) in
//
//                        if success {
//                            self.performSegue(withIdentifier: AuthenticationViewController.ShowNavigationControllerSegueName, sender: self)
//                        }
//                    })
                    
                }
            }
        }
        else {
            localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reasonString, reply: { (success, evaluateError) in
                if success {
                    self.performSegue(withIdentifier: AuthenticationViewController.ShowNavigationControllerSegueName, sender: self)
                }
            })
        }
    }
    
    //MARK: Internal fields
    
    fileprivate var publicKey:String?
    fileprivate var privateKey:String?
    
    fileprivate static let ShowNavigationControllerSegueName = "Show Navigation Controller"
}
