//
//  ViewController.swift
//  DBFM
//
//  Created by apple on 15/11/30.
//  Copyright © 2015年 pz1943. All rights reserved.
//

import UIKit
import MediaPlayer
import SwiftyJSON
import Alamofire

//MARK: - TODO
// update to new player
//use 4G?
//内存泄露
//write a document for SQLite.swift?
//private
//icon
//down progress

class MainViewController: UIViewController, HttpProtocol, ContainerViewControllerDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        eHttp.delegate = self
        db = SongListDB.sharedInstance()
        setNotification()
        songList = db!.loadSongList()
        if let settings = db!.loadSettings(){
            selectedRowOfchannelView = settings["selectedChannelIndex"] ?? 0
            mode = PlayerMode(rawValue: (settings["mode"])!) ?? .FMMode
        }
        refreshUI()
    }
    
    override func viewWillAppear(animated: Bool) {
        playCurrentRow()
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        UIApplication.sharedApplication().endReceivingRemoteControlEvents()
        self.resignFirstResponder()
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func remoteControlReceivedWithEvent(event: UIEvent?) {
        if event?.type == UIEventType.RemoteControl {
            switch event!.subtype {
            case UIEventSubtype.RemoteControlPlay:
                musicPlayer.pauseMusic()
            case UIEventSubtype.RemoteControlPause:
                musicPlayer.pauseMusic()
            case UIEventSubtype.RemoteControlPreviousTrack:
                PlayPreviousSong()
            case UIEventSubtype.RemoteControlNextTrack:
                playNextSong()
            default:
                break
            }
        }
    }
    //MARK: - var
    var db: SongListDB?
    let eHttp = HttpController()
    let musicPlayer = MyMediaPlayer()
    var songList: [Song] = []
    var channelsData: [[String: String]] = []

    var refreshTimer: NSTimer?
    var currentChannel: Int = 0
    var selectedRowOfchannelView: Int = 0 {
        didSet {
            db?.saveSelectedChannelIndex(selectedRowOfchannelView)
        }
    }
    var mode: PlayerMode = .FMMode {
        didSet {
            db?.saveMode(mode)
        }
    }
    var playingRow: Int = 0
    var needANewSongFlag = false
    
    struct Constants {
        static let historyMaxCount = 20
        static let songURL = "http://douban.fm/j/mine/playlist"
        static let tableName = "songList"
    }
    
    //MARK: - refresh
    func refreshUI() {
        playedTime = 0.0
        playedSlider.setValue(0, animated: false)
        refreshImageView()
        refreshListTableView()
        startRefreshTimer()
    }
    
    func startRefreshTimer() {
        if refreshTimer?.valid == true {
            refreshTimer?.fire()
        } else {
            refreshTimer = NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "refreshPlayedTimeLabel:", userInfo: nil, repeats: true)
        }
    }
    
    func refreshPlayedTimeLabel(timer: NSTimer ) {
        if musicPlayer.playbackState == MPMoviePlaybackState.Playing {
            let seconds = floor(musicPlayer.currentPlaybackTime as Double)
            playedTime = seconds
            if musicPlayer.duration != 0.0 {
                playedSlider.setValue(Float(seconds / musicPlayer.duration), animated: false)
            }
        }
    }

    func refreshImageView() {
        func fetchImage(imageURL: String) {
            if let NSUrl = NSURL(string: imageURL) {
                let qos = QOS_CLASS_USER_INITIATED
                let queue: dispatch_queue_t = dispatch_get_global_queue(qos, 0)
                dispatch_async(queue){
                    let imageData = NSData(contentsOfURL: NSUrl)
                    dispatch_async(dispatch_get_main_queue()){
                        if imageData != nil {
                            let image = UIImage( data: imageData! )
                            self.imageView.image = image
                            self.songList[0].imageCache = imageData!
                        } else {
                            self.imageView.image = nil
                        }
                    }
                }
            }
        }
        
        if let song = songList.first {
            if song.imageCache == nil {
                fetchImage(song.imageURL)
            } else {
                self.imageView.image = UIImage(data: song.imageCache!)
            }
        }
    }
    
    func refreshListTableView() {
        NSNotificationCenter.defaultCenter().postNotificationName("NSNotifationRefreshListTableView", object: self, userInfo: ["songData": songList, "playingRow": playingRow])
    }
    
    
    //MARK: - callBackMethod
    func didRecieveList(results: JSON){
        if let jsonData = results["song"][0].dictionary{
            if songList.count > 0 {
                for i in 0 ..< songList.count {
                    if jsonData["title"]?.string == songList[i].title {
                        NSNotificationCenter.defaultCenter().postNotificationName("NSNotificationNeedANewSong", object: self)
                        return
                    }
                }
            }
            let newSong = Song(
                title: jsonData["title"]!.stringValue,
                imageURL: jsonData["picture"]!.stringValue,
                musicURL: jsonData["url"]!.stringValue,
                singer: jsonData["singers"]![0]["name"].stringValue
            )
            if songList.count < Constants.historyMaxCount{
                songList.insert(newSong, atIndex: 0)
            } else {
                songList.insert(newSong, atIndex: 0)
                songList.removeLast()
            }
            playingRow = 0
            playCurrentRow()
            NSNotificationCenter.defaultCenter().postNotificationName("NSNotificationGotNewSong", object: self, userInfo: ["songData": songList])
        }
    }
    
    func didRecieveChannel(results: JSON) {
        if let jsonData = results["channels"].array {
            channelsData.removeAll(keepCapacity: false)
            for info in jsonData {
                let name = info["name"].stringValue
                let channel_id = info["channel_id"].stringValue
                channelsData.append(["name": name, "channel_id": channel_id])
            }
            NSNotificationCenter.defaultCenter().postNotificationName("NSNotificationGotChannelData", object: self, userInfo: ["channelsData": channelsData])
        }
    }
    
    //MARK: - music controll
    func saveMusicInRow(row :Int) {
        let song = songList[row]
        if song.favoriteFlag == false {
            songList[row].favoriteFlag = true
            self.db?.insertSong(song)
            Alamofire.download(
                .GET, song.musicURL,
                destination: {
                    temporaryURL, response -> NSURL in
                    let directoryURLs = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
                    if !directoryURLs.isEmpty {
                        let directoryURL = directoryURLs[0].URLByAppendingPathComponent(response.suggestedFilename!)
                        //MARK:??? row dif when set
                        self.songList[row].savedName = response.suggestedFilename!
                        self.db?.insertSong(song)
                        return directoryURL
                    }
                    return temporaryURL
            })
                .response(completionHandler: { (_, _, data, _) -> Void in
                    print("downLoad done row = \(row)")
                    if self.songList[row].favoriteFlag == false {
                        self.delMusicInRow(row)
                    }
                })
                .progress({ (_, remaining, total) -> Void in
                    print("remaining \(total - remaining) bytes")
                })
        }
    }
    
    func delMusicInRow(row: Int) {
        let song = songList[row]
        if  song.savedName != nil {
            song.favoriteFlag = false
            do {
                try NSFileManager.defaultManager().removeItemAtPath(song.musicPath!)
                db!.delSong(song.musicURL)
                songList[row].savedName = nil
                print("del done row =\(row)")
                
            } catch let error as NSError {
                print(error)
            }
        } else {
            if song.savedName == nil {
                song.favoriteFlag = false
            }
        }
    }
    func playCurrentRow() {
        if needANewSongFlag == true {
            getASong()
            playingRow = 0
            needANewSongFlag = false
            return
        }
        if songList.count > playingRow {
            musicPlayer.PlayMusic(self.songList, cnt: self.playingRow)
        } else {
            if songList.count > 0 {
                print("OH! playing at row \(playingRow)")
                self.musicPlayer.playMusic(self.songList.first)
            } else {
                getASong()
            }
        }
    }
    
    func playNextSong() {
        switch mode {
        case .FMMode:
            if playingRow > 0 {
                playingRow -= 1
                playCurrentRow()
                refreshUI()
            } else {
                getASong()
            }
        case .LocalMode:
            if playingRow > 0 {
                playingRow -= 1
            } else {
                playingRow = songList.count - 1
            }
            playCurrentRow()
            refreshUI()
        case .singleMode:
            playCurrentRow()
        }
    }
    
    func PlayPreviousSong() {
        if playingRow < songList.count - 1 {
            playingRow += 1
            playCurrentRow()
        }
    }
    
    
    func getASong() {
        let parameter: [String: AnyObject] = ["type": "n" ,"channel": currentChannel, "from": "mainsite"]
        let url = Constants.songURL
        eHttp.onSearchList(url, parameter: parameter)
    }
    
    func searchChannel() {
        eHttp.onSearchChannel("http://www.douban.com/j/app/radio/channels")
    }

    func removeFMSong() {
        for var index = songList.count - 1; index >= 0 ; index--  {
            if songList[index].favoriteFlag == false {
                songList.removeAtIndex(index)
            }
        }
    }
    //MARK: - segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "ListTableView" {
            if let DVC = segue.destinationViewController as? ContainerViewController {
                DVC.songList = self.songList
                DVC.dataSource = self
            }
        } else {
            if segue.identifier == "show channel" {
                if let NVC = segue.destinationViewController as? UINavigationController {
                    if let DVC = NVC.topViewController as? SettingViewController {
                        DVC.selectedRow = self.selectedRowOfchannelView
                        DVC.mode = self.mode
                    }
                }
                searchChannel()
            }
        }
    }
    
    //MARK: - outlets
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var playedSlider: UISlider!
    @IBOutlet weak var label: UILabel!
    @IBAction func backToMain(segue: UIStoryboardSegue) {

    }

    var playedTime: Double {
        set {
            if newValue.isNaN == false {
                let sec = Int(newValue % 60)
                let min = Int(newValue / 60 )
                var timeLabelText = ""
                if sec < 10 {
                    if min < 10 {
                        timeLabelText = "0\(min):0\(sec)"
                    } else {
                        timeLabelText = "\(min):0\(sec)"
                    }
                } else {
                    if min < 10 {
                        timeLabelText = "0\(min):\(sec)"
                    } else {
                        timeLabelText = "\(min):\(sec)"
                    }
                }
                label.text = timeLabelText
            }
        }
        get { return self.playedTime }
    }
    
    
    @IBAction func playedSliderTouchDown(sender: UISlider) {
        refreshTimer?.invalidate()
    }
    
    @IBAction func playedSliderChanging(sender: UISlider) {
        let duration = musicPlayer.duration as Double
        playedTime = Double(sender.value) * duration
    }
    
    @IBAction func playedSliderChanged(sender: UISlider) {
        let duration = musicPlayer.duration as Double
        musicPlayer.currentPlaybackTime = Double(sender.value) * duration
        startRefreshTimer()
    }
    
    @IBAction func pauseMusic(sender: UIButton) {
        musicPlayer.pauseMusic()
    }
    func setNotification() {
        //MARK: - to be modified
        NSNotificationCenter.defaultCenter().addObserverForName("NSNotificationTableViewDidSelectRow", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let data = notification.userInfo {
                self.songList = data["songData"] as! Array<Song>
                self.playingRow = data["selectedRow"] as? Int ?? 0
                if self.songList[self.playingRow].favoriteFlag == true {
                    self.mode = .LocalMode
                }
                self.playCurrentRow()
                self.refreshImageView()
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("NSNotificationFavoriteSetDidChange", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let data = notification.userInfo {
                let flag = data["switch"] as! Bool
                let row = data["row"] as! Int
                if flag {
                    self.saveMusicInRow(row )
                } else {
                    self.delMusicInRow(row )
                }
            }
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("NSNotificationNeedANewSong", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.refreshTimer?.invalidate()
            self.getASong()
        }
        
        NSNotificationCenter.defaultCenter().addObserverForName("NSNotificationMPPlaybackEnded", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            self.refreshTimer?.invalidate()
            self.playNextSong()
        }
        NSNotificationCenter.defaultCenter().addObserverForName("songDeletedNotification", object: nil, queue: NSOperationQueue.mainQueue()) { (notification) -> Void in
            if let musicURLToDel = notification.userInfo?["musicURL"] as? String {
                if let row = notification.userInfo?["deletedRow"] as? Int{
                    if musicURLToDel == self.songList[row].musicURL {
                        if self.songList[row].favoriteFlag == true {
                            self.db?.delSong(self.songList[row].musicURL)
                            if let path = self.songList[row].musicPath {
                                let _ = try? NSFileManager.defaultManager().removeItemAtPath(path)
                            }
                        }
                        self.songList.removeAtIndex(row)
                        if self.playingRow > row {
                            self.playingRow -= 1
                        } else if self.playingRow == row {
                            if self.playingRow > 0 {
                                self.playingRow -= 1
                            }
                            self.refreshImageView()
                            self.playCurrentRow()
                        }
                        self.refreshListTableView()
                    }
                }
            }
        }

        NSNotificationCenter.defaultCenter().addObserverForName("NSNotificationGotNewSong", object: nil, queue: NSOperationQueue.mainQueue(), usingBlock: {
            notification in
            self.songList = notification.userInfo!["songData"] as! Array<Song>
            if self.mode != .FMMode {
                self.mode = .FMMode
            }
            self.refreshUI()
        })
    }
    
    //MARK: - dataSource
    func getSongList() -> [Song] {
        return songList
    }
    func getPlayingRow() -> Int {
        return playingRow
    }
}

