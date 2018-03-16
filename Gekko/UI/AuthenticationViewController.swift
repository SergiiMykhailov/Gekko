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
        
        publicKey = userDefaults.string(forKey:UIUtils.PublicKeySettingsKey)
        privateKey = userDefaults.string(forKey:UIUtils.PrivateKeySettingsKey)
        
        self.setupMainIconImageView()
    }
    
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated)
        
        if isAuthorized {
            authenticate()
        }
        else {
            performSegue(withIdentifier: AuthenticationViewController.ShowNavigationControllerSegueName, sender: self)
        }
    }
    
    // MARK: Internal methods
    
    fileprivate func setupMainIconImageView() {
        let iconImage = (#imageLiteral(resourceName: "btcIcon"))
        let mainIconImageView = UIImageView(image: iconImage)
        
        self.view.addSubview(mainIconImageView)
        
        mainIconImageView.layer.cornerRadius = mainIconImageView.frame.width / 2
        mainIconImageView.layer.masksToBounds = true
        
        mainIconImageView.snp.makeConstraints { (make) in
            let sizeOfMainView = self.view.frame.size
            
            make.centerX.equalTo(sizeOfMainView.width / 2)
            make.centerY.equalTo(sizeOfMainView.height / 4)
        }
    }
    
    fileprivate var isAuthorized:Bool {
        return publicKey != nil && !publicKey!.isEmpty && privateKey != nil && !privateKey!.isEmpty
    }
    
    func authenticate() {
        let localAuthenticationContext = LAContext()
        localAuthenticationContext.localizedFallbackTitle = NSLocalizedString("Use Passcode", comment: "Fallback title")
        
        let reasonString = NSLocalizedString("To access the application", comment: "Authentication reason string")
        
        localAuthenticationContext.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reasonString) { (success, _) in
            if success {
                DispatchQueue.main.async { [weak self] in
                    if self != nil {
                        self!.performSegue(withIdentifier: AuthenticationViewController.ShowNavigationControllerSegueName, sender: self)
                    }
                }
            }
            else {
                DispatchQueue.main.async { [weak self] in
                    if self != nil {
                        self!.failedLabel.textColor = #colorLiteral(red: 1, green: 0.02807807196, blue: 0, alpha: 1)
                        self!.failedLabel.text = NSLocalizedString("Authorization failed", comment: "Authorization failed")
                        self!.failedLabel.isEnabled = true
                    }
                }
            }
        }
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var failedLabel: UILabel!
    
    // MARK: Internal fields
    
    fileprivate var publicKey:String?
    fileprivate var privateKey:String?
    
    fileprivate static let ShowNavigationControllerSegueName = "Show Navigation Controller"
}
