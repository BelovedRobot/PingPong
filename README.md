# PingPong by Beloved Robot

## Overview
This group of source files provides a framework to sync json documents to and from a type-less document endpoint. The syncing can occur in the foreground or background, and it supports offline syncing.

In our projects we pair this framework with a REST-ful nodejs endpoint to POST/PUT documents, which are then stored in a document database. The framework also supports file uploads through another endpoint.

## Features
- Foreground and Background Document Syncing
- Offline Document Syncing
- JSON Serialization and De-serialization for Swift Classes
- Local Document Stash 
- File Uploads assume they are tied to another document so you have to provide a FileUpload object for each file that should be used by your endpoint to assign the file's URL to the object once uploading is complete

## What's Missing
- Document Conflict Handling (the framework assumes conflict decisions will be handled elsewhere)

## Implementation
The first step is to create the Document endpoint. This endpoint can be configured anyway you like as long as PingPong can POST/PUT json documents. 

The framework depends on a few things:
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
4) When files are uploaded 

After creating an endpoint 