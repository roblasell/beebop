//
//  SettingsTableViewController.swift
//  BeeBop
//
//  Created by Rob Lasell on April 11 2016
//  Copyright © 2016 Tufts. All rights reserved.
//
//  Table of settings for BeeBop companion app
//

import UIKit


class SettingsTableViewController: UITableViewController {
    
    // names of the available settings
    let settingsCells = ["Level", "Active Drums", "Bluetooth"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    // number of unique settings
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settingsCells.count
    }
    
    // cell to return for each type of setting
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell:UITableViewCell
        let setting = settingsCells[indexPath.row]
        
        if (setting == "Level") {
            cell = tableView.dequeueReusableCellWithIdentifier("LevelCell", forIndexPath: indexPath)
            cell.textLabel?.text = setting
        } else if (setting == "Active Drums") {
            cell = tableView.dequeueReusableCellWithIdentifier("ActiveDrumsCell", forIndexPath: indexPath)
            cell.textLabel?.text = setting
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
