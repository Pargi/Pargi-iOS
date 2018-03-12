//
//  SearchViewController.swift
//  Pargi
//
//  Created by Henri Normak on 02/06/2017.
//  Copyright © 2017 Henri Normak. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource {
    
    var zones: [Zone] = [] {
        didSet {
            self.tableView?.reloadData()
        }
    }
    
    private var isSearching: Bool = false
    private var matchingZones: [Zone] = []
    
    @IBOutlet var tableView: UITableView!
    
    // MARK: UISearchBarDelegate
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.isSearching = !searchText.isEmpty
        
        self.matchingZones = self.zones.filter { (zone) in
            return zone.code.lowercased().contains(searchText.lowercased())
        }
        
        self.tableView.reloadData()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        self.isSearching = false
    }
    
    func searchBarResultsListButtonClicked(_ searchBar: UISearchBar) {
        
    }
    
    // MARK: UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.isSearching ? self.matchingZones.count : self.zones.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ZoneCell")!
        let zone = self.isSearching ? self.matchingZones[indexPath.row] : self.zones[indexPath.row]
        
        cell.textLabel?.text = zone.code
        
        return cell
    }
}
