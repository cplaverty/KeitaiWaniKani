import Foundation
@testable import OperationKit

class StubGroupOperation: GroupOperation {
    private(set) var stateTransitions: [Operation.State] = []
    
    convenience init(operations: NSOperation...) {
        self.init(operations: operations)
    }
    
    init(immediatelyFinish: Bool = true, operations: [NSOperation]) {
        super.init(operations: operations)
        stateTransitions.append(state)
    }
    
    override var state: State {
        willSet {
            stateTransitions.append(newValue)
        }
    }
}