//  Created by Sergii Mykhailov on 11/07/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

class AccountRegistrationViewController : UIViewController,
                                          UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        signUpButton?.isEnabled = false
        signUpButton?.setTitle(NSLocalizedString("Sign Up", comment:"Sign Up button title"), for:.normal)

        emailTextField?.keyboardType = .emailAddress
        emailTextField?.delegate = self
        emailTextField?.textContentType = .emailAddress
        emailTextField?.addTarget(self, action:#selector(textFieldDidChange(_:)), for:.editingChanged)
        emailTextField?.becomeFirstResponder()
    }

    // MARK: Internal methods

    fileprivate func register() {
        if let accountManager = TradingPlatformManager.shared.tradingPlatform.accountManager {
            let email = emailTextField!.text!.trimmingCharacters(in:.whitespaces)
            accountManager.registerAccount(withEmail:email) { (registrationResult) in

            }
        }
    }

    fileprivate func isValidEmail(_ inputString:String) -> Bool {
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", AccountRegistrationViewController.EmailRegEx)
        let result = emailPredicate.evaluate(with:inputString)

        return result
    }

    // MARK: Actions handling

    @IBAction func signUpButtonPressed() {
        register()
    }

    @objc func textFieldDidChange(_ textField:UITextField) {
        var isButtonEnabled = false

        if var text = textField.text {
            text = text.trimmingCharacters(in:.whitespaces)
            isButtonEnabled = isValidEmail(text)
        }

        signUpButton?.isEnabled = isButtonEnabled
    }

    // MARK: Outlets

    @IBOutlet weak var emailTextField:UITextField?
    @IBOutlet weak var signUpButton:UIButton?

    // MARK: Internal fields

    fileprivate static let EmailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,10}"
}
