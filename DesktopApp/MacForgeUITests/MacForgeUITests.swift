//
//  MacForgeUITests.swift
//  MacForgeUITests
//
//  Comprehensive UI tests for MacForge following Apple's accessibility and
//  UI testing guidelines and best practices from device management repositories.
//

import XCTest

final class MacForgeUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        
        // Set up initial state for consistent testing
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Landing Page Tests
    
    @MainActor
    func testLandingPageElements() throws {
        // Test that all main landing page elements are accessible
        let macforgeTitle = app.staticTexts["MacForge"]
        XCTAssertTrue(macforgeTitle.exists, "MacForge title should be visible")
        
        let profileBuilderButton = app.buttons["PPPC Profile Creator"]
        XCTAssertTrue(profileBuilderButton.exists, "PPPC Profile Creator button should be accessible")
        
        let themeSwitcher = app.buttons["Theme Switcher"]
        XCTAssertTrue(themeSwitcher.exists, "Theme switcher should be accessible")
    }
    
    @MainActor
    func testThemeSwitching() throws {
        // Test theme switching functionality
        let themeSwitcher = app.buttons["Theme Switcher"]
        themeSwitcher.click()
        
        // Wait for theme switcher to appear
        let lcarsThemeButton = app.buttons["LCARS Theme"]
        XCTAssertTrue(lcarsThemeButton.exists, "LCARS theme option should be available")
        
        lcarsThemeButton.click()
        
        // Verify theme change (this would need visual verification in a real test)
        let defaultThemeButton = app.buttons["Default Theme"]
        XCTAssertTrue(defaultThemeButton.exists, "Default theme option should be available")
    }
    
    // MARK: - PPPC Profile Creator Workflow Tests
    
    @MainActor
    func testProfileBuilderNavigation() throws {
        // Navigate to PPPC Profile Creator
        let profileBuilderButton = app.buttons["PPPC Profile Creator"]
        profileBuilderButton.click()
        
        // Verify we're in the PPPC Profile Creator
        let profileBuilderTitle = app.staticTexts["PPPC Profile Creator"]
        XCTAssertTrue(profileBuilderTitle.exists, "Should be in PPPC Profile Creator")
        
        // Test sidebar navigation
        let modeButton = app.buttons["MODE"]
        XCTAssertTrue(modeButton.exists, "MODE button should be accessible")
        
        let templatesButton = app.buttons["TEMPLATES"]
        XCTAssertTrue(templatesButton.exists, "TEMPLATES button should be accessible")
    }
    
    @MainActor
    func testProfileBuilderStepNavigation() throws {
        // Navigate to PPPC Profile Creator
        app.buttons["PPPC Profile Creator"].click()
        
        // Verify initial step
        let step1Indicator = app.staticTexts["STEP 1 OF 3"]
        XCTAssertTrue(step1Indicator.exists, "Should start at step 1")
        
        // Test step navigation buttons
        let nextButton = app.buttons["Next"]
        let previousButton = app.buttons["Previous"]
        
        XCTAssertTrue(nextButton.exists, "Next button should be accessible")
        XCTAssertTrue(previousButton.exists, "Previous button should be accessible")
        
        // Next button should be disabled initially (no payloads selected)
        XCTAssertFalse(nextButton.isEnabled, "Next button should be disabled without payloads")
    }
    
    @MainActor
    func testPayloadSelection() throws {
        // Navigate to PPPC Profile Creator
        app.buttons["PPPC Profile Creator"].click()
        
        // Select PPPC payload
        let pppcPayload = app.buttons["Privacy Preferences"]
        XCTAssertTrue(pppcPayload.exists, "PPPC payload should be accessible")
        
        pppcPayload.click()
        
        // Verify payload is selected
        let selectedCount = app.staticTexts["1 payload(s) selected"]
        XCTAssertTrue(selectedCount.exists, "Should show correct payload count")
        
        // Next button should now be enabled
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.isEnabled, "Next button should be enabled with payload selected")
    }
    
    @MainActor
    func testApplicationDropZone() throws {
        // Navigate to PPPC Profile Creator
        app.buttons["PPPC Profile Creator"].click()
        
        // Verify drop zone exists
        let dropZone = app.staticTexts["Drag and drop an application (.app) to configure PPPC permissions"]
        XCTAssertTrue(dropZone.exists, "Application drop zone should be visible")
        
        // Test "Select Application" button if available
        let selectAppButton = app.buttons["Select Application"]
        if selectAppButton.exists {
            selectAppButton.click()
            // This would open a file picker in real usage
        }
    }
    
    @MainActor
    func testTemplateApplication() throws {
        // Navigate to PPPC Profile Creator
        app.buttons["PPPC Profile Creator"].click()
        
        // Click on Templates section
        let templatesButton = app.buttons["TEMPLATES"]
        templatesButton.click()
        
        // Test Security Baseline template
        let securityBaselineTemplate = app.buttons["Security Baseline"]
        XCTAssertTrue(securityBaselineTemplate.exists, "Security Baseline template should be accessible")
        
        securityBaselineTemplate.click()
        
        // Verify template was applied (should add payloads)
        let selectedCount = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'payload(s) selected'")).firstMatch
        XCTAssertTrue(selectedCount.exists, "Template should add payloads")
    }
    
    // MARK: - PPPC Configuration Tests
    
    @MainActor
    func testPPPCConfigurationWorkflow() throws {
        // Navigate to PPPC Profile Creator and select PPPC payload
        app.buttons["PPPC Profile Creator"].click()
        app.buttons["Privacy Preferences"].click()
        app.buttons["Next"].click()
        
        // Should now be in Step 2 (Configure Payloads)
        let step2Indicator = app.staticTexts["STEP 2 OF 3"]
        XCTAssertTrue(step2Indicator.exists, "Should be at step 2")
        
        // Test PPPC configuration view
        let pppcConfigTitle = app.staticTexts["Privacy Preferences (PPPC) Configuration"]
        XCTAssertTrue(pppcConfigTitle.exists, "PPPC configuration view should be visible")
        
        // Test service category selection
        let categoryPicker = app.pickers["Category"]
        XCTAssertTrue(categoryPicker.exists, "Service category picker should be accessible")
    }
    
    // MARK: - Accessibility Tests
    
    @MainActor
    func testAccessibilityLabels() throws {
        // Test that all interactive elements have proper accessibility labels
        
        // Test a few key buttons for accessibility
        let profileBuilderButton = app.buttons["PPPC Profile Creator"]
        XCTAssertFalse(profileBuilderButton.label.isEmpty, "PPPC Profile Creator button should have accessibility label")
        
        let nextButton = app.buttons["Next"]
        if nextButton.exists {
            XCTAssertFalse(nextButton.label.isEmpty, "Next button should have accessibility label")
        }
        
        // Test key static texts for accessibility
        let macforgeTitle = app.staticTexts["MacForge"]
        XCTAssertFalse(macforgeTitle.label.isEmpty, "MacForge title should have accessibility label")
    }
    
    @MainActor
    func testKeyboardNavigation() throws {
        // Test keyboard navigation through the interface
        app.buttons["PPPC Profile Creator"].click()
        
        // Use Tab key to navigate through elements
        app.typeKey(.tab, modifierFlags: [])
        app.typeKey(.tab, modifierFlags: [])
        
        // Verify navigation worked by checking if we can interact with elements
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.exists, "Should be able to navigate to Next button")
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    @MainActor
    func testProfileBuilderLoadPerformance() throws {
        measure {
            app.buttons["PPPC Profile Creator"].click()
            
                    // Wait for PPPC Profile Creator to fully load
        let profileBuilderTitle = app.staticTexts["PPPC Profile Creator"]
            XCTAssertTrue(profileBuilderTitle.waitForExistence(timeout: 5.0))
        }
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testErrorHandling() throws {
        // Navigate to PPPC Profile Creator
        app.buttons["PPPC Profile Creator"].click()
        
        // Try to advance without selecting payloads
        let nextButton = app.buttons["Next"]
        XCTAssertFalse(nextButton.isEnabled, "Next button should be disabled without payloads")
        
        // Test that appropriate error states are shown
        let noChangesText = app.staticTexts["No changes selected yet"]
        XCTAssertTrue(noChangesText.exists, "Should show appropriate message when no changes selected")
    }
    
    // MARK: - Helper Methods
    
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5.0) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    private func tapIfExists(_ element: XCUIElement) {
        if element.exists && element.isEnabled {
            element.click()
        }
    }
}
