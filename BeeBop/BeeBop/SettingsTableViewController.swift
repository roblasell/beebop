//
//  SettingsTableViewController.swift
//  BeeBop
//
//  Created by Robert Lasell on 4/11/16.
//  Copyright © 2016 Tufts. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {
    
    let settingsCells = ["Level", "Active Drums", "Bluetooth"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false
        
        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsCells.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell
        let setting = settingsCells[indexPath.row]
        
        if (setting == "Level") {
            cell = tableView.dequeueReusableCellWithIdentifier("LevelCell", forIndexPath: indexPath)
            cell.textLabel?.text = setting
        } else if (setting == "Active Drums") {
            cell = tableView.dequeueReusableCellWithIdentifier("ActiveDrumsCell", forIndexPath: indexPath)
            cell.textLabel?.text = setting
        /*} else if (setting == "Handedness") {
            cell = tableView.dequeueReusableCellWithIdentifier("HandednessCell", forIndexPath: indexPath)
            cell.textLabel?.text = setting
        } else if (setting == "Hit Force") {
            cell = tableView.dequeueReusableCellWithIdentifier("HitForceCell", forIndexPath: indexPath)
            cell.textLabel?.text = setting*/
        } else if (setting == "Bluetooth") {
            cell = tableView.dequeueReusableCellWithIdentifier("BluetoothCell", forIndexPath: indexPath)
            cell.textLabel?.text = setting
        } else {
            cell = UITableViewCell()
        }
        
        cell.accessoryType = UITableViewCellAccessoryType.DisclosureIndicator
        
        return cell
    }
}
