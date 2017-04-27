//
//  ApplicationData.swift
//  Pargi
//
//  Main handler of the database, allows getting a stored database, as well
//  as fetching the latest copy from GitHub
//
//  Created by Henri Normak on 27/04/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import Foundation
import Cereal

struct ApplicationData {
    private static let DatabaseFilename = "PargiData"
    private static let DatabasePrimeResource = "Data"
    private static let DatabasePrimeResourceExtension = "json"
    
    private static let DatabaseUpdateURL = URL(string: "https://raw.githubusercontent.com/Pargi/Data/master/Data.json")!
    
    enum Error: Swift.Error {
        case DatabaseError(String)
    }
    
    static let currentDatabase: Database = {
        do {
            let fileURL = databaseFileURL()
            
            if !FileManager.default.fileExists(atPath: fileURL.path) {
                // Prime the DB
                try primeDatabase()
            }
            
            // Now there is definitely something at the correct path, read it in and return in
            let data = try Data(contentsOf: fileURL)
            return try CerealDecoder.rootCerealItem(with: data)
        } catch let error {
            print("Error creating local database, defaulting to empty DB - \(error)")
            return Database(version: "0.0.0", date: Date.distantPast, hash: "", providers: [], groups: [])
        }
    }()
    
    static func updateDatabase() {
        // Update database by downloading the latest, and writing it to disk
        _ = Downloader(URL: DatabaseUpdateURL) { (error, fileURL) in
            guard let fileURL = fileURL else {
                print("Failed to get the latest DB from cloud - \(String(describing: error))")
                return
            }
            
            do {
                let updatedDatabase = try createDatabase(withContentsAtURL: fileURL)
                let currentDatabase = self.currentDatabase
                
                if updatedDatabase.version > currentDatabase.version {
                    try overwriteDatabase(withContentsAtURL: fileURL)
                    print("DB updated")
                } else {
                    print("Skipping update, fetched database either older or as new as local DB")
                }
            } catch let error {
                print("Failed to update DB - \(error)")
            }
        }
    }
    
    // MARK: Helpers
    
    private static func databaseFileURL() -> URL {
        let documents = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return documents.appendingPathComponent(ApplicationData.DatabaseFilename)
    }
    
    private static func primeDatabase() throws {
        // Load the initial data (JSON)
        guard let fileURL = Bundle.main.url(forResource: DatabasePrimeResource, withExtension: DatabasePrimeResourceExtension) else {
            return
        }
        
        try overwriteDatabase(withContentsAtURL: fileURL)
    }
    
    private static func createDatabase(withContentsAtURL fileURL: URL) throws -> Database {
        let data = try Data(contentsOf: fileURL)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw Error.DatabaseError("Failed to cast original JSON as a dictionary")
        }
        
        guard let database = Database(dictionary: json) else {
            throw Error.DatabaseError("Failed to initialise Database from JSON")
        }
        
        return database
    }
    
    private static func overwriteDatabase(withContentsAtURL fileURL: URL) throws {
        let database = try createDatabase(withContentsAtURL: fileURL)
        let saveData = try CerealEncoder.data(withRoot: database)
        try saveData.write(to: databaseFileURL(), options: .atomicWrite)
    }
}
