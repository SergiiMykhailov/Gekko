//  Created by Sergii Mykhailov on 13/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

class BTCTradeUAAccountSettingsViewController : UIViewController {

    // MARK: Public methods and properties

public static let PublicKeySettingsKey = "Public Key"
public static let PrivateKeySettingsKey = "Private Key"

    // MARK: Overriden methods

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = NSLocalizedString("Account Settings", comment:"Account settings view controller title")

        instructionLabel?.text = NSLocalizedString("Please specify public and private keys in order to perform trading operations\nTo obtain these keys please login to your account at www.btc-trade.com.ua and go to:\nAccount -> Profile -> API and mobile app",
                                                   comment:"Settings instruction")

        publicKeyLabel?.text = NSLocalizedString("Public Key", comment:"Public key label")
        publicKeyField?.placeholder = NSLocalizedString("Public Key", comment:"Public key label")

        privateKeyLabel?.text = NSLocalizedString("Private Key", comment:"Private key label")
        privateKeyField?.placeholder = NSLocalizedString("Private Key", comment:"Private key label")

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:NSLocalizedString("Done", comment:"Done button title"),
                                                                 style:.done,
                                                                 target:self,
                                                                 action:#selector(applyButtonPressed))
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: NSLocalizedString("Back", comment:"Back navigation button"), style: .plain, target: self, action: #selector(backButtonPressed))
    }

    override func prepare(for segue:UIStoryboardSegue, sender:Any?) {
        if let qrPickerController = segue.destination as? QRCodePickerViewController {
            if segue.identifier == BTCTradeUAAccountSettingsViewController.PickPublicKeySegueIdentifier {
                captureKey(forInputField:publicKeyField!,
                           withPicker:qrPickerController)
            }
            else if segue.identifier == BTCTradeUAAccountSettingsViewController.PickPrivateKeySegueIdentifier {
                captureKey(forInputField:privateKeyField!,
                           withPicker:qrPickerController)
            }
        }
    }

    // MARK: Internal methods

    fileprivate func captureKey(forInputField inputField:UITextField,
                                withPicker controller:QRCodePickerViewController) {
        qrCodeCaptureHandler = QRCodeCaptureHandler(withCompletionBlock: {
            [weak inputField] (capturedKey) in
            if inputField != nil {
                inputField!.text = capturedKey
            }

            controller.dismiss(animated:true, completion:nil)
        })

        controller.delegate = qrCodeCaptureHandler
    }

    // MARK: Events handling

    @objc func applyButtonPressed() {
        let publicKey = publicKeyField?.text
        let privateKey = privateKeyField?.text

        if publicKey != nil && privateKey != nil {
            BTCTradeUALoginSession.loginIfNeeded(withPublicKey: publicKey!,
                                                 privateKey: privateKey!,
                                                 completionCallback: { (succeeded) in
                DispatchQueue.main.async { [weak self] () in
                    if (self != nil && succeeded) {
                        let userDefaults = UserDefaults.standard
                        
                        userDefaults.set(publicKey!,
                                         forKey:BTCTradeUAAccountSettingsViewController.PublicKeySettingsKey)
                        userDefaults.set(privateKey,
                                         forKey:BTCTradeUAAccountSettingsViewController.PrivateKeySettingsKey)
                        
                        self!.navigationController?.popViewController(animated:true)
                    }
                    else {
                        let alert = UIAlertController(title: NSLocalizedString("Authorization failed", comment: "Alert title"),
                                                      message: NSLocalizedString("Invalid public/private key", comment: "Invalid key"),
                                                      preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: NSLocalizedString("Close", comment: "Close alert action"),
                                                      style: .`default`,
                                                      handler: { _ in
                            self!.publicKeyField!.text = String()
                            self!.privateKeyField!.text = String()
                        }))
                        
                        self!.present(alert, animated: true, completion: nil)
                    }
                }
            })
        }
    }
    
    @objc func backButtonPressed() {
        self.navigationController?.popViewController(animated:true)
    }

    // MARK: Outlets

    @IBOutlet weak var instructionLabel:UILabel?

    @IBOutlet weak var publicKeyLabel:UILabel?
    @IBOutlet weak var publicKeyField:UITextField?

    @IBOutlet weak var privateKeyLabel:UILabel?
    @IBOutlet weak var privateKeyField:UITextField?

    // MARK: Internal fields

    fileprivate var qrCodeCaptureHandler:QRCodeCaptureHandler?

    fileprivate static let PickPrivateKeySegueIdentifier = "Pick Private Key"
    fileprivate static let PickPublicKeySegueIdentifier = "Pick Public Key"

    internal class QRCodeCaptureHandler : NSObject, QRCodePickerViewControllerDelegate {

        typealias QRCodeCaptureCompletionBlock = (String) -> Void

        init(withCompletionBlock block:@escaping QRCodeCaptureCompletionBlock) {
            self.completionBlock = block
        }

        // MARK: QRCodePickerViewControllerDelegate implementation

        func qrCodePicker(sender:QRCodePickerViewController, didPick key:String) {
            if completionBlock != nil {
                completionBlock!(key)
            }
        }

        internal var completionBlock:QRCodeCaptureCompletionBlock?
    }
}
