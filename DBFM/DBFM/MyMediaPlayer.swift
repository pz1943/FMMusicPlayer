//
//  myMediaPlayer.swift
//  DBFM
//
//  Created by apple on 15/12/15.
//  Copyright © 2015年 pz1943. All rights reserved.
//

import Foundation
import MediaPlayer


class MyMediaPlayer: MPMoviePlayerController{
    
    init() {
//        
//        let url: String?
//        if song?.musicPath != nil {
//            url = song!.musicPath
//        } else {
//            url = song!.musicURL
//        }
        super.init(contentURL: NSURL())
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("AVAudioSessionError!")
        }

        NSNotificationCenter.defaultCenter().addObserverForName("MPMoviePlayerPlaybackDidFinishNotification", object: nil, queue: nil) { (notification) -> Void in
            if let reason = notification.userInfo?[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] as? Int {
                if (reason == MPMovieFinishReason.PlaybackEnded.rawValue) {
                    NSNotificationCenter.defaultCenter().postNotificationName("NSNotificationMPPlaybackEnded", object: nil)
                }
            }
        }
    }
    //MARK: - constants and outlets
    struct Constant {
        static let historyMaxCount = 20
    }
    let eHttp: HttpController = HttpController()
    

    func playMusic(song: Song?) {
        
        func fetchImage(song: Song) {
            var image: UIImage?
            
            func setPlayingInfo(title: String, artist: String, image: UIImage?...) {
                if image.count > 0 {
                    if let imageData = image[0] {
                        let artWork = MPMediaItemArtwork(image: imageData)
                        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
                            MPMediaItemPropertyTitle: title,
                            MPMediaItemPropertyArtist: artist,
                            MPMediaItemPropertyArtwork: artWork]
                    }
                } else {
                    MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = [
                        MPMediaItemPropertyTitle: title,
                        MPMediaItemPropertyArtist: artist]
                }
            }
            
            if song.imageCache != nil {
                if let image = UIImage( data: song.imageCache!) {
                    setPlayingInfo(song.title, artist: song.singer, image: image)
                } else {
                    setPlayingInfo(song.title, artist: song.singer)
                }
            } else {
                if let NSUrl = NSURL(string: song.imageURL) {
                    let qos = QOS_CLASS_USER_INITIATED
                    let queue: dispatch_queue_t = dispatch_get_global_queue(qos, 0)
                    dispatch_async(queue){
                        let imageData = NSData(contentsOfURL: NSUrl)
                        dispatch_async(dispatch_get_main_queue()){
                            if imageData != nil {
                                image = UIImage( data: imageData! )
                                setPlayingInfo(song.title, artist: song.singer, image: image)
                            }
                        }
                    }
                } else {
                    setPlayingInfo(song.title, artist: song.singer)
                }
            }
        }

        if song != nil {
            let NSUrl: NSURL
            if let url = song?.musicPath {
                NSUrl = NSURL(fileURLWithPath: url, isDirectory: false)
                
            } else {
                NSUrl = NSURL(string: song!.musicURL)!
            }
            fetchImage(song!)
            self.contentURL = NSUrl
            self.play()
        }
    }
    
    
    func PlayMusic(songList: [Song]?, cnt: Int) {
        if let list = songList {
            if cnt < list.count {
                playMusic(list[cnt])
            }
        }
    }
    
    func pauseMusic() {
        if self.playbackState == .Paused {
            self.play()
        } else {
            self.pause()
        }
    }
}

