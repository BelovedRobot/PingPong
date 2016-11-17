# PingPong by Beloved Robot

## Overview
PingPong provides a framework to sync json documents to and from a type-less document endpoint. The syncing can occur in the foreground or background, and it supports offline syncing.

In our projects we pair this framework with a REST-ful nodejs endpoint to POST/PUT documents, which are then stored in a document database. The framework also supports file uploads through another endpoint.

## Features
- Foreground and Background Document Syncing
- Offline Document Syncing
- JSON Serialization and De-serialization for Swift Classes
- Local Document Stash 
- File Uploads
- Custom Sync Tasks

## What's Missing or Broken
- Document Conflict Handling is not covered, the framework assumes conflict decisions will be handled elsewhere
- JSON deserialization can not handle Array and Dictionary types
- JSON deserialization can not handle null types, such as Int?

![Beloved Robot PingPong Infographic](https://belovedrobotstorage.blob.core.windows.net/general/PingPongOverview.png "Beloved Robot PingPong Infographic")

## Quick Example
```swift
class Note : SyncObject {
    var docType : String = "note" // This field is for querying on type and is required to differentiate objects
    var text : String = ""
}
```

```swift
    var note : Note = Note()
    note.text = "Here is my note text"

    // To stash the object locally
    note.stash()

    // To save the object to the endpoint
    note.saveEventually()

    // To convert to JSON
    let jsonString = note.toJSON()

    // To fetch from the stash
    note.id = 'aa-bb-cc-dd-ee' // You must have an id to fetch a document
    note.refresh()

    // To fetch from the cloud
    note.fromCloud()
```

## Core Objects and Concepts
Below is a list of PingPong objects and why they are important. It is critical that you understand these objects and why.

### JsonObject
The JsonObject class contains all of the JSON serialization and deserialization logic. Subclassing JsonObject will enable an object to be json serialized and deserialized as well as converted to a Dictionary.

### StashObject
The StashObject class contains all of the logic to save and retrieve an object from the local database. Subclassing StashObject will enable an object to be saved, updated, and retrieved from the local database. StashObject subclasses JsonObject, therefore you inherit those behaviors as well.

### SyncObject
The SyncObject class contains all of the logic to POST/PUT/DELETE an object from the document endpoint. The SyncObject also contains that critical logic that updates objects in memory when updated from a sync operation.

### FileUpload/FileDelete
The FileUpload and FileDelete objects are designed to upload attachments to documents. For example consider the JSON representing a Note object: 
```json
{
    "noteId" : "aa-bb-cc-dd",
    "text" : "This is the note text",
    "noteImageUrl" : ""
}
```

The field noteImageUrl is clearly meant to attach a photo to this note. The problem is how do you sync the json object with a missing image url for the image if the image has not been uploaded, or vice-versa do you risk uploading a file without the back object to describe and define it? This is where FileUpload and FileDelete come in. When a Note object is created and an image as assigned to it then a FileUpload object should be created. The FileUpload object defines the file to be uploaded and the meta-data necessary to tie that file to the target Note on the server. Therefore when the background sync operation occurs the Note is synced to the server, the image is uploaded, and after the upload is successful the Note is updated with the proper url. The same is true for FileDelete except that it works in the opposite direction. You issue a file delete for a given url and simultaneously delete the url from the Note object and the background sync will save the Note with a blank image url, and then the file delete will physically remove the file.

### The Physical Database and the DateStore class
The physical database backing PingPong is SQLite. We use FMDB to access SQLite and we use BRDatabase to provision and upgrade the physical database. Most of the logic saving and retrieving documents to and from the database is found in DataStore, however it is uncommon to access DataStore or SQLite directly. All of the operations to save documents to and from the local stash can be found in the Stash class.

### The Background Sync Process
The background sync process is designed to push data and pull data to and from the app and the service in a background thread. This liberates the main thread from long running web requests and also handles the complicated logic for the developer. The background sync process can be fired in three ways: 
1) When PingPong is started, usually in the AppDelegate, there are timers that are configured to fire and run the background sync
2) When the App is in the background the background sync process is executed during a background fetch event from the OS
3) The developer can manually trigger a background sync by calling PingPong.startBackgroundSync()

