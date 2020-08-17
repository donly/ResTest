/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`MapViewController` is the root view controller for the car screen. It hosts an instance of `MapScrollView`.
*/

import Foundation
import CarPlay
import MapKit

/**
 `MapViewActionProviding` describes an external object that can trigger UI updates in the map view.
 */
protocol MapViewActionProviding {
    func setZoomInEnabled(_ enabled: Bool)
    func setZoomOutEnabled(_ enabled: Bool)
}

/**
 `MapViewController` is the root view controller for the car screen. It hosts an instance of `MapScrollView`.
 */
class MapViewController: UIViewController {
  var cpWindow: CPWindow?
    var mapView: MapScrollView!
    var mapViewActionProvider: MapViewActionProviding?
  var contentLabel: UILabel!
  
    override func viewDidLoad() {
        super.viewDidLoad()
      self.view.backgroundColor = UIColor.blue
//        guard let mapImage = UIImage(named: "Map", in: .main, compatibleWith: traitCollection) else { fatalError("No map image found") }

        /// - Tag: did_layout
        // Add the map as the base view for the CarPlay screen.
        // Only add 1 view and it should cover the entire screen.
//        mapView = MapScrollView(frame: view.bounds, image: mapImage)
//        mapView.translatesAutoresizingMaskIntoConstraints = false
//        view.addSubview(mapView)
//
//        mapView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
//        mapView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
//        mapView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
//        mapView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
//
//        setPolylineVisible(false)
//        mapView.zoomToLocation(.routeOverview)
      
      contentLabel = UILabel(frame: view.bounds)
      contentLabel.translatesAutoresizingMaskIntoConstraints = false
      view.addSubview(contentLabel)
      
      contentLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
      contentLabel.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
      contentLabel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
      contentLabel.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
      
      contentLabel.backgroundColor = UIColor.gray
      contentLabel.numberOfLines = 0
      contentLabel.textAlignment = .center
      
      guard let window = cpWindow else { return }
      
      var text = ""
      if let mode = window.screen.currentMode {
        text = "Screen Resolution is:\n\(mode.size)\nContent Size is:\n\(UIScreen.main.bounds.size)\n\n"
      }
      
      text.append("Available Resolution is:\n")
      for mode in window.screen.availableModes {
        text += "\(mode.size)\n"
      }
      
      contentLabel.text = text
    }

    /// Coastal Roads navigates with a single pre-determined polyline that indicates the route.
    /// When navigation guidance becomes active, the scroll view will swap its background image
    /// in favor of one with a visible polyline.
    func setPolylineVisible(_ visible: Bool) {
        let imageName = visible ? "MapLine" : "Map"
        guard let image = UIImage(named: imageName, in: .main, compatibleWith: traitCollection) else { return }
        mapView.imageView.image = image
    }

    // MARK: Panning

    func panInDirection(_ direction: CPMapTemplate.PanDirection) {
        MemoryLogger.shared.appendEvent("Panning to \(direction).")

        var offset = mapView.contentOffset
        // Customize the panning amount to better fit with the sample map
        switch direction {
        case .down:
            offset.y += mapView.bounds.size.height / 2
        case .up:
            offset.y -= mapView.bounds.size.height / 2
        case .left:
            offset.x -= mapView.bounds.size.width / 2
        case .right:
            offset.x += mapView.bounds.size.width / 2
        default:
            break
        }

        mapView.setContentOffset(offset, animated: true)
    }

    // MARK: Actions

    func zoomIn() {
        mapView.zoomIn()
        updateMapZoom()
    }

    func zoomOut() {
        mapView.zoomOut()
        updateMapZoom()
    }
    
    private func updateMapZoom() {
        mapViewActionProvider?.setZoomInEnabled(mapView.canZoomIn())
        mapViewActionProvider?.setZoomOutEnabled(mapView.canZoomOut())
    }
    
}
