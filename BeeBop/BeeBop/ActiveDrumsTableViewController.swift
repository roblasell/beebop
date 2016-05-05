//
//  ActiveDrumsTableViewController.swift
//  BeeBop
//
//  Created by Rob Lasell on April 25 2016
//  Copyright © 2016 Tufts. All rights reserved.
//
//  View Controller that allows the user to decide which drums
//  will be used
//

import UIKit


class ActiveDrumsTableViewController: UITableViewController {

    let defaults = NSUserDefaults.standardUserDefaults()
    
    // each element represents one drum, with a 0 indicating that that
    // drum is not in use, and a 1 indicating that that drum is in use
    var drums = [Int]()
    // maps drum numbers to the colors of the BeeBop drum peripheral drums
    var drumNames = ["Red", "Orange", "Blue", "Yellow"]
    
    // storyboard outlets
    @IBOutlet var tableview: UITableView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        drums = defaults.arrayForKey(drumsKey) as! [Int]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - IBActions

    // saves drums to NSUserDefaults when the user presses the save button
    @IBAction func buttonPressed (sender : AnyObject) -> Void {
        defaults.setObject(drums, forKey: drumsKey)
    }
    
    
    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    // number of total drums, not just active drums
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drums.count
    }
    
    // cell to return for each drum
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCellWithIdentifier("DrumCell", forIndexPath: indexPath)
        cell.textLabel?.text = drumNames[indexPath.row]
        
        if (drums[indexPath.row] == 0) {
            cell.detailTextLabel!.text = "Inactive"
        } else {
            cell.detailTextLabel!.text = "Active"
        }

        return cell
    }
    
    // when the user selects a drum, switch its state (0 to 1 or 1 to 0)
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        drums[indexPath.row] = abs(drums[indexPath.row] - 1)
        tableView.reloadData()
    }
}
