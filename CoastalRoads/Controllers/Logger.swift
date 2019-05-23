/*
See LICENSE folder for this sample’s licensing information.

Abstract:
`Logger` handles logging of events during a CarPlay session.
*/

import Foundation

/**
 `Logger` describes an object that can receive interesting events from elsewhere in the application
 and persist them to memory, disk, a network connection or elsewhere.
 */
protocol Logger {
    
    typealias Event = (Date, String)
    
    /// Append a new event to the log. All events are added at the 0 index.
    func appendEvent(_: String)
    
    /// Fetch the list of events received by this logger.
    var events: [Event] { get }
}

/**
`LoggerDelegate` is informed of logging events.
 */
protocol LoggerDelegate: AnyObject {
    
    /// The logger has received a new event.
    func loggerDidAppendEvent()
}

/**
 `MemoryLogger` is a type of `Logger` that records events only in-memory for the current
 lifecycle of the app.
 */
class MemoryLogger: Logger {
    
    static let shared = MemoryLogger()
    
    weak var delegate: LoggerDelegate?
    
    public private(set) var events: [Event]
    
    private let loggingQueue: OperationQueue
    
    private init() {
        events = []
        loggingQueue = OperationQueue()
        loggingQueue.maxConcurrentOperationCount = 1
        loggingQueue.name = "Memory Logger Queue"
        loggingQueue.qualityOfService = .userInitiated
    }
    
    func appendEvent(_ event: String) {
        loggingQueue.addOperation {
            let eventData = (Date(), event)
            self.events.insert(eventData, at: 0)
            
            guard let delegate = self.delegate else { return }
            
            DispatchQueue.main.async {
                delegate.loggerDidAppendEvent()
            }
        }
    }
}
