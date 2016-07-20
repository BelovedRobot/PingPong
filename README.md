# PingPong by Beloved Robot

## Overview
This group of source files provides a framework to sync json documents to and from a type-less document endpoint. The syncing can occur in the foreground or background, and it supports offline syncing.

In our projects we pair this framework with a REST-ful nodejs endpoint to POST/PUT documents, which are then stored in a document database. The framework also supports file uploads through another endpoint.

## Features
- Foreground and Background Document Syncing
- Offline Document Syncing
- JSON Serialization and De-serialization for Swift Classes
- Local Document Stash 
- File Uploads

## What's Missing
- Document Conflict Handling (the framework assumes conflict decisions will be handled elsewhere)

## Implementation
The first step is to create the Document endpoint. This endpoint can be configured anyway you like as long as PingPong can POST/PUT json documents. 

### Implementation Notes for the Service Endpoint
1. Each document needs an ID
2. Each document needs a "docType" property, which can then be used to model types of objects
3. When documents are POST/PUT the document is returned wrapped in a data property. Example: 
I POST:
`{
	"id": "...",
	"docType": "myDocType",
	"someProperty": "Hello World!"
}`

I expect:
`{
	"data": {
		"id": "...",
		"docType": "myDocType",
		"someProperty": "Hello World!"
	}
}`
4. When files are uploaded PingPong assumes they are tied to another document so you have to provide a FileUpload object for each file that should be used by your endpoint to assign the file's URL to the object once uploading is complete
5. Authorization to the endpoint is _only_ provided through simple token-based authentication where a token is assigned to each app and or user that gives access the endpoint through the "Authorization" header on requests. That is to say each PingPong request includes "Token token=xxx" in the Authorization header where "xxx" is the actual token

### Implementation Notes for iOS Apps
After creating the endpoint, add PingPong to your iOS project by following these steps:

1. Clone a copy of PingPong or make sure to pull latest

2. Copy _all_ the source files from the repo into your iOS project *DO NOT* Copy the .git repo or any .git files
As weird as this sounds but PingPong is not an actual iOS Framework. At the time of writing this mixed Objective-C/Swift frameworks are not allowed. Furthermore FMDB is not compatible with Frameworks either (again, as of this writing). The simplest solution then was to simply create a folder with the source and copy it into each project that needs it.

3. Add "libsqlite3.tbd" to Linked Frameworks and Libraries on your iOS Target

4. Add "#import "FMDB.h" to your bridging header

5. Add "#import "BRDatabase.h" to your bridging header

6. In your AppDelegate (or wherever you'd like) add PingPong.shared.start(...your parameters...)

7. This is *very important*: The JSON de-serialization to Swift objects cannot parse arrays or dictionaries (or Swift classes that are seen as Dictionaries) on it's own. So if your object has an array or dictionary you will have to override the func fromJson. Be sure to call super.fromJSON() to populate your simple properties and that will also populate the property deserializationExceptions (Dictionary<string, JSON>) where you can get the JSON value for the property.
Example:

```swift
class PayrollWeek : SyncObject {
    var docType = "payrollWeek"
    var technicianId : String = ""
    var name : String = ""
    var serviceLocation : String = ""
    var startOfWeek : String = ""
    var days : [PayrollDay] = []
    var metadata : PayrollMetadata = PayrollMetadata()
    
    override func fromJSON(json: String) {
        self.days = []
        
        super.fromJSON(json)
        
        // Days
        if let dayArray = self.deserializationExceptions["days"]?.array {
            for dayJson in dayArray {
                let day = PayrollDay()
                day.fromJSON(dayJson.rawString()!)
                self.days.append(day)
            }
        }
        
        // PayrollMetadata
        if let json = self.deserializationExceptions["metadata"]?.rawString() {
            let metadata = PayrollMetadata()
            metadata.fromJSON(json)
            self.metadata = metadata
        }
    }
}
```

### Modifying PingPong
The easiest and recommended way of making modifications to PingPong is to edit the source files directly in a working iOS project. Before making modifications make sure that you have the latest version of PingPong installed. Then simply start editing. This ensures that any changes are built and tested prior to committing to the PingPong repo. Once you have validated your changes you can can copy/paste the source into the PingPong repo and commit them.
