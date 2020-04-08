/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`TemplateApplicationSceneDelegate` is the delegate for the `CPTemplateApplicationScene` on the CarPlay display.
*/

import CarPlay
import UIKit

class TemplateApplicationSceneDelegate: NSObject {
    
    let templateManager = TemplateManager()
    
    // MARK: UISceneDelegate
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if scene is CPTemplateApplicationScene, session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene will connect.")
        } else if scene is CPTemplateApplicationDashboardScene, session.configuration.name == "DashboardSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application dashboard scene will connect.")
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did disconnect.")
        } else if scene.session.configuration.name == "DashboardSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application dashboard scene did disconnect.")
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did become active.")
        } else if scene.session.configuration.name == "DashboardSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application dashboard scene did become active.")
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene will resign active.")
        } else if scene.session.configuration.name == "DashboardSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application dashboard scene will resign active.")
        }
    }
    
}

// MARK: CPTemplateApplicationSceneDelegate

extension TemplateApplicationSceneDelegate: CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")
        templateManager.interfaceController(interfaceController, didConnectWith: window)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        templateManager.interfaceController(interfaceController, didDisconnectWith: window)
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay.")
    }
}

extension TemplateApplicationSceneDelegate: CPTemplateApplicationDashboardSceneDelegate {
    
    func templateApplicationDashboardScene(
        _ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene,
        didConnect dashboardController: CPDashboardController,
        to window: UIWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay dashboard.")
        templateManager.dashboardController(dashboardController, didConnectWith: window)
    }
    
    func templateApplicationDashboardScene(
        _ templateApplicationDashboardScene: CPTemplateApplicationDashboardScene,
        didDisconnect dashboardController: CPDashboardController,
        from window: UIWindow) {
        templateManager.dashboardController(dashboardController, didDisconnectWith: window)
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay dashboard.")
    }
}
