//  Created by Sergii Mykhailov on 28/06/2018.
//  Copyright © 2018 Sergii Mykhailov. All rights reserved.
//

import Foundation
import UIKit

class NavigatableViewController : UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        setupBackButton()
    }

    // MARK: Internal methods

    fileprivate func setupBackButton() {
        let button = UIButton(type:.system)

        button.setImage(#imageLiteral(resourceName: "backArrow"), for:.normal)
        button.setTitle(NSLocalizedString("Back", comment:"Back navigation button"), for:.normal)
        button.sizeToFit()
        button.addTarget(self, action:#selector(backButtonPressed), for:.touchUpInside)

        let backButtonItem = UIBarButtonItem(customView:button)

        self.navigationItem.leftBarButtonItem = backButtonItem
    }

    // MARK: Actions

    @IBAction func backButtonPressed(_ sender: UISwipeGestureRecognizer) {
        self.navigationController?.popViewController(animated:true)
    }
}
