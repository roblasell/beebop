//
//  SessionsPageViewController.swift
//  BeeBop
//
//  Created by Robert Lasell on 4/11/16.
//  Copyright © 2016 Tufts. All rights reserved.
//

import UIKit

class SessionsPageViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var filterControl: UISegmentedControl!
    @IBOutlet weak var sessionsTable: UITableView!
    
    let dateSessionsCells = ["Friday 4/8", "Thursday 4/7", "Monday 4/4", "Saturday 4/2"]
    let songSessionsCells = ["A Very Ming Chow Christmas", "Ron Ron Ron Your Boat", "I'm Ming and You're Chow", "Do the Ming'n'Ron Dance", "Ron Top of Old Smokey", "You're the Only Ron for Me", "Doo Wop (That Ming)", "The Lasser of Two Evils", "What a Day for a Mobile Medical Device"]
    let boringSongs = ["Song1", "Song2", "Song3", "Song4", "Song5", "Song6", "Song7"]
    var sessionCells = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        sessionsTable.delegate = self
        sessionsTable.dataSource = self
        sessionCells = dateSessionsCells
        sessionsTable.reloadData()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func indexChanged(sender:UISegmentedControl) {
        switch filterControl.selectedSegmentIndex {
            case 0:
                sessionCells = dateSessionsCells
                sessionsTable.reloadData()
            
            case 1:
                //sessionsCells = songSessionsCells
                sessionCells = boringSongs
                sessionsTable.reloadData()
                
            default:
                break
        }
    }
    
    // MARK: - Table view data source
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sessionCells.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell:UITableViewCell
            
        if (filterControl.selectedSegmentIndex == 0) {
            cell = tableView.dequeueReusableCellWithIdentifier("DateCell", forIndexPath: indexPath)
            cell.textLabel?.text = sessionCells[indexPath.row]
        } else if (filterControl.selectedSegmentIndex == 1) {
            cell = tableView.dequeueReusableCellWithIdentifier("SongCell", forIndexPath: indexPath)
            cell.textLabel?.text = sessionCells[indexPath.row]
        } else {
            cell = UITableViewCell()
        }
        
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
}
