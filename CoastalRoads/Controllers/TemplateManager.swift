/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`TemplateManager` manages the CPTemplates displayed in Coastal Roads.
*/

import CarPlay
import Foundation
import os

class TemplateManager: NSObject, CPInterfaceControllerDelegate, CPListTemplateDelegate, CPSessionConfigurationDelegate {
//  func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPBaseListItem, completionHandler: @escaping () -> Void) {
//    print("listTemplate, didSelect")
//  }
  

    private var carplayInterfaceController: CPInterfaceController?
    private var carWindow: UIWindow?

    public private(set) var baseMapTemplate: CPMapTemplate?

    var currentTravelEstimates: CPTravelEstimates?
    var navigationSession: CPNavigationSession?
    var displayLink: CADisplayLink?
    var activeManeuver: CPManeuver?
    var activeEstimates: CPTravelEstimates?
    var lastCompletedManeuverFrame: CGRect?
    var sessionConfiguration: CPSessionConfiguration!
    
    let mapViewController = MapViewController(nibName: nil, bundle: nil)

    override init() {
        super.init()
        sessionConfiguration = CPSessionConfiguration(delegate: self)
        mapViewController.mapViewActionProvider = self
    }

    // MARK: CPInterfaceControllerDelegate

    func templateWillAppear(_ aTemplate: CPTemplate, animated: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) will appear.")
    }

    func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) did appear.")
    }

    func templateWillDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) will disappear.")
    }

    func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        MemoryLogger.shared.appendEvent("Template \(aTemplate.classForCoder) did disappear.")
    }

    // MARK: CPSessionConfigurationDelegate

    func sessionConfiguration(_ sessionConfiguration: CPSessionConfiguration,
                              limitedUserInterfacesChanged limitedUserInterfaces: CPLimitableUserInterface) {
        MemoryLogger.shared.appendEvent("Limited UI changed: \(limitedUserInterfaces)")
    }

    // MARK: CPMapTemplateDelegate

    func mapTemplateDidShowPanningInterface(_ mapTemplate: CPMapTemplate) {
        MemoryLogger.shared.appendEvent("Showing map panning interface.")
    }

    func mapTemplateDidDismissPanningInterface(_ mapTemplate: CPMapTemplate) {
        MemoryLogger.shared.appendEvent("Dismissed map panning interface.")
    }
    
    // MARK: CPTemplateApplicationDashboardSceneDelegate
    
    func dashboardController(_ dashboardController: CPDashboardController, didConnectWith window: UIWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay dashboard window.")
        
        let aButton = CPDashboardButton(
            titleVariants: ["Beaches"],
            subtitleVariants: ["Beach Trip"],
            image: #imageLiteral(resourceName: "gridBeaches")) { (button) in
                self.beginNavigation()
        }
        
        let bButton = CPDashboardButton(
            titleVariants: ["Parks"],
            subtitleVariants: ["Park Trip"],
            image: #imageLiteral(resourceName: "gridParks")) { (button) in
                self.beginNavigation()
        }

        window.rootViewController = mapViewController
        
        dashboardController.shortcutButtons = [aButton, bButton]
    }

    func dashboardController(_ dashboardController: CPDashboardController, didDisconnectWith window: UIWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay dashboard window.")
    }

    // MARK: CPTemplateApplicationSceneDelegate

    func interfaceController(_ interfaceController: CPInterfaceController, didConnectWith window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay window.")
        interfaceController.delegate = self
        carplayInterfaceController = interfaceController
      mapViewController.cpWindow = window
        window.rootViewController = mapViewController

        carWindow = window

        /// - Tag: did_connect
        let mapTemplate = CPMapTemplate.coastalRoadsMapTemplate(compatibleWith: mapViewController.traitCollection, zoomInAction: {
            MemoryLogger.shared.appendEvent("Map zoom in.")
            self.mapViewController.zoomIn()
        }, zoomOutAction: {
            MemoryLogger.shared.appendEvent("Map zoom out.")
            self.mapViewController.zoomOut()
        })

        mapTemplate.mapDelegate = self

        baseMapTemplate = mapTemplate

//        installBarButtons()

//        interfaceController.setRootTemplate(mapTemplate, animated: true)
    }

    func interfaceController(_ interfaceController: CPInterfaceController, didDisconnectWith window: CPWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay window.")
        carplayInterfaceController = nil
        carWindow?.isHidden = true
    }

    // MARK: Template Generators

    func showGridTemplate() {
        let gridTemplate = CPGridTemplate.favoritesGridTemplate(compatibleWith: mapViewController.traitCollection) {
            // Set title if it exists, otherwise name it "Favorites".
            button in self.showListTemplate(title: button.titleVariants.first ?? "Favorites")
        }

        carplayInterfaceController?.pushTemplate(gridTemplate, animated: true)
    }

    func showListTemplate(title: String) {
        let listTemplate = CPListTemplate.searchResultsListTemplate(compatibleWith: mapViewController.traitCollection, title: title)
        listTemplate.delegate = self

        carplayInterfaceController?.pushTemplate(listTemplate, animated: true)
    }

    // MARK: CPListTemplateDelegate

    func listTemplate(_ listTemplate: CPListTemplate, didSelect item: CPListItem, completionHandler: @escaping () -> Void) {
        carplayInterfaceController?.popToRootTemplate(animated: true)
        /// In your application, you might extract the destination the user selected rather than navigate to the same place every time :
        // guard let destination = item.userInfo as? MKMapItem else { completionHandler(); return }
        beginNavigation()
        completionHandler()
    }
}

