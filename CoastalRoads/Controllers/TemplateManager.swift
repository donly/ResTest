/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`TemplateManager` manages the CPTemplates displayed in Coastal Roads.
*/

import CarPlay
import Foundation
import os

class TemplateManager: NSObject, CPInterfaceControllerDelegate, CPListTemplateDelegate, CPSessionConfigurationDelegate {

    private var carplayInterfaceController: CPInterfaceController?
    private var carWindow: UIWindow?

    public private(set) var carViewController: MapViewController?
    public private(set) var baseMapTemplate: CPMapTemplate?

    private var currentTravelEstimates: CPTravelEstimates?
    private var navigationSession: CPNavigationSession?
    private var displayLink: CADisplayLink?
    private var activeManeuver: CPManeuver?
    private var activeEstimates: CPTravelEstimates?
    private var lastCompletedManeuverFrame: CGRect?
    private var sessionConfiguration: CPSessionConfiguration!

    override init() {
        super.init()
        sessionConfiguration = CPSessionConfiguration(delegate: self)
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

    // MARK: CPApplicationDelegate

    func interfaceController(_ interfaceController: CPInterfaceController, didConnectWith window: CPWindow) {
        MemoryLogger.shared.appendEvent("Connected to CarPlay window.")

        interfaceController.delegate = self
        carplayInterfaceController = interfaceController

        let mapViewController = MapViewController(nibName: nil, bundle: nil)
        mapViewController.mapViewActionProvider = self

        window.rootViewController = UINavigationController(rootViewController: mapViewController)

        carWindow = window
        carViewController = mapViewController

        guard let traitCollection = carViewController?.traitCollection else { return }

        /// - Tag: did_connect
        let mapTemplate = CPMapTemplate.coastalRoadsMapTemplate(compatibleWith: traitCollection, zoomInAction: {
            MemoryLogger.shared.appendEvent("Map zoom in.")
            mapViewController.zoomIn()
        }, zoomOutAction: {
            MemoryLogger.shared.appendEvent("Map zoom out.")
            mapViewController.zoomOut()
        })

        mapTemplate.mapDelegate = self

        baseMapTemplate = mapTemplate

        installBarButtons()

        interfaceController.setRootTemplate(mapTemplate, animated: true)
    }

    func interfaceController(_ interfaceController: CPInterfaceController, didDisconnectWith window: CPWindow) {
        MemoryLogger.shared.appendEvent("Disconnected from CarPlay window.")
        carplayInterfaceController = nil
        carWindow?.isHidden = true
    }

    // MARK: Template Generators

    func showGridTemplate() {
        guard let carViewController = carViewController else { return }
        let gridTemplate = CPGridTemplate.favoritesGridTemplate(compatibleWith: carViewController.traitCollection) {
            // Set title if it exists, otherwise name it "Favorites".
            button in self.showListTemplate(title: button.titleVariants.first ?? "Favorites")
        }

        carplayInterfaceController?.pushTemplate(gridTemplate, animated: true)
    }

    func showListTemplate(title: String) {
        guard let carViewController = carViewController else { return }

        let listTemplate = CPListTemplate.searchResultsListTemplate(compatibleWith: carViewController.traitCollection, title: title)
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

// MARK: CPMapTemplate UI

extension TemplateManager {

    final private func panButtonPressed(_ sender: Any) {
        baseMapTemplate?.showPanningInterface(animated: true)

        let doneButton = CPBarButton(type: .text) { (_) in
            self.baseMapTemplate?.dismissPanningInterface(animated: true)
            self.installBarButtons()
        }

        doneButton.title = "Done"
        self.baseMapTemplate?.leadingNavigationBarButtons = [ doneButton ]
        self.baseMapTemplate?.trailingNavigationBarButtons = []
    }

    final private func installBarButtons() {
        guard let carViewController = self.carViewController else { return }
        let panButton = CPBarButton(type: .image) { (btn) in
            // Pass panButton as sender.
            self.panButtonPressed(btn)
        }
        panButton.image = UIImage(named: "Pan", in: .main, compatibleWith: carViewController.traitCollection)
        let destsButton = CPBarButton(type: .image) { (_) in
            self.showGridTemplate()
        }
        destsButton.image = UIImage(named: "Favorites", in: Bundle.main, compatibleWith: carViewController.traitCollection)
        baseMapTemplate?.leadingNavigationBarButtons = [panButton]
        baseMapTemplate?.trailingNavigationBarButtons = [destsButton]
    }
}

// MARK: MapViewActionProviding

extension TemplateManager: MapViewActionProviding {

    final func setZoomInEnabled(_ enabled: Bool) {
        if let zoomInButton = baseMapTemplate?.mapButtons.first {
            zoomInButton.isEnabled = enabled
        }
    }

    final func setZoomOutEnabled(_ enabled: Bool) {
        if let zoomOutButton = baseMapTemplate?.mapButtons.last {
            zoomOutButton.isEnabled = enabled
        }
    }
}

// MARK: CPMapTemplateDelegate

extension TemplateManager: CPMapTemplateDelegate {

    func mapTemplate(_ mapTemplate: CPMapTemplate, panWith direction: CPMapTemplate.PanDirection) {
        carViewController?.panInDirection(direction)
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, selectedPreviewFor trip: CPTrip, using routeChoice: CPRouteChoice) {
        carViewController?.setPolylineVisible(true)
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, startedTrip trip: CPTrip, using routeChoice: CPRouteChoice) {
        guard let traitCollection = carViewController?.traitCollection else { return }

        MemoryLogger.shared.appendEvent("Beginning navigation guidance.")

        let navSession = mapTemplate.simulateCoastalRoadsNavigation(trip: trip, routeChoice: routeChoice, traitCollection: traitCollection)
        navigationSession = navSession

        simulateNavigation(for: navSession, maneuvers: mapTemplate.coastalRoadsManeuvers(compatibleWith: traitCollection))
    }

    // When this sample app enters the background you will not continue to see banner notifications.
    // This is because the simulation is driven in conjunction with the CADisplayLink which will pause
    // when the app enters the background.
    func mapTemplate(_ mapTemplate: CPMapTemplate,
                     shouldUpdateNotificationFor maneuver: CPManeuver,
                     with travelEstimates: CPTravelEstimates) -> Bool {
        return true
    }

    func mapTemplate(_ mapTemplate: CPMapTemplate, shouldShowNotificationFor navigationAlert: CPNavigationAlert) -> Bool {
        return true
    }
}

// MARK: Navigation

extension TemplateManager {

    final private func beginNavigation() {
        let cancelButton = CPBarButton(type: .text) { (_) in
            self.endNavigation(cancelled: true)
        }
        cancelButton.title = "Cancel"

        let route = CPRouteChoice(summaryVariants: ["via Solar Circle"],
                                  additionalInformationVariants: ["Possible meteor shower."],
                                  selectionSummaryVariants: [])

        let destinationItem = MKMapItem(placemark: MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 0, longitude: 0)))
        destinationItem.name = "Mars Meadow"
        let trip = CPTrip(origin: MKMapItem(), destination: destinationItem, routeChoices: [route])

        let estimates = CPTravelEstimates(distanceRemaining: NSMeasurement(doubleValue: 4500, unit: UnitLength.meters) as Measurement<UnitLength>,
                                          timeRemaining: 360)
        currentTravelEstimates = estimates

        baseMapTemplate?.showTripPreviews([trip],
                                          textConfiguration: CPTripPreviewTextConfiguration(startButtonTitle: "Launch",
                                                                                            additionalRoutesButtonTitle: "More Routes",
                                                                                            overviewButtonTitle: "Overview"))
        baseMapTemplate?.updateEstimates(estimates, for: trip)
        baseMapTemplate?.leadingNavigationBarButtons = [cancelButton]
        baseMapTemplate?.trailingNavigationBarButtons = []
        carViewController?.setPolylineVisible(true)
        carViewController?.mapView.zoomToLocation(.routeOverview)
    }

    final private func endNavigation(cancelled: Bool) {
        MemoryLogger.shared.appendEvent("Navigation guidance ended.")

        displayLink?.invalidate()
        displayLink = nil

        if cancelled {
            navigationSession?.cancelTrip()
        } else {
            navigationSession?.finishTrip()
        }

        activeManeuver = nil
        activeEstimates = nil
        lastCompletedManeuverFrame = nil
        currentTravelEstimates = nil

        baseMapTemplate?.hideTripPreviews()
        installBarButtons()
        carViewController?.setPolylineVisible(false)
        carViewController?.mapView.zoomToLocation(.routeOverview)
    }

    @objc
    func displayLinkFired(_ sender: CADisplayLink) {
        guard let maneuver = self.activeManeuver else { return }
        guard let estimates = self.activeEstimates else { return }
        guard let maneuverEndValue = maneuver.userInfo as? NSValue else { return }
        guard let maneuverStartFrame = self.lastCompletedManeuverFrame else { return }
        let maneuverEndFrame = maneuverEndValue.cgRectValue

        let totalDistance = maneuver.initialTravelEstimates?.distanceRemaining.value ?? 0
        let completedDistance = totalDistance - estimates.distanceRemaining.value
        let progress = CGFloat(completedDistance / totalDistance)

        guard progress >= 0 && progress < 1 else { return }

        func interpolate(start: CGFloat, end: CGFloat, progress: CGFloat) -> CGFloat {
            return start + ((end - start) * progress)
        }

        let interpolatedRect = CGRect(x: interpolate(start: maneuverStartFrame.origin.x,
                                                     end: maneuverEndFrame.origin.x, progress: progress),
                                      y: interpolate(start: maneuverStartFrame.origin.y,
                                                     end: maneuverEndFrame.origin.y, progress: progress),
                                      width: interpolate(start: maneuverStartFrame.size.width,
                                                         end: maneuverEndFrame.size.width, progress: progress),
                                      height: interpolate(start: maneuverStartFrame.size.height,
                                                          end: maneuverEndFrame.size.height, progress: progress)
            ).integral

        carViewController?.mapView.setContentOffset(interpolatedRect.origin, animated: false)
    }

    final private func evaluateManeuver(maneuver: CPManeuver, currentManeuverIndex: Int) {
        switch currentManeuverIndex {
        case 0: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeOrigin.frame)
        case 1: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeTurn1.frame)
        case 2: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeTurn2.frame)
        case 3: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeTurn3.frame)
        case 4: maneuver.userInfo = NSValue(cgRect: CRZoomLocation.routeDestination.frame)
        default: break
        }
    }

    final private func updateDistance(_ distance: Double, for maneuver: CPManeuver, session: CPNavigationSession) {
        DispatchQueue.main.sync {
            let newDistance = Measurement(value: distance, unit: UnitLength.meters)
            let estimates = CPTravelEstimates(distanceRemaining: newDistance as Measurement<UnitLength>, timeRemaining: 0)
            self.activeEstimates = estimates
            session.updateEstimates(estimates, for: maneuver)
        }
    }

    // In a real CarPlay app, actual navigation should occur. This method is purely for simulation purposes.
    final private func simulateNavigation(for session: CPNavigationSession, maneuvers: [CPManeuver]) {
        var currentManeuverIndex = 0
        var completedRoute = false

        // At the start of guidance, move the viewport to the first point of interest.
        carViewController?.mapView.zoomToLocation(.routeTurn1)

        if let currentDisplayLink = carViewController?.view.window?.screen.displayLink(withTarget: self, selector: #selector(displayLinkFired(_:))) {
            currentDisplayLink.add(to: .main, forMode: .common)
            displayLink = currentDisplayLink
        }

        // Since this is a simulation with an image instead of an actual route, disable zoom to prevent going off screen.
        setZoomInEnabled(false)
        setZoomOutEnabled(false)

        DispatchQueue.global(qos: .background).async {
            repeat {
                DispatchQueue.main.sync {
                    if currentManeuverIndex < maneuvers.count {

                        if currentManeuverIndex > 0 {
                            self.lastCompletedManeuverFrame = (maneuvers[currentManeuverIndex - 1].userInfo as? NSValue)?.cgRectValue
                        }

                        let maneuver = maneuvers[currentManeuverIndex]
                        self.activeManeuver = maneuver
                        session.upcomingManeuvers = [maneuver]
                        currentManeuverIndex += 1
                        self.evaluateManeuver(maneuver: maneuver, currentManeuverIndex: currentManeuverIndex)
                    } else {
                        completedRoute = true
                        self.endNavigation(cancelled: false)
                    }
                }

                guard var distance = self.activeManeuver?.initialTravelEstimates?.distanceRemaining.value else { continue }
                // Update the distance panel and drive the simulation by decrementing the distance in a while loop.
                repeat {
                    guard let maneuver = self.activeManeuver else { return }
                    self.updateDistance(distance, for: maneuver, session: session)
                    distance -= 5
                    usleep(600)
                } while (distance >= 0)

                let remainingSteps = maneuvers.count - currentManeuverIndex - 1
                let multiplier = Double(remainingSteps) / Double(maneuvers.count)
                let distanceRemaining = max(0, (self.currentTravelEstimates?.distanceRemaining.value ?? 0) * multiplier)
                let timeRemaining = max(0, (self.currentTravelEstimates?.timeRemaining ?? 0) * multiplier)

                let tripDistance = Measurement(value: distanceRemaining, unit: UnitLength.meters)
                let newEstimates = CPTravelEstimates(distanceRemaining: tripDistance,
                                                     timeRemaining: timeRemaining)

                self.baseMapTemplate?.updateEstimates(newEstimates, for: session.trip)

            } while (!completedRoute)
        }
    }
}
