/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`TemplateApplicationSceneDelegate` is the delegate for the `CPTemplateApplicationScene` on the CarPlay display.
*/

import CarPlay
import UIKit

class TemplateApplicationSceneDelegate: NSObject {
    
    private var templateManager: TemplateManager?
    
    // MARK: UISceneDelegate
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if scene is CPTemplateApplicationScene, session.configuration.name == "TemplateSceneConfiguration" {
            templateManager = TemplateManager()
            MemoryLogger.shared.appendEvent("Template application scene will connect.")
        }
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did disconnect.")
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene did become active.")
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        if scene.session.configuration.name == "TemplateSceneConfiguration" {
            MemoryLogger.shared.appendEvent("Template application scene will resign active.")
        }
    }
    
}

// MARK: CPTemplateApplicationSceneDelegate

extension TemplateApplicationSceneDelegate: CPTemplateApplicationSceneDelegate {
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didConnect interfaceController: CPInterfaceController, to window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")
        templateManager?.interfaceController(interfaceController, didConnectWith: window)
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene,
                                  didDisconnect interfaceController: CPInterfaceController, from window: CPWindow) {
        templateManager?.interfaceController(interfaceController, didDisconnectWith: window)
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay.")
    }
}
