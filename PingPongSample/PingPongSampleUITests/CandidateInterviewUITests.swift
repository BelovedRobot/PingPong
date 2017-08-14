import XCTest

@testable import CandidateInterview

class CandidateInterviewUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUp() {
        super.setUp()

        continueAfterFailure = false
        app = XCUIApplication()

        app.launchArguments.append("--uitesting")
    }

    func testTeamsTable_hasThreeItems() {
        app.launch()

        XCTAssert(app.tables.staticTexts["Test0"].exists)
        XCTAssert(app.tables.staticTexts["Test1"].exists)
        XCTAssert(app.tables.staticTexts["Test2"].exists)
    }

    func testClickOnTeam_showsCorrectDetail() {
        app.launch()

        app.cells.element(boundBy: 0).tap()

        XCTAssert(app.staticTexts["Test0"].exists)
        XCTAssert(app.staticTexts["TestNickname0"].exists)
        XCTAssert(app.staticTexts["TestSport0"].exists)
        XCTAssert(app.staticTexts["TestColor0"].exists)
        XCTAssert(app.tables.staticTexts["Player0"].exists)
    }

    func testClickOnCreateTeam_showsTheRightController() {
        app.launch()

        app.buttons["Add"].tap()

        XCTAssert(app.staticTexts["Create team"].exists)
    }

    func testCreateTeam_showsTeamOnTeamsView() {
        app.launch()

        app.buttons["Add"].tap()

        app.writeOnTextField(textFieldIdentifier: "Name", string: "Chicago Bulls")
        app.writeOnTextField(textFieldIdentifier: "Sport", string: "Basketball")
        app.writeOnTextField(textFieldIdentifier: "Nickname", string: "The Bulls")
        app.writeOnTextField(textFieldIdentifier: "Color", string: "Red")

        app.buttons["Save"].tap()
        app.buttons["Ok"].tap()

        XCTAssert(app.tables.staticTexts["Chicago Bulls"].exists)
    }

    func testCreateTeamWithEmptyFields_showMessageError() {
        app.launch()

        app.buttons["Add"].tap()

        app.writeOnTextField(textFieldIdentifier: "Sport", string: "Basketball")
        app.writeOnTextField(textFieldIdentifier: "Nickname", string: "The Bulls")
        app.writeOnTextField(textFieldIdentifier: "Color", string: "Red")

        app.buttons["Save"].tap()

        XCTAssert(app.staticTexts["Fields cannot be empty"].exists)
    }

    func testCreateTeam_successFullyAddsPlayers() {
        app.launch()

        app.buttons["Add"].tap()

        app.writeOnTextField(textFieldIdentifier: "Player", string: "Stephen Curry")
        app.buttons["Add"].tap()
        app.writeOnTextField(textFieldIdentifier: "Player", string: "Kevin Durant")
        app.buttons["Add"].tap()

        XCTAssert(app.tables.staticTexts["Stephen Curry"].exists)
        XCTAssert(app.tables.staticTexts["Kevin Durant"].exists)
    }
}

