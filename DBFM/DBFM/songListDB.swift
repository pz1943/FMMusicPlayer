//
//  songListDB.swift
//  DBFM
//
//  Created by apple on 15/12/19.
//  Copyright © 2015年 pz1943. All rights reserved.
//

//MARK: TODO 不够优雅，代码冗余
import Foundation
import SQLite

class SongListDB {
    
    var DB: Connection
    var songListTable: Table
    var settingTable: Table

    var favoriteFlag: Expression<Bool>
    var imageCache: Expression<SQLite.Blob?>
    var imageURL: Expression<String>
    var IsPlaying: Expression<Bool?>
    var savedName: Expression<String?>
    var musicURL: Expression<String>
    var singer: Expression<String>
    var title: Expression<String>
    
    var selectedChannelIndex: Expression<Int>
    var mode: Expression<Int>

    struct Constants {
        static let songListTableName = "songList"
        static let settingTableName = "settings"
    }
    struct Static {
        static var instance:SongListDB? = nil
        static var token:dispatch_once_t = 0
    }
    
    class func sharedInstance() -> SongListDB! {
        dispatch_once(&Static.token) {
            Static.instance = self.init()
        }
        return Static.instance!
    }

    required init() {
        let path = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true
            ).first!
        
        DB = try! Connection("\(path)/db.sqlite3")
        self.songListTable = Table(Constants.songListTableName)
        self.settingTable = Table(Constants.settingTableName)
        
        favoriteFlag = Expression<Bool>(songDBColumn.favoriteFlag)
        imageCache = Expression<SQLite.Blob?>(songDBColumn.imageCache)
        imageURL = Expression<String>(songDBColumn.imageURL)
        IsPlaying = Expression<Bool?>(songDBColumn.IsPlaying)
        savedName = Expression<String?>(songDBColumn.savedName)
        musicURL = Expression<String>(songDBColumn.musicURL)
        singer = Expression<String>(songDBColumn.singer)
        title = Expression<String>(songDBColumn.title)
        
        selectedChannelIndex = Expression<Int>("selectedChannelIndex")
        mode = Expression<Int>("mode")
        
        try! DB.run(songListTable.create(ifNotExists: true) { t in
            print("creat songListDB at \(path)")

            t.column(musicURL, primaryKey: true)
            t.column(favoriteFlag, defaultValue: false)
            t.column(imageCache)
            t.column(imageURL)
            t.column(IsPlaying, defaultValue: false)
            t.column(savedName)
            t.column(singer)
            t.column(title)
            })
        
        try! DB.run(settingTable.create(ifNotExists: true) { t in
            t.column(selectedChannelIndex)
            t.column(mode)
        })
        
        var rowExist: Bool = false
        for _ in DB.prepare(settingTable) {
            rowExist = true
        }
        if !rowExist {
            let insert = settingTable.insert(
                self.selectedChannelIndex <- 0,
                self.mode <- PlayerMode.FMMode.rawValue)
            do {
                try DB.run(insert)
            } catch let error as NSError {
                print(error)
            }
        }
        
   }
    
    func loadSettings() -> [String :Int]?{
        for setting in DB.prepare(settingTable) {
            return ["selectedChannelIndex": setting[selectedChannelIndex] ,"mode": setting[mode]]
        }
        return nil
    }
    
    func saveMode(mode: PlayerMode) {
        let modeRaw = mode.rawValue
        try! DB.run(settingTable.update(self.mode <- modeRaw))
    }
    
    func saveSelectedChannelIndex(index: Int) {
        try! DB.run(settingTable.update(self.selectedChannelIndex <- index))
    }
    
    func loadSongList() -> Array<Song> {
        var songList: Array<Song> = []
        var imageCacheData: NSData?
        for user in DB.prepare(songListTable) {
            if let imageCacheBytes = user[imageCache]?.bytes {
                let length = imageCacheBytes.count
                if length > 0 {
                    imageCacheData = NSData(bytes: imageCacheBytes, length: length)
                }
            }
            let song =  Song(
                title: user[title],
                imageURL: user[imageURL],
                musicURL: user[musicURL],
                singer: user[singer],
                favoriteFlag: user[favoriteFlag],
                imageCache: imageCacheData,
                savedName: user[savedName],
                IsPlaying: user[IsPlaying])
            songList.insert(song, atIndex: 0)
        }
        return songList
    }
    
    
    
    func insertSong(newSong: Song) {
        var rowExist: Bool = false
        
        for selection in DB.prepare(songListTable.select(musicURL)) {
            if selection[musicURL] == newSong.musicURL {
                rowExist = true
                print("row exist")
            }
        }
        if rowExist {
            let alice = songListTable.filter(musicURL == newSong.musicURL)
            alice.update(savedName <- newSong.savedName)
        } else {
            var imageCacheData: Blob?
            if let data = newSong.imageCache {
                imageCacheData = Blob(bytes: data.bytes, length: data.length)
            }
            let insert = songListTable.insert(
                self.title <- newSong.title,
                self.imageURL <- newSong.imageURL,
                self.musicURL <- newSong.musicURL,
                self.singer <- newSong.singer,
                self.favoriteFlag <- newSong.favoriteFlag,
                self.imageCache <- imageCacheData,
                self.IsPlaying <- newSong.IsPlaying,
                self.savedName <- newSong.savedName)
            do {
                try DB.run(insert)
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    func delSong(musicURL: String) {
        let alice = songListTable.filter(self.musicURL == musicURL)
        try! DB.run(alice.delete())
    }
    
//    func resetDB() {
//        try! DB.run(songListTable.drop(ifExists: true))
//        try! DB.run(settingTable.drop(ifExists: true))
//        print("DB Droped!")
//    }
}