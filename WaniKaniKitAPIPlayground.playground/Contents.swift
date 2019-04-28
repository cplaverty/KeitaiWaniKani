import PlaygroundSupport
import WaniKaniKit

// Set your API v2 key here
let apiKey = "00000000-0000-0000-0000-000000000000"

let api = WaniKaniAPI(apiKey: apiKey, decoder: LoggingResourceDecoder(shouldPrintReceivedDataToConsole: false))

//
// Example requests
// Set apiKey above before uncommenting
//

//api.fetchResource(ofType: .user) { result in
//    print(result)
//}

//api.fetchResourceCollection(ofType: .subjects(filter: nil)) { result in
//    print(result)
//
//    return true
//}

//PlaygroundPage.current.needsIndefiniteExecution = true

