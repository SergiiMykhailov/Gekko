//  Created by Sergii Mykhailov on 11/07/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

class AccountRegistrationViewController : UIViewController,
                                          UITextFieldDelegate {

    // MARK: Overriden methods

    override func viewDidLoad() {
        super.viewDidLoad()

        phoneLabel?.text = NSLocalizedString("phone:", comment:"Phone number label title")

        signUpButton?.isEnabled = false
        signUpButton?.setTitle(NSLocalizedString("Sign Up", comment:"Sign Up button title"), for:.normal)

        emailTextField?.delegate = self
        emailTextField?.addTarget(self, action:#selector(textFieldDidChange(_:)), for:.editingChanged)
        emailTextField?.becomeFirstResponder()

        phoneTextField?.delegate = self
        phoneTextField?.addTarget(self, action:#selector(textFieldDidChange(_:)), for:.editingChanged)
    }

    override func resignFirstResponder() -> Bool {
        if emailTextField!.isFirstResponder {
            return emailTextField!.resignFirstResponder()
        }
        else if phoneTextField!.isFirstResponder {
            return phoneTextField!.resignFirstResponder()
        }

        return true
    }

    // MARK: UITextFieldDelegate implementation

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailTextField {
            phoneTextField?.becomeFirstResponder()
        }
        else if textField == phoneTextField {
            register()
        }

        return true
    }

    // MARK: Internal methods

    fileprivate func register() {
        if let accountManager = TradingPlatformManager.shared.tradingPlatform.accountManager {
            let email = emailTextField!.text!.trimmingCharacters(in:.whitespaces)
            let phoneNumber = phoneTextField!.text!.trimmingCharacters(in:.whitespaces)
            let password = UUID().uuidString
            accountManager.registerAccount(withEmail:email,
                                           phoneNumber:phoneNumber,
                                           password:password) { (registrationResult, serverResponse) in
                DispatchQueue.main.async { [weak self] in
                    if registrationResult != nil {
                        switch registrationResult! {
                        case .Succeeded:
                            TradingPlatformManager.shared.handleRegistration(withUserID:email,
                                                                             password:password,
                                                                             serverResponse:serverResponse)
                            self?.navigationController?.popToRootViewController(animated:true)

                        case .AccountAlreadyExists:
                            self?.showFailAlert(withExplanation:NSLocalizedString("User with such credentials already exists",
                                                                                  comment:"User already exists alert title"))

                        case .UnknownError:
                            var explanation = NSLocalizedString("Unknown server error:",
                                                                comment:"Registration server error alert title")
                            explanation += "\n"
                            explanation += serverResponse.description
                            self?.showFailAlert(withExplanation:explanation)
                        }
                    }
                }
            }
        }
    }

    fileprivate func showFailAlert(withExplanation explanation:String) {
        let alert = UIAlertController(title:NSLocalizedString("Registration failed",
                                                              comment:"Registration failed alert title"),
                                      message:explanation,
                                      preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:NSLocalizedString("Close", comment:"Close alert action"),
                                      style:.`default`,
                                      handler:{ (_) in }))

        present(alert, animated:true, completion:nil)
    }

    fileprivate func isValidEmail(_ inputString:String) -> Bool {
        let emailPredicate = NSPredicate(format:"SELF MATCHES %@", AccountRegistrationViewController.EmailRegEx)
        let result = emailPredicate.evaluate(with:inputString)

        return result
    }

    fileprivate func isValidPhoneNumber(_ inputString:String) -> Bool {
        let phonePredicate = NSPredicate(format:"SELF MATCHES %@", AccountRegistrationViewController.PhoneNumberRegEx)
        let result = phonePredicate.evaluate(with:inputString)

        return result
    }

    // MARK: Actions handling

    @IBAction func signUpButtonPressed() {
        register()
    }

    @objc func textFieldDidChange(_ textField:UITextField) {
        var isButtonEnabled = false

        if var text = emailTextField!.text {
            text = text.trimmingCharacters(in:.whitespaces)

            if isValidEmail(text) {
                if phoneTextField!.text != nil {
                    text = phoneTextField!.text!

                    isButtonEnabled = isValidPhoneNumber(text.trimmingCharacters(in:.whitespaces))
                }
            }
        }

        signUpButton?.isEnabled = isButtonEnabled
    }

    // MARK: Outlets

    @IBOutlet weak var emailTextField:UITextField?
    @IBOutlet weak var phoneTextField:UITextField?
    @IBOutlet weak var phoneLabel:UILabel?
    @IBOutlet weak var signUpButton:UIButton?

    // MARK: Internal fields

    fileprivate static let EmailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,10}"
    fileprivate static let PhoneNumberRegEx = "\\d{10}"
}
