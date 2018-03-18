//  Created by Sergii Mykhailov on 14/12/2017.
//  Copyright © 2017 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation

@objc protocol QRCodePickerViewControllerDelegate : class {

    @objc optional func qrCodePicker(sender:QRCodePickerViewController,
                                     didPick key:String) -> Void

}

class QRCodePickerViewController : UIViewController,
                                   AVCaptureMetadataOutputObjectsDelegate {

    public weak var delegate:QRCodePickerViewControllerDelegate?

    // MARK: Overriden methods

    override func viewDidLoad() {
        super.viewDidLoad()

        let captureDevice = AVCaptureDevice.default(for:.video)

        let input = try? AVCaptureDeviceInput(device:captureDevice!)

        captureSession = AVCaptureSession()
        captureSession?.addInput(input! as AVCaptureInput)

        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession?.addOutput(captureMetadataOutput)

        captureMetadataOutput.setMetadataObjectsDelegate(self, queue:DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]

        qrCodeFrameView = UIView()
        qrCodeFrameView?.layer.borderColor = UIColor.green.cgColor
        qrCodeFrameView?.layer.borderWidth = 2
        view.addSubview(qrCodeFrameView!)
        view.bringSubview(toFront:qrCodeFrameView!)

        videoPreviewLayer = AVCaptureVideoPreviewLayer(session:captureSession!)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
        
        setupTopBar()

        captureSession?.startRunning()
    }

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        captureSession?.stopRunning()

        super.dismiss(animated:flag, completion:completion)
    }

    // MARK: AVCaptureMetadataOutputObjectsDelegate implementation

    func metadataOutput(_ output:AVCaptureMetadataOutput,
                        didOutput metadataObjects:[AVMetadataObject],
                        from connection: AVCaptureConnection) {
        // Check if the metadataObjects array is not nil and it contains at least one object.
        if metadataObjects.count == 0 {
            qrCodeFrameView?.frame = CGRect.zero
            return
        }

        // Get the metadata object.
        let metadataObj = metadataObjects[0] as! AVMetadataMachineReadableCodeObject

        if metadataObj.type == AVMetadataObject.ObjectType.qr {
            // If the found metadata is equal to the QR code metadata then update the status label's text and set the bounds
            let barCodeObject = videoPreviewLayer?.transformedMetadataObject(for:metadataObj as AVMetadataMachineReadableCodeObject) as! AVMetadataMachineReadableCodeObject
            qrCodeFrameView?.frame = barCodeObject.bounds;
            view.bringSubview(toFront:qrCodeFrameView!)

            if metadataObj.stringValue != nil {
                delegate?.qrCodePicker!(sender:self, didPick:metadataObj.stringValue!)
            }
        }
    }
    
    // MARK: Internal methods
    
    fileprivate func setupTopBar() {
        let topBar = UIView()
        topBar.backgroundColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        topBar.alpha = UIDefaults.TopBarOpacity
        
        view.addSubview(topBar)
        
        topBar.snp.makeConstraints { (make) in
            make.top.equalToSuperview()
            make.left.equalToSuperview()
            make.width.equalToSuperview()
            make.height.equalTo(60)
        }
        
        let label = UILabel()
        label.text = NSLocalizedString("Scan", comment:"TopBar label")
        label.font = UIFont.systemFont(ofSize:UIDefaults.TopBarFontSize)
        label.textAlignment = .center
        label.textColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
        
        topBar.addSubview(label)
        
        label.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-UIDefaults.Spacing)
        }
        
        let cancelButton = UIButton(type:.system)
        cancelButton.addTarget(self, action:#selector(cancelButtonPressed), for:.touchUpInside)
        cancelButton.setImage(#imageLiteral(resourceName: "cross"), for:.normal)
        cancelButton.tintColor = #colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)

        topBar.addSubview(cancelButton)

        cancelButton.snp.makeConstraints { (make) in
            make.bottom.equalToSuperview().offset(-12)
            make.right.equalToSuperview().offset(-12)
            make.height.equalTo(18)
            make.width.equalTo(18)
        }
    }
    
    // MARK: Actions
    
    @objc func cancelButtonPressed() {
        self.dismiss(animated:true)
    }

    // MARK: Internal fields
    
    var captureSession:AVCaptureSession?
    var videoPreviewLayer:AVCaptureVideoPreviewLayer?
    var qrCodeFrameView:UIView?
}
