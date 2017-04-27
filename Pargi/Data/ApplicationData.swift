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
    
    private enum Error: Swift.Error {
        case DatabaseError(String)
    }
    
    static let currentDatabase: Database = {
        do {
            let fileURL = databaseFileURL()
            
            if !FileManager.default.fileExists(atPath: fileURL.absoluteString) {
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
    
    private static func databaseFileURL() -> URL {
        let documents = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return documents.appendingPathComponent(ApplicationData.DatabaseFilename)
    }
    
    private static func primeDatabase() throws {
        // Load the initial data (JSON)
        guard let fileURL = Bundle.main.url(forResource: DatabasePrimeResource, withExtension: DatabasePrimeResourceExtension) else {
            return
        }
        
        let data = try Data(contentsOf: fileURL)
        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw Error.DatabaseError("Failed to cast original JSON as a dictionary")
        }
        
        guard let database = Database(dictionary: json) else {
            throw Error.DatabaseError("Failed to initialise Database from JSON")
        }
        
        let saveData = try CerealEncoder.data(withRoot: database)
        try saveData.write(to: databaseFileURL())
    }
}