### Custom Sync Tasks
There are scenarios when you don't want PingPong to handle specific document types, or as a whole the document endpoint is not an option. In those cases we provide an override mechanism. When starting PingPong you provide it with an array of SyncTask objects. These specific objects are "tasks" that you create by subclassing the SyncTask type. You configure these sync tasks as one of two different types, either **automatic sync tasks** or **document sync tasks**. If you set automaticSyncTask to true then everytime PingPong syncs in the background it will automatically execute the logic defined in the sync function. Otherwise if the task is not an automatic task but instead is defined by a specific docType, then it will execute the sync logic when the background sync process has a document of that type to process in the sync queue.

### Querying the Stash
There is a handy func in the DataStore that enables the user to query the local stash. Simply pass in a set of fields and values to search on those values.
```swift
// Func signature
func queryDocumentStore(parameters : (property: String, value: String)..., callback : @escaping ([JSON]) -> ())
```

```swift
// Example Usage
DataStore.sharedDataStore.queryDocumentStore(("docType", "note")) { documents in
    for json in documents {
        let note = Note()
        note.fromJSON(json.rawString()!)
    }
}
```

## Implementation
The first step is to create the Document endpoint. This endpoint can be configured anyway you like as long as PingPong can POST/PUT json documents. A sample endpoint that Beloved Robot uses is found here: https://github.com/BelovedRobot/PingPongEndpoint

### Implementation Notes for the Service Endpoint
1. Each document needs an ID

2. Each document needs a "docType" property, which can then be used to model types of objects

3. When documents are POST/PUT the document is returned wrapped in a data property.

4. When files are uploaded PingPong assumes they are tied to another document so you have to provide a FileUpload object for each file that should be used by your endpoint to assign the file's URL to the object once uploading is complete

5. Authorization to the endpoint is _only_ provided through simple token-based authentication where a token is assigned to each app and or user that gives access the endpoint through the "Authorization" header on requests. That is to say each PingPong request includes "Token token=xxx" in the Authorization header where "xxx" is the actual token

### Implementation of Alternate Endpoints
If you are implementing a non-document endpoint or you do not have control of the endpoint then you can override all functionality of PingPong by using the syncOptions. You will need to register a syncOption for each documentType and implement it in that manner. If you have a file upload process you can either a) modify the fileUpload logic directly or b) change the docType of FileUpload and create a customer sync option.

### Implementation Notes for iOS Apps
After creating the endpoint, add PingPong to your iOS project by following these steps:

1. Clone a copy of PingPong or make sure to pull latest

2. Copy _all_ the source files from the repo into your iOS project *DO NOT* Copy the .git repo or any .git files
As weird as this sounds but PingPong is not an actual iOS Framework. At the time of writing this mixed Objective-C/Swift frameworks are not allowed. Furthermore FMDB is not compatible with Frameworks either (again, as of this writing). The simplest solution then was to simply create a folder with the source and copy it into each project that needs it.

3. Add "libsqlite3.tbd" to Linked Frameworks and Libraries on your iOS Target

4. Add "#import "FMDB.h" to your bridging header

5. Add "#import "BRDatabase.h" to your bridging header

6. In your AppDelegate (or wherever you'd like) add PingPong.shared.start(...your parameters...)

7. PingPong supports the ability to "override" default syncing behavior through the SyncingOptions parameter. Essentially you give PingPong the docType and a closure (block of code) to execute when syncing occurs. You can use this feature to create custom background tasks.

8.  Be weary of **optional** properties, they do not serialize properly (this needs to be verified).

9. This is *very important*: The JSON de-serialization to Swift objects cannot parse arrays or dictionaries (or Swift classes that are seen as Dictionaries) on it's own. So if your object has an array or dictionary you will have to override the func fromJson. Be sure to call super.fromJSON() to populate your simple properties and that will also populate the property deserializationExceptions (Dictionary<string, JSON>) where you can get the JSON value for the property.
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
