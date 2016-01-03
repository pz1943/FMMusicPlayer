//
//  song.swift
//  DBFM
//
//  Created by apple on 15/12/15.
//  Copyright © 2015年 pz1943. All rights reserved.
//

import UIKit

class Song: CustomStringConvertible{
    var title: String
    var imageURL: String
    var musicURL: String
    var singer: String
    var favoriteFlag: Bool = false
    var imageCache: NSData?
    var musicPath: String? {
        get {
            if self.savedName != nil {
                let path = NSSearchPathForDirectoriesInDomains(
                    .DocumentDirectory, .UserDomainMask, true
                    ).first!
                return path + "/" + self.savedName!

            } else {
                return nil
            }
        }
    }
    var savedName: String?
    var IsPlaying: Bool?
    var description: String {
        get {
            return "\n\ntitle:\(title)\nimageURL: \(imageURL)\nmusicURL:\(musicURL)\nsinger:\(singer)\nfavoriteFlag:\(favoriteFlag)\nsavedName: \(savedName)\nIsPlaying:\(IsPlaying)"
        }
    }
    
    init(title: String, imageURL: String, musicURL: String, singer: String) {
        self.title = title
        self.imageURL = imageURL
        self.musicURL = musicURL
        self.singer = singer
    }
    init(title: String, imageURL: String, musicURL: String, singer: String, favoriteFlag: Bool, imageCache: NSData?, savedName: String?, IsPlaying: Bool?) {
        self.title = title
        self.imageURL = imageURL
        self.musicURL = musicURL
        self.singer = singer
        self.favoriteFlag = favoriteFlag
        self.imageCache = imageCache
        self.savedName = savedName
        self.IsPlaying = IsPlaying
    }

}

struct songDBColumn {
    static let title = "title"
    static let imageURL = "imageURL"
    static let musicURL = "musicURL"
    static let singer = "singer"
    static let favoriteFlag = "favoriteFlag"
    static let imageCache = "imageCache"
    static let savedName = "savedName"
    static let IsPlaying = "IsPlaying"
}

enum PlayerMode :Int{
    case FMMode = 0
    case singleMode
    case LocalMode
}
