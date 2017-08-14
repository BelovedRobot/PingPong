import Foundation
import UIKit

class BaseViewController: UIViewController {

    func showMessage(title: String, message: String, completion: (() -> Void)?) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)

        alert.addAction(UIAlertAction(title: "Ok", style: .default, handler: { (action: UIAlertAction!) in
            if let completion = completion {
                completion()
            }
        }))

        self.present(alert, animated: true, completion: nil)
    }
}
