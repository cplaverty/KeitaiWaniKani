import WaniKaniKit

public class LoggingResourceDecoder: ResourceDecoder {
    let wrapped = WaniKaniResourceDecoder()
    let shouldPrintReceivedDataToConsole: Bool
    
    public init(shouldPrintReceivedDataToConsole: Bool = false) {
        self.shouldPrintReceivedDataToConsole = shouldPrintReceivedDataToConsole
    }
    
    public func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        if shouldPrintReceivedDataToConsole {
            print(String(data: data, encoding: .utf8)!)
        }
        return try wrapped.decode(type, from: data)
    }
}
