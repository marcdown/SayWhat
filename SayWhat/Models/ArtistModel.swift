//
//  ArtistModel.swift
//  SayWhat
//
//  Created by Marc Brown on 8/28/16.
//  Copyright © 2016 creative mess. All rights reserved.
//

import Foundation
//model
class ArtistModel: NSObject {
    var identifier: String?
    var imageURL: String?
    var name: String?
    
    init(artist: [String: AnyObject]) {
        if let identifier = artist["id"] as? String {
            self.identifier = identifier
        }
        
        if let image = artist["images"]?.firstObject as? [String: AnyObject],
            let url = image["url"] as? String {
            self.imageURL = url
        }
        
        if let name = artist["name"] as? String {
            self.name = name
        }
        
        super.init()
    }
}
