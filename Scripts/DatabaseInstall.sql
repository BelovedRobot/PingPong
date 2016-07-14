-- Create the Version table to store the database version
CREATE TABLE Version (versionId INTEGER PRIMARY KEY ASC, databaseVersion INT, description TEXT);

CREATE TABLE documents (id TEXT, json TEXT);

CREATE TABLE sync_queue (id TEXT);

CREATE TABLE sync_history (id TEXT, json TEXT, dateSynced TEXT);

-- Update the Version
INSERT INTO Version (databaseVersion, description) VALUES (0.0, 'The initial install of the database. Creating the new documents, sync_queue, and sync_history tables.');