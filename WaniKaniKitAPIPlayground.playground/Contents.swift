import PlaygroundSupport
import WaniKaniKit

// Set your API v2 key here
let apiKey = "00000000-0000-0000-0000-000000000000"

let api = WaniKaniAPI(apiKey: apiKey, decoder: LoggingResourceDecoder(shouldPrintReceivedDataToConsole: false))

//
// Example requests
// Set apiKey above before uncommenting
//

//api.fetchResource(ofType: .user) { (resource, error) in
//    if let error = error {
//        print(error)
//    } else {
//        print(resource!)
//    }
//}

//api.fetchResourceCollection(ofType: .subjects(filter: nil)) { (resources, error) in
//    if let error = error {
//        print(error)
//    } else {
//        print(resources!)
//    }
//
//    return true
//}

//PlaygroundPage.current.needsIndefiniteExecution = true

