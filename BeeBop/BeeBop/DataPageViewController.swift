//
//  DataPageViewController.swift
//  BeeBop
//
//  Created by Robert Lasell on 4/11/16.
//  Copyright © 2016 Tufts. All rights reserved.
//

import UIKit

class DataPageViewController: UIViewController {

    @IBOutlet weak var filterControl: UISegmentedControl!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var graphView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
