import Foundation
import XCTest

extension XCUIApplication {

    func writeOnTextField(textFieldIdentifier: String, string: String) {
        let textField = self.textFields[textFieldIdentifier]
        textField.tap()
        textField.typeText(string)
    }
}
