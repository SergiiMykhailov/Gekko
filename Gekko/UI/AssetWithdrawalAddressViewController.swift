//  Created by Sergii Mykhailov on 31/07/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

class AssetWithdrawalAddressViewController : UIViewController,
                                             UITextFieldDelegate {

    // MARK: Public methods and properties

    public var currency:Currency = .UAH

    // MARK: Overriden methods

    override func viewDidLoad() {
        title = NSLocalizedString("Withdraw funds", comment:"Withdraw funds scene title")

        availableAmountLabel?.text = NSLocalizedString("Available amount:", comment:"Withdrawal available amount label title")
        TradingPlatformManager.shared.tradingPlatform.retriveBalanceAsync(forCurrency:currency) { (balanceItem) in
            if balanceItem != nil {
                DispatchQueue.main.async { [weak self] in
                    if self != nil {
                        let formattedAmount = UIUtils.formatAssetValue(amount:balanceItem!.amount)
                        let text = self!.availableAmountLabel!.text! + " " + formattedAmount

                        self?.availableAmountLabel?.text = text
                    }
                }
            }
        }

        let lastUsedWalletForCurrency = UserDefaults.standard.value(forKey:lastUsedWalletSettingsKey) as? String
        if currency == .UAH {
            addressTextField?.keyboardType = .numberPad
            addressTextField?.textContentType = UITextContentType.creditCardNumber
            addressTextField?.smartDashesType = .yes
            addressTextField?.placeholder = lastUsedWalletForCurrency ??
                NSLocalizedString("Card number", comment:"Card number label title")
        }
        else {
            addressTextField?.placeholder = lastUsedWalletForCurrency ?? NSLocalizedString("Wallet", comment:"Wallet address label title")
        }

        withdrawAmountTextField?.placeholder = NSLocalizedString("Amount", comment:"Withdrawal amount placeholder text")

        addressTextField?.delegate = self
        withdrawAmountTextField?.delegate = self

        addressTextField?.addTarget(self, action:#selector(textFieldDidChange(_:)), for:.editingChanged)
        withdrawAmountTextField?.addTarget(self, action:#selector(textFieldDidChange(_:)), for:.editingChanged)

        submitButton?.setTitle(NSLocalizedString("Transfer", comment:"Transfer button title"), for:.normal)
        submitButton?.isEnabled = false
    }

    // MARK: UITextFieldDelegate implementation

    func textFieldShouldReturn(_ textField:UITextField) -> Bool {
        if textField == addressTextField {
            withdrawAmountTextField?.becomeFirstResponder()
        }
        else if textField == withdrawAmountTextField {
            authenticateAndTransfer()
        }

        return true
    }

    // MARK: Internal methods

    fileprivate var lastUsedWalletSettingsKey:String {
        get {
            return "LastUsedWallet_\(currency.rawValue)"
        }
    }

    fileprivate var defaultAddressPlaceholder:String {
        get {
            return currency == .UAH ?
                   NSLocalizedString("Card number", comment:"Card number label title") :
                   NSLocalizedString("Wallet", comment:"Wallet address label title")
        }
    }

    fileprivate var isAddressFieldValid:Bool {
        get {
            var addressText = addressTextField!.text
            if addressText != nil && !addressText!.isEmpty {
                addressText = addressText!.trimmingCharacters(in:.whitespaces)

                return currency == .UAH ? isValidCreditCardNumber(addressText!) : !addressText!.isEmpty
            }
            else if addressTextField!.placeholder != defaultAddressPlaceholder {
                return true
            }

            return false
        }
    }

    @objc fileprivate func textFieldDidChange(_ textField:UITextField) {
        var isButtonEnabled = false

        if isAddressFieldValid {
            if var amountText = withdrawAmountTextField!.text {
                amountText = amountText.trimmingCharacters(in:.whitespaces)

                let amountValue = Double(amountText)
                isButtonEnabled = amountValue != nil && amountValue! > 0.0
            }
        }

        submitButton?.isEnabled = isButtonEnabled
    }

    fileprivate func isValidCreditCardNumber(_ inputString:String) -> Bool {
        let cardNumberPredicate = NSPredicate(format:"SELF MATCHES %@", AssetWithdrawalAddressViewController.CardNumberRegEx)
        let result = cardNumberPredicate.evaluate(with:inputString)

        return result
    }

    fileprivate func authenticateAndTransfer() {
        // This logic is hidden inside methods intentionally.
        // So there is no opportunity to initiate actual asset transfer
        // without user authentication.
        // !!! DO NOT REMOVE FROM HERE
        let transfer = { (securityKey:String) in
            if securityKey.isEmpty {
                return
            }

            var address = self.addressTextField!.text!.trimmingCharacters(in:.whitespaces)
            if address.isEmpty {
                address = self.addressTextField!.placeholder!.trimmingCharacters(in:.whitespaces)
            }

            let amount = Double(self.withdrawAmountTextField!.text!.trimmingCharacters(in:.whitespaces))

            UserDefaults.standard.setValue(securityKey, forKey:UIUtils.SecurityKeySettingsKey)
            UserDefaults.standard.setValue(address, forKey:self.lastUsedWalletSettingsKey)

            let spinner = UIActivityIndicatorView(activityIndicatorStyle:.gray)
            self.view.addSubview(spinner)
            spinner.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
            }
            spinner.startAnimating()

            self.submitButton?.isEnabled = false
            self.addressTextField?.isEnabled = false
            self.withdrawAmountTextField?.isEnabled = false

            TradingPlatformManager.shared.tradingPlatform.assetsHandler?.withdrawAsset?(asset:self.currency,
                                                                                        amount:amount!,
                                                                                        toAddress:address,
                                                                                        securityKey:securityKey,
                                                                                        onCompletion:
                { (succeeded, status) in
                spinner.stopAnimating()
                spinner.removeFromSuperview()

                self.submitButton?.isEnabled = true
                self.addressTextField?.isEnabled = true
                self.withdrawAmountTextField?.isEnabled = true
            })
        }

        if let securityKey = UserDefaults.standard.value(forKey:UIUtils.SecurityKeySettingsKey) as? String {
            UIUtils.authenticate { (succeeded, _) in
                if succeeded {
                    transfer(securityKey)
                }
            }
        }
        else {
            let alert = UIAlertController(title:NSLocalizedString("Two-factor authentication", comment:"Two-factor authentication alert title"),
                                          message:NSLocalizedString("Please enter security key (PIN)", comment:"Enter security key text"),
                                          preferredStyle:.alert)

            alert.addTextField { (textField) in
                textField.placeholder = NSLocalizedString("Security key (PIN)", comment:"Security key placeholder text")
                textField.isSecureTextEntry = true
            }

            alert.addAction(UIAlertAction(title:NSLocalizedString("Submit", comment:"Security key submit button title"),
                                          style:.default,
                                          handler: { (_) in
                let securityKey = alert.textFields![0].text!

                transfer(securityKey)
            }))

            present(alert, animated:true, completion:nil)
        }
    }

    // MARK: Events handling

    @IBAction fileprivate func submitButtonPressed() {
        authenticateAndTransfer()
    }

    // MARK: Outlets

    @IBOutlet weak var availableAmountLabel:UILabel?
    @IBOutlet weak var addressTextField:UITextField?
    @IBOutlet weak var withdrawAmountTextField:UITextField?
    @IBOutlet weak var submitButton:UIButton?

    fileprivate static let CardNumberRegEx = "\\d{16}"
}
