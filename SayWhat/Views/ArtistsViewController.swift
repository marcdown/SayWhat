//
//  ArtistsViewController.swift
//  SayWhat
//
//  Created by Marc Brown on 8/28/16.
//  Copyright © 2016 creative mess. All rights reserved.
//

import UIKit

class ArtistsViewController: UIViewController, UITableViewDataSource, UISearchBarDelegate {
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var searchBar: UISearchBar!
    
    private var searchResults: [ArtistModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func search(artist: String?) {
        guard let artist = artist else {
            return
        }
        
        let url: URL = URL(string: "https://api.spotify.com/v1/search?q=\(artist)&type=artist")!
        let session = URLSession.shared
        
        let task = session.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
                
                if let artists = json?["artists"]?["items"] as? [AnyObject] {
                    for artist in artists {
                        let artistModel = ArtistModel(artist: artist as! [String : AnyObject])
                        self.searchResults.append(artistModel)
                    }
                    
                    OperationQueue.main.addOperation {
                        self.tableView.reloadData()
                    }
                }
            } catch {
                return
            }
        }
        
        task.resume()
    }
    
    func reset() {
        searchResults = []
        tableView.reloadData()
    }
    
    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return searchResults.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ArtistCell", for: indexPath)
        let artistModel: ArtistModel = searchResults[indexPath.row]
        
        cell.textLabel?.text = artistModel.name
        
        return cell
    }
    
    // MARK: UISearchBarDelegate
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = true
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.showsCancelButton = false
        searchBar.resignFirstResponder()
        reset()
        search(artist: searchBar.text)
    }
}

