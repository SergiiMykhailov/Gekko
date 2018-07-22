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
        emailTextField?.becomeFirstResponder()

        phoneTextField?.delegate = self
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
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == phoneTextField {
            return validationPhoneNumber(textField, shouldChangeCharactersIn:range, replacementString:string)
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
                            TradingPlatformManager.shared.handleRegistration(withServerResponse:serverResponse)
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
    
    func validationPhoneNumber(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let validationSet = CharacterSet.decimalDigits.inverted
        let components = string.components(separatedBy:validationSet)
        
        if components.count > 1 {
            return false
        }
        
        var newString = (textField.text as NSString?)?.replacingCharacters(in: range, with: string)
        
        let validComponents = newString!.components(separatedBy: validationSet)
        
        newString = validComponents.joined(separator:"")
        
        let localNumberMaxLength = 7
        let areaCodeMaxLength = 3
        let countryCodeMaxLength = 2
        
        if newString!.count > localNumberMaxLength + areaCodeMaxLength + countryCodeMaxLength {
            return false
        }
        
        var resultString = ""
        
        let localNumberLength = min(localNumberMaxLength, newString!.count)
        
        if localNumberLength > 0 {
            let index = newString!.index(newString!.startIndex, offsetBy: newString!.count - localNumberLength)
            let number = String(newString![index...])
            resultString.append(number)
            if resultString.count > 3 {
                resultString.insert("-", at: resultString.index(resultString.startIndex, offsetBy: 3))
            }
        }
        
        if newString!.count > localNumberMaxLength {
            let areaCodeLength = min(newString!.count - localNumberMaxLength, areaCodeMaxLength)
            let firstIndex = newString!.index(newString!.startIndex, offsetBy: newString!.count - localNumberMaxLength - areaCodeLength)
            let secondIndex = newString!.index(firstIndex, offsetBy: areaCodeLength)
            var area = String(newString![firstIndex..<secondIndex])
            area = "(\(area))"
            resultString.insert(contentsOf: area, at: resultString.startIndex)
        }
        
        if newString!.count > localNumberMaxLength + areaCodeMaxLength {
            let countryCodeLength = min(newString!.count - localNumberMaxLength - areaCodeMaxLength, countryCodeMaxLength)
            let firstIndex = newString!.startIndex
            let secondIndex = newString!.index(firstIndex, offsetBy: countryCodeLength)
            var countryCode = String(newString![firstIndex..<secondIndex])
            countryCode = "+\(countryCode)"
            resultString.insert(contentsOf: countryCode, at: resultString.startIndex)
        }
        
        textField.text = resultString
        
        return false
    }

    // MARK: Actions handling

    @IBAction func signUpButtonPressed() {
        register()
    }

    // MARK: Outlets

    @IBOutlet weak var emailTextField:UITextField?
    @IBOutlet weak var phoneTextField:UITextField?
    @IBOutlet weak var phoneLabel:UILabel?
    @IBOutlet weak var signUpButton:UIButton?
}
