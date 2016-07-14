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
1) Each document needs an ID
2) Each document needs a "docType" property, which can then be used to model types of objects
3) When documents are POST/PUT the document is returned wrapped in a data property. Example: 
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
4) When files are uploaded PingPong assumes they are tied to another document so you have to provide a FileUpload object for each file that should be used by your endpoint to assign the file's URL to the object once uploading is complete
5) Authorization to the endpoint is _only_ provided through simple token-based authentication where a token is assigned to each app and or user that gives access the endpoint through the "Authorization" header on requests. That is to say each PingPong request includes "Token token=xxx" in the Authorization header where "xxx" is the actual token

After creating the endpoint, add PingPong to your iOS project by following these steps:
1) Clone a copy of PingPong or make sure to pull latest
2) Copy _all_ the source files from the repo into your iOS project

As weird as this sounds but PingPong is not an actual iOS Framework. At the time of writing this mixed Objective-C/Swift frameworks are not allowed. Furthermore FMDB is not compatible with Frameworks either (again, as of this writing). The simplest solution then was to simply create a folder with the source and copy it into each project that needs it.

3) Add "libsqlite3.tbd" to Linked Frameworks and Libraries on your iOS Target
4) Add "#import "FMDB.h" to your bridging header
5) Add "#import "BRDatabase.h" to your bridging header