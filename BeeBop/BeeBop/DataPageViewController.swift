//
//  DataPageViewController.swift
//  BeeBop
//
//  Created by Robert Lasell on 4/11/16.
//  Copyright © 2016 Tufts. All rights reserved.
//

import UIKit

/* Session Data Structure
 * sessions  -> array
 * - session     -> dictionary
 * --- tempo         -> int
 * --- level         -> int
 * --- song_name     -> string
 * --- drums         -> [int]
 * --- beat_sequence -> [int]
 * --- hit_sequence  -> [string]
 */


class DataPageViewController: UIViewController {

    @IBOutlet weak var filterControl: UISegmentedControl!
    @IBOutlet weak var chartView: UIView!
    @IBOutlet weak var graphView: UIView!
    
    /*************** FAKE DATA ******************/
    
    var testTempo = 120
    
    var testSongKey = 0
    
    var testBeatSequence = [0,0,0,0,0,0,0,0,
                            0,0,0,0,0,0,0,0,
                            0,0,0,0,0,0,0,0,
                            1,0,1,0,1,1,1,1,
                            1,0,1,0,1,1,1,1,
                            1,0,1,0,1,1,1,1,
                            1,0,1,0,1,1,1,1,
                            1,1,1,1,1,1,1,1,
                            1,1,1,1,1,1,0,1,
                            1,0,0,0]
    
    // 0 - no hit
    // 1 - correct hit
    // 2 - incorrect hit
    var testDrumSequence = [0,0,0,2,0,0,0,0,
                            0,0,0,0,0,0,0,0,
                            0,0,0,2,0,0,0,0,
                            1,0,1,0,1,1,0,1,
                            1,2,1,0,1,2,1,1,
                            1,0,1,0,1,1,0,1,
                            1,0,1,2,1,0,1,1,
                            2,1,1,1,1,1,1,2,
                            1,1,1,1,1,1,2,1,
                            1,0,2,0]
    
    // in seconds?
    var testReactionTimes = [0,0,0,0.2,0,0,0,0,
                             0,0,0,0,0,0,0,0,
                             0,0,0,0.2,0,0,0,0,
                             0.1,0,0.1,0,0.1,0.1,0,0.1,
                             0.1,0.2,0.1,0,0.1,0.2,0.1,0.1,
                             0.1,0,0.1,0,0.1,0.1,0,0.1,
                             0.1,0,0.1,0.2,0.1,0,0.1,0.1,
                             0.2,0.1,0.1,0.1,0.1,0.1,0.1,0.2,
                             0.1,0.1,0.1,0.1,0.1,0.1,0.2,0.1,
                             0.1,0,0.2,0]
    
    //in Newtons
    var testForce = [0,0,0,20,0,0,0,0,
                     0,0,0,0,0,0,0,0,
                     0,0,0,20,0,0,0,0,
                     10,0,10,0,10,10,0,10,
                     10,20,10,0,10,20,10,10,
                     10,0,10,0,10,10,0,10,
                     10,0,10,20,10,0,10,10,
                     20,10,10,10,10,10,10,20,
                     10,10,10,10,10,10,20,10,
                     10,0,20,0]
    
    /***************** END OF FAKE DATA ******************/
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

}
