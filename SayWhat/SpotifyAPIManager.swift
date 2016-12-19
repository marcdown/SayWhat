//
//  SpotifyAPIManager.swift
//  SayWhat
//
//  Created by Bereket Ghebremedhin on 12/17/16.
//  Copyright © 2016 creative mess. All rights reserved.
//

import Foundation


//model was created out of the original search function.
class SpotifyAPIManager{
    
    func searchForArtists(url: URL, completion: @escaping (_ artists: [ArtistModel])->Void) {
        let session = URLSession.shared
        let task = session.dataTask(with: url) { (data, response, error) in
            guard data != nil else {
                print("\(error?.localizedDescription)")
                return
            }
            self.artistsFromJSON(data: data!) { artistsArray in
                completion(artistsArray)
                
            }
        }
        task.resume()
    }
    
    //receives JSON from the search for artist function and serializes it 
    private func artistsFromJSON(data:Data, completion: (_ artists: [ArtistModel])->Void ){
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
    
}
