/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`LoggerViewController` displays a read-only log, on the phone screen, of the events being recorded by Coastal Roads.
*/

import UIKit

/**
 `LoggerViewController` displays a read-only log, on the phone screen, of the events
 being recorded by Coastal Roads.
 */
class LoggerViewController: UITableViewController {
    
    private let cellIdentifier = "cell"
    private static let formatter = DateFormatter()
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        LoggerViewController.formatter.dateFormat = "hh:mm:ss.SSS"
        
        title = "Coastal Roads Events"
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: cellIdentifier)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 44
        tableView.allowsSelection = false
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        let previousInterfaceStyle = previousTraitCollection?.userInterfaceStyle == .dark
        let newInterfaceStyle = traitCollection.userInterfaceStyle == .dark
        
        guard previousInterfaceStyle != newInterfaceStyle else { return }
        
        MemoryLogger.shared.appendEvent("Phone: Dark interface style changed from \(previousInterfaceStyle) to \(newInterfaceStyle)")
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return MemoryLogger.shared.events.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: UITableViewCell.CellStyle.subtitle, reuseIdentifier: cellIdentifier)
        let event = MemoryLogger.shared.events[indexPath.row]
        cell.textLabel?.text = event.1
        cell.textLabel?.numberOfLines = 0
        cell.detailTextLabel?.text = dateToString(event.0)
        return cell
    }
    
    private func dateToString(_ date: Date) -> String {
        return LoggerViewController.formatter.string(from: date)
    }
    
}

extension LoggerViewController: LoggerDelegate {
    
    func loggerDidAppendEvent() {
        tableView.reloadData()
    }
    
}
