import PlaygroundSupport
import FMDB
import WaniKaniKit

/*:
 # Getting Started
 This Playground will need to write to your file system. Create the directory `~/Documents/Shared Playground Data` before running this.
 */

//: Set your API v2 key here before running
let apiKey = "00000000-0000-0000-0000-000000000000"

let api = WaniKaniAPI(apiKey: apiKey, decoder: WaniKaniResourceDecoder())

let databaseBaseURL = playgroundSharedDataDirectory.appendingPathComponent(apiKey, isDirectory: true)
let fileManager = FileManager.default
try fileManager.createDirectory(at: databaseBaseURL, withIntermediateDirectories: true, attributes: nil)

let databaseURL = databaseBaseURL.appendingPathComponent("Data.db")
let databaseManager = DatabaseManager(factory: DefaultDatabaseConnectionFactory(url: databaseURL))

if !databaseManager.open() {
    print("Failed to open database!")
    PlaygroundPage.current.finishExecution()
}

// Use a larger cache
let urlCache = URLCache(memoryCapacity: 4 * 1024 * 1024, diskCapacity: 25 * 1024 * 1024, diskPath: nil)
URLCache.shared = urlCache

let resourceRepository = ResourceRepository(databaseManager: databaseManager, apiKey: apiKey)

let group = DispatchGroup()

group.enter()
print("Fetching subjects...")
resourceRepository.updateSubjects(minimumFetchInterval: .oneHour) { result in
    print("Subject fetch result: \(result)")
    if case .error(_) = result {
        print("Failed to fetch latest subjects!")
        PlaygroundPage.current.finishExecution()
    }
    group.leave()
}

group.wait()

print("Downloading radical images...")
let imageURL = databaseBaseURL.appendingPathComponent("Radicals", isDirectory: true)
try fileManager.createDirectory(at: imageURL, withIntermediateDirectories: true, attributes: nil)
let contents = """
    {
      "info" : {
        "version" : 1,
        "author" : "xcode"
      },
      "properties" : {
        "provides-namespace" : true
      }
    }
    """.data(using: .utf8)
fileManager.createFile(atPath: imageURL.appendingPathComponent("Contents.json").path, contents: contents, attributes: nil)

for level in 1...60 {
    let resources = try resourceRepository.loadSubjects(type: .radical, level: level)
    print("Level \(level): \(resources.count) radicals")
    for resource in resources {
        let id = resource.id
        let radical = resource.data as! Radical
        let renderableImages = radical.characterImages.filter({ $0.contentType == "image/png" })
        if renderableImages.isEmpty {
            print("Skipping radical \(id): no renderable images")
            continue
        }
        
        let destinationBaseURL = imageURL.appendingPathComponent("\(id).imageset", isDirectory: true)
        try fileManager.createDirectory(at: destinationBaseURL, withIntermediateDirectories: true, attributes: nil)
        
        let downloadGroup = DispatchGroup()
        // Largest displayed subject view has 50px height, but we intentionally grab the next-largest size to oversample
        for (styleName, fileName) in [("128px", "\(id).png"), ("256px", "\(id)@2x.png"), ("512px", "\(id)@3x.png")] {
            guard let imageURL = renderableImages.first(where: { $0.metadata.styleName == styleName })?.url else {
                print("Unable to find an image for radical \(id) with style name \(styleName)")
                continue
            }
            
            let destination = destinationBaseURL.appendingPathComponent(fileName)
            downloadGroup.enter()
            let task = URLSession.shared.downloadTask(with: imageURL) { (location, response, error) in
                defer { downloadGroup.leave() }
                guard let location = location else {
                    print("Failed to download \(imageURL): \(error.debugDescription)")
                    return
                }
                
                try? fileManager.removeItem(at: destination)
                
                do {
                    try fileManager.moveItem(at: location, to: destination)
                } catch {
                    print("Failed to move item to \(destination) from \(location): \(error)")
                }
            }
            task.resume()
        }
        downloadGroup.wait()
        
        let imagesetContents = """
            {
              "images" : [
                {
                  "idiom" : "universal",
                  "filename" : "\(id).png",
                  "scale" : "1x"
                },
                {
                  "idiom" : "universal",
                  "filename" : "\(id)@2x.png",
                  "scale" : "2x"
                },
                {
                  "idiom" : "universal",
                  "filename" : "\(id)@3x.png",
                  "scale" : "3x"
                }
              ],
              "info" : {
                "version" : 1,
                "author" : "xcode"
              }
            }
            """.data(using: .utf8)
        fileManager.createFile(atPath: destinationBaseURL.appendingPathComponent("Contents.json").path, contents: imagesetContents, attributes: nil)
    }
}
print("Done")
