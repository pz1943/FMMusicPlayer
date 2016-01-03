//
//  SettingViewController.swift
//  DBFM
//
//  Created by apple on 15/12/1.
//  Copyright © 2015年 pz1943. All rights reserved.
//

import UIKit

class SettingViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        NSNotificationCenter.defaultCenter().addObserverForName("NSNotificationGotChannelData", object: nil, queue: NSOperationQueue.mainQueue()) { (notifation) -> Void in
            let userInfo = notifation.userInfo
            self.channelData = userInfo!["channelsData"] as! Array<Dictionary<String, String>>
            NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "scrollToRow:", userInfo: NSIndexPath(forRow: self.selectedRow, inSection: 1), repeats: false)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        NSTimer.scheduledTimerWithTimeInterval(0.2, target: self, selector: "scrollToRow:", userInfo: NSIndexPath(forRow: self.selectedRow, inSection: 1), repeats: false)
    }
    
    @IBOutlet weak var channelTableView: UITableView!

    @IBAction func disMissChannelVC(sender: UIBarButtonItem) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    var selectedChannel: Int = 0
    var selectedRow: Int = 0
    var mode: PlayerMode = .FMMode
    var channelData: Array<Dictionary<String, String>> = []
    
    func scrollToRow(timer: NSTimer) {
        let indexPath = timer.userInfo as! NSIndexPath
        if channelData.count > indexPath.row {
            channelTableView.reloadData()
            channelTableView.selectRowAtIndexPath(indexPath, animated: true, scrollPosition: UITableViewScrollPosition.Middle)
        }
    }

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else {
            return channelData.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let dequeued: AnyObject = channelTableView.dequeueReusableCellWithIdentifier("mode cell", forIndexPath: indexPath)
            let cell = dequeued as! ModeSettingTableViewCell
            cell.modeSettingSegment.selectedSegmentIndex = self.mode.rawValue
            return cell
        } else {
            let dequeued: AnyObject = channelTableView.dequeueReusableCellWithIdentifier("channel", forIndexPath: indexPath)
            let cell = dequeued as! UITableViewCell
            cell.textLabel?.text = channelData[indexPath.row]["name"]
            return cell
        }
    }
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "循环模式"
        } else {
            return "频道"
        }
    }
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        if indexPath.section == 1 {
            if let x = channelData[indexPath.row]["channel_id"] {
                selectedChannel = NSString(string: x).integerValue
                selectedRow = indexPath.row
            }
        }
        return indexPath
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "select a new channel" {
            if let DVC = segue.destinationViewController as? MainViewController {
                DVC.currentChannel = selectedChannel
                DVC.selectedRowOfchannelView = selectedRow
                DVC.removeFMSong()
                DVC.needANewSongFlag = true
                self.selectedRow = 0
            }
        }
        if segue.identifier == "modeSetting" {
            if let DVC = segue.destinationViewController as? MainViewController {
                if let segment = sender as? UISegmentedControl{
                    if let mode = PlayerMode(rawValue: segment.selectedSegmentIndex) {
                        DVC.mode = mode
                        if mode == .FMMode
                        {
                            DVC.playingRow = 0
                            DVC.needANewSongFlag = true
                            self.selectedRow = 0
                        }
                        if mode == PlayerMode.LocalMode {
                            if DVC.songList[DVC.playingRow].favoriteFlag == false {
                                DVC.playingRow = DVC.songList.count - 1
                            }
                        }
                    }
                }
            }
        }
    }
}
