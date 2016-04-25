//
//  ActiveDrumsTableViewController.swift
//  BeeBop
//
//  Created by Robert Lasell on 4/25/16.
//  Copyright © 2016 Tufts. All rights reserved.
//

import UIKit

class ActiveDrumsTableViewController: UITableViewController {

    let defaults = NSUserDefaults.standardUserDefaults()
    
    var drums = [Int]()
    
    @IBOutlet var tableview: UITableView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        drums = defaults.arrayForKey(drumsKey) as! [Int]
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return drums.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("DrumCell", forIndexPath: indexPath)
        cell.textLabel?.text = String(indexPath.row + 1)
        
        if (drums[indexPath.row] == 0) {
            cell.detailTextLabel!.text = "Inactive"
        } else {
            cell.detailTextLabel!.text = "Active"
        }

        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        drums[indexPath.row] = abs(drums[indexPath.row] - 1)
        tableView.reloadData()
    }
    
    // gets called when you press the save button
    @IBAction func buttonPressed (sender : AnyObject) -> Void {
        defaults.setObject(drums, forKey: drumsKey)
    }
}
