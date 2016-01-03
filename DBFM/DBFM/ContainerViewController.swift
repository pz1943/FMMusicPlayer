//
//  ContainerViewController.swift
//  DBFM
//
//  Created by apple on 15/12/4.
//  Copyright © 2015年 pz1943. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol ContainerViewControllerDataSource {
    func getSongList() -> [Song]
    func getPlayingRow() -> Int
}

class ContainerViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserverForName("NSNotifationRefreshListTableView", object: nil, queue: NSOperationQueue.mainQueue()) { (data) -> Void in
            self.tableReload()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        if tableneedReloadedFlag == true {
            self.listTableView.reloadData()
            tableneedReloadedFlag = false
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        tableReload()
        tableneedReloadedFlag = true
    }
    
    var songList: Array<Song> = []
    var playingRow: Int = 0
    var dataSource: ContainerViewControllerDataSource?
    var tableneedReloadedFlag: Bool = false
    @IBOutlet weak var listTableView: UITableView! //tableView
    
    @IBAction func favoriteSet(sender: UISwitch) { //notify mainViewController favorite set had been changed
        if let cell = sender.superview?.superview as? UITableViewCell {
            if let row = listTableView.indexPathForCell(cell)?.row {
                NSNotificationCenter.defaultCenter().postNotificationName("NSNotificationFavoriteSetDidChange", object: self, userInfo: ["row": row, "switch": sender.on])
            }
        }
    }
    
    @IBAction func refresh(sender: UIRefreshControl) { //get a new song
        NSNotificationCenter.defaultCenter().postNotificationName("NSNotificationNeedANewSong", object: self)
        sender.endRefreshing()
    }
    
    func tableReload() {
        songList = dataSource!.getSongList()
        playingRow = dataSource!.getPlayingRow()
        self.listTableView.reloadData()
        if songList.count > playingRow {
            NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "selectRowAtIndexPath", userInfo: nil, repeats: false)
        }
    }
   
    func selectRowAtIndexPath() {
        listTableView.selectRowAtIndexPath(NSIndexPath(forRow: playingRow, inSection: 0), animated: true, scrollPosition: UITableViewScrollPosition.Middle)
    }

    func delSongAtIndexPath(indexPath: NSIndexPath) {
        NSNotificationCenter.defaultCenter().postNotificationName("songDeletedNotification", object: self, userInfo: ["deletedRow": indexPath.row, "musicURL": songList[indexPath.row].musicURL])
    }
    
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        delSongAtIndexPath(indexPath)
    }
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return songList.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        NSNotificationCenter.defaultCenter().postNotificationName("NSNotificationTableViewDidSelectRow", object: self, userInfo: ["songData": songList, "selectedRow": indexPath.row])
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let dequeued: AnyObject = listTableView.dequeueReusableCellWithIdentifier("douban", forIndexPath: indexPath)
        let cell = dequeued as! ListTableViewCell
        let song = self.songList[indexPath.row]
        cell.tileLabel.text = song.title
        cell.artistLabel.text = song.singer
        cell.favoriteSwitch.on = song.favoriteFlag ?? false
        if song.imageCache == nil {
            if let url = NSURL(string: song.imageURL) {
                let qos = QOS_CLASS_USER_INITIATED
                let queue: dispatch_queue_t = dispatch_get_global_queue(qos, 0)
                dispatch_async(queue){
                    let imageData = NSData(contentsOfURL: url)
                    dispatch_async(dispatch_get_main_queue()){
                        if imageData != nil {
                            let image = UIImage( data: imageData! )
                            cell.thumbImageView.image = image
                            self.songList[0].imageCache = imageData!
                        }
                    }
                }
            }
        } else {
            cell.thumbImageView.image = UIImage(data: song.imageCache!)
        }
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
