//  Created by Sergii Mykhailov on 23/07/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

class AccountDetailsViewController : UIViewController {

    // MARK: Overriden methods

    override func viewDidLoad() {
        userIDLabel?.text = NSLocalizedString("login:", comment:"Login label title")
        passwordLabel?.text = NSLocalizedString("password:", comment:"Password label title")

        userIDButton?.setTitle(TradingPlatformManager.shared.userID, for:.normal)
        passwordButton?.setTitle(TradingPlatformManager.shared.password, for:.normal)
        pinButton?.setTitle(TradingPlatformManager.shared.securityKey, for:.normal)
    }

    // MARK: Internal methods

    fileprivate func copyToClipboardAndShowNotification(value:String) {
        UIPasteboard.general.string = value

        UIUtils.presentNotification(withMessage:NSLocalizedString("Value was copied to clipboard", comment:"Value copying message"),
                                    onView:view,
                                    onCompletion: { })
    }

    // MARK: Events handling

    @IBAction func loginButtonPressed() {
        if let userID = TradingPlatformManager.shared.userID {
            copyToClipboardAndShowNotification(value:userID)
        }
    }

    @IBAction func passwordButtonPressed() {
        if let password = TradingPlatformManager.shared.password {
            copyToClipboardAndShowNotification(value:password)
        }
    }

    @IBAction func pinButtonPressed() {
        if let securityKey = TradingPlatformManager.shared.securityKey {
            copyToClipboardAndShowNotification(value:securityKey)
        }
    }

    // MARK: Outlets

    @IBOutlet weak var userIDLabel:UILabel?
    @IBOutlet weak var userIDButton:UIButton?
    @IBOutlet weak var passwordLabel:UILabel?
    @IBOutlet weak var passwordButton:UIButton?
    @IBOutlet weak var pinLabel:UILabel?
    @IBOutlet weak var pinButton:UIButton?
}
