/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`AppDelegate` is the `UIApplicationDelegate` and the `CPApplicationDelegate`.
*/

import UIKit
import CarPlay

@UIApplicationMain
class AppDelegate: UIResponder {
    
    internal var window: UIWindow?
    private var templateManager: TemplateManager?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        templateManager = TemplateManager()

        let loggerViewController = LoggerViewController()
        window?.rootViewController = UINavigationController(rootViewController: loggerViewController)
        window?.makeKeyAndVisible()
        MemoryLogger.shared.delegate = loggerViewController

        MemoryLogger.shared.appendEvent("Application finished launching.")
        
        return true
    }

    // MARK: UIApplicationDelegate

    func applicationDidBecomeActive(_ application: UIApplication) {
        MemoryLogger.shared.appendEvent("Application did become active.")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        MemoryLogger.shared.appendEvent("Application will resign active.")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        MemoryLogger.shared.appendEvent("Application did enter background.")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        MemoryLogger.shared.appendEvent("Application will enter foreground.")
    }
    
}

// MARK: CPApplicationDelegate

extension AppDelegate: CPApplicationDelegate {
    
    func application(_ application: UIApplication, didConnectCarInterfaceController interfaceController: CPInterfaceController,
                     to window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay.")
        templateManager?.interfaceController(interfaceController, didConnectWith: window)
    }
    
    func application(_ application: UIApplication, didDisconnectCarInterfaceController interfaceController: CPInterfaceController,
                     from window: CPWindow) {
        templateManager?.interfaceController(interfaceController, didDisconnectWith: window)
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay.")
    }
    
}

