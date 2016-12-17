//
//  ArtistsViewController.swift
//  SayWhat
//
//  Created by Marc Brown on 8/28/16.
//  Copyright © 2016 creative mess. All rights reserved.
//

import Speech
import UIKit

class ArtistsViewController: UIViewController, UISearchBarDelegate, UITableViewDataSource, SpeechRecognitionDelegate {
    
    enum ErrorMessage: String {
        case Denied = "To enable Speech Recognition go to Settings -> Privacy."
        case NotDetermined = "Authorization not determined - please try again."
        case Restricted = "Speech Recognition is restricted on this device."
        case NoResults = "No results found - please try a different search."
    }
    
    @IBOutlet var tableView: UITableView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var microphoneButton: UIBarButtonItem!
    
    private var searchResults: [ArtistModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.tableFooterView = UIView(frame: CGRect.zero)
    }
    
    func requestSpeechAuthorization() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            switch authStatus {
            case .authorized:
                self.startListening()
                
            case .denied:
                self.displayErrorAlert(message: .Denied)
                
            case .notDetermined:
                self.displayErrorAlert(message: .NotDetermined)
                
            case .restricted:
                self.displayErrorAlert(message: .Restricted)
            }
        }
    }
    
    func startListening() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "SpeechRecognitionViewController") as! SpeechRecognitionViewController
        vc.delegate = self
        OperationQueue.main.addOperation {
            self.present(vc, animated: true, completion: nil)
        }
    }
    
    func displayErrorAlert(message: ErrorMessage) {
        let alertController = UIAlertController(title: nil,
                                                message: message.rawValue,
                                                preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        alertController.addAction(alertAction)
        OperationQueue.main.addOperation {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
//    func search(artist: String?) {
//       
//        guard let artist = artist else {
//            return
//        }
//        
//        //makeAPICall(artist: String)
//        reset()
//       //1
//        let urlEncodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
//        let url: URL = URL(string: "https://api.spotify.com/v1/search?q=\(urlEncodedArtist)&type=artist")!
//        let session = URLSession.shared
//        
//        
//        //2
//        let task = session.dataTask(with: url) { (data, response, error) in
//            guard let data = data else {
//                return
//            }
//        
//        
//        //3
//            do {
//                let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
//                
//                if let artists = json?["artists"]?["items"] as? [AnyObject] {
//                    if artists.isEmpty {
//                        self.displayErrorAlert(message: .NoResults)
//                    } else {
//                        for artist in artists {
//                            let artistModel = ArtistModel(artist: artist as! [String : AnyObject])
//                            self.searchResults.append(artistModel)
//                        }
//                        
//                        
//                        OperationQueue.main.addOperation {
//                            self.tableView.reloadData()
//                        }
//                    }
//                    
//                }
//            } catch {
//                return
//            }
//        }
//        
//        task.resume()
//    }
    
    func searchForArtist(artist: String?){
        guard let artist = artist else {
            return
        }
        let urlEncodedArtist = artist.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
        let url: URL = URL(string: "https://api.spotify.com/v1/search?q=\(urlEncodedArtist)&type=artist")!
        makeAPICall(url: url){ artistsArray in
            OperationQueue.main.addOperation {
                self.tableView.reloadData()
            }
            if artistsArray.isEmpty{
                self.displayErrorAlert(message: .NoResults)
            }
            self.searchResults = artistsArray
        }
    }
    
    func makeAPICall(url: URL, completion: @escaping (_ artists: [ArtistModel])->Void) {
        let session = URLSession.shared
        let task = session.dataTask(with: url) { (data, response, error) in
            guard data != nil else {
                print("\(error?.localizedDescription)")
                return
            }
            self.serializeAndParseJSON(data: data!) { artistsArray in
                completion(artistsArray)
                
                            }
        }
        task.resume()
    }
    
    
    func serializeAndParseJSON(data:Data, completion: (_ artists: [ArtistModel])->Void ){
        var artistsArray: [ArtistModel] = []
        do {
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: AnyObject]
            if let artists = json?["artists"]?["items"] as? [AnyObject] {
                if artists.isEmpty {
                    completion(artistsArray)
                } else {
                    for artist in artists {
                        let artistModel = ArtistModel(artist: artist as! [String : AnyObject])
                        
                        artistsArray.append(artistModel)
                    }
                    completion(artistsArray)
                }
                
            }
        } catch {
            return
        }
    }
    
    func reset() {
        searchResults = []
        tableView.reloadData()
    }
    
    @IBAction func microphoneButtonTapped() {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized:
            startListening()
            break
            
        case .denied:
            displayErrorAlert(message: .Denied)
            break
            
        case .notDetermined:
            requestSpeechAuthorization()
            break
            
        case .restricted:
            displayErrorAlert(message: .Restricted)
            break
        }
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
        searchForArtist(artist: searchBar.text)
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
    
    // MARK: SpeechRecognitionDelegate
    
    func speechRecognitionComplete(query: String?) {
        if let query = query {
            
            searchForArtist(artist: query)
            searchBar.text = ""
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func speechRecognitionCancelled() {
        dismiss(animated: true, completion: nil)
    }
}

