//
//  DataPageViewController.swift
//  BeeBop
//
//  Created by Aristana Scourtas and Rob Lasell, last updates 5/8/16
//  Copyright © 2016 Tufts. All rights reserved.
//
//  Guided by
//  http://sourcefreeze.com/uisegmentedcontrol-example-using-swift-in-ios/
//
// Note: This page only has the logic for computing weekly data, but has the 
//  capacity to compute monthly and yearly data as well. Currently all monthly
//  and yearly data is filled by dummy data.

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


class DataPageViewController: UIViewController{
    
    @IBOutlet weak var filterControl: UISegmentedControl!
    
    @IBOutlet weak var percentCorrectGraphView: GraphView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var hitForceGraphView: GraphView!
    @IBOutlet weak var reactionTimeGraphView: GraphView!
    
    //variables for data that will continually be updated as new data comes in
    var numIncorrectDrums:Int = 0
    var accelValue:Int = 0
    var timeValue:Int = 0
    var numStrings:Int = 0
    
    var numCorrectDrums:Int = 0
    var numAccelStrings:Int = 0
    
    //the data stored in the plist for every game play
    var sessionData = NSMutableArray()
    
    //hold average values displayed in graph
    var reactionTimesWeek:[Double] = [0,0,0,0,0,0,0]
    var percentCorrectWeek:[Double] = [0,0,0,0,0,0,0]
    var hitForceWeek:[Double] = [0,0,0,0,0,0,0]
    
    //dummy data for reaction times
    var testReactionTimesMonth:[Double] = [1, 3, 4, 2, 1, 4, 2, 5, 2,
                                           3, 1, 4, 1, 3, 4, 2, 1, 4,
                                           2, 5, 2, 3, 1, 4, 2, 4, 1,
                                           3, 2, 4]
    var testReactionTimesYear:[Double] = [2,3,2,3,2,4,3,4,3, 1, 2, 3]
    

    
    //dummy data for percent correct
    var testPercentCorrectMonth:[Double] = [9,8,7,6,5,4,3]
    var testPercentCorrectYear:[Double] = [10, 23, 34, 45, 46, 34]
    
    //dummy data for hit force
    var testForceMonth:[Double] = [2, 4, 6, 4, 3, 0, 2, 4,6, 8, 10, 8, 6, 4]
    var testForceYear: [Double] = [39, 33, 12, 23, 12]
    
    //dummy hit sequence data
    var hitSequence = ["","","","","","","","",
                           "","","","","","","","",
                           "","","","","","","","",
                           "0 570","","3 1 1200","","1 3 3 3 0 4000",
                           "1 1000","1 0 2000","3 750",
                           "0 570","","3 1 1200","","1 3 3 3 0 4000",
                           "1 1000","1 0 2000","3 750",
                           "0 570","","3 1 1200","","1 3 3 3 0 4000",
                           "1 1000","1 0 2000","3 750",
                           "0 570","","3 1 1200","","1 3 3 3 0 4000",
                           "1 1000","1 0 2000","3 750",
                           "1 320","3 450","3 0 2400","1 1300","1 320",
                           "3 450","3 0 2400","1 1300",
                           "1 320","3 450","3 0 2400","1 1300","1 320",
                           "3 450","","1 1300",
                           "0 1 0 0 1 3 5738","","",""]

    override func viewDidLoad() {
        
        
        //fix the segment titles because it wasn't working in IB for some reason
        filterControl.setTitle("Week", forSegmentAtIndex: 0)
        filterControl.setTitle("Month", forSegmentAtIndex: 1)
        filterControl.setTitle("Year", forSegmentAtIndex: 2)
        
        super.viewDidLoad()

        //loads the data from all sessions in order to use it in graph 
        //point calculations
        loadSessionDataFromFile()
        
        let lastIndex = sessionData.count - 1
        
        //get the data from the most recent game play data
        let lastSession = sessionData[lastIndex]
        let mostRecentDate = lastSession.objectForKey(dateDataKey) as! NSDate
        let mostRecentWeekday = mostRecentDate.dayOfWeek()!
        
        //for choosing the array index of data averages to be displayed
        let offset = 6 - mostRecentWeekday

        var day = mostRecentWeekday

        numStrings = 0
        //if day of week == day of week mod 7 plus 1
        for i in (0...(sessionData.count - 1)).reverse() {


            //if day > 7 days ago, end
            let tempSession = sessionData[i]
            
            let sessionDate = tempSession.objectForKey(dateDataKey) as! NSDate
            let sessionWeekday = sessionDate.dayOfWeek()
            
            //if we've moved on to the next day of the next week, stop
            if(mostRecentDate.timeIntervalSinceDate(sessionDate) > 518400){
                    break
            }
            
            //if we've progressed to the previous day
            if(sessionWeekday != day) {

                storeDay(day, offset:offset)
                day = sessionWeekday!

                
            }
            
            
            
            //get the data for the game play session that has to do with hits
            hitSequence = tempSession.objectForKey(hitSequenceDataKey) as! [String]
            
            for i in 0...(hitSequence.count - 1) {
                if (hitSequence[i] != "") {
                    //store the data
                    parseHitString(hitSequence[i])
                    numStrings += 1
                }
            }
        }
        
        storeDay(day, offset: offset)
        
        
        //send the appropriate UIviews their respecive data
        hitForceGraphView.setHitForce(hitForceWeek)
        reactionTimeGraphView.setReactionTime(reactionTimesWeek)
        percentCorrectGraphView.setPercentCorrect(percentCorrectWeek)
        
    }
    
    //store the given day's average values in the data arrays to be displayed
    func storeDay(day: Int, offset: Int) {

        let index = (day + offset) % 7
        //set the data arrays with averages for each day of the week
        reactionTimesWeek[index] = Double(timeValue) / Double(numStrings)

        percentCorrectWeek[index] = Double(numCorrectDrums) /
                        (Double(numCorrectDrums) + Double(numIncorrectDrums))

        hitForceWeek[index] = Double(accelValue) / Double(numAccelStrings)

        // reset all of the global variables
        numStrings = 0
        accelValue = 0
        timeValue = 0
        numAccelStrings = 0
        numCorrectDrums = 0
        numIncorrectDrums = 0
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    @IBAction func filterControlAction(sender: AnyObject) {
        //if the "Week" segment is selected
        if (filterControl.selectedSegmentIndex == 0) {
            hitForceGraphView.setHitForce(hitForceWeek)
            hitForceGraphView.redisplayView()
            
            reactionTimeGraphView.setReactionTime(reactionTimesWeek)
            reactionTimeGraphView.redisplayView()
            
            percentCorrectGraphView.setPercentCorrect(percentCorrectWeek)
            percentCorrectGraphView.redisplayView()
            
        
        }
        //if the "Month" segment is selected
        if (filterControl.selectedSegmentIndex == 1) {
            hitForceGraphView.setHitForce(testForceMonth)
            hitForceGraphView.redisplayView()
            
            reactionTimeGraphView.setReactionTime(testReactionTimesMonth)
            reactionTimeGraphView.redisplayView()
            
            percentCorrectGraphView.setPercentCorrect(testPercentCorrectMonth)
            percentCorrectGraphView.redisplayView()
            
        }
        //if the "Year" segment is selected
        if(filterControl.selectedSegmentIndex == 2) {
            hitForceGraphView.setHitForce(testForceYear)
            hitForceGraphView.redisplayView()
            
            reactionTimeGraphView.setReactionTime(testReactionTimesYear)
            reactionTimeGraphView.redisplayView()
            
            percentCorrectGraphView.setPercentCorrect(testPercentCorrectYear)
            percentCorrectGraphView.redisplayView()
        }
       
        
    }
    
    //extract the data values from the string received via Bluetooth
    func parseHitString(sequenceStr:String){
        //parse the string
        var segments =  sequenceStr.componentsSeparatedByString(" ")
        if (segments[segments.count - 1] == ""){
            segments.removeLast()
        }

        //the acceleration will be the last segment of the string
        var accelString = "0"
        if (Double(segments[segments.count - 1]) != -1.00) {
            accelString = segments[segments.count - 1]
            numAccelStrings += 1
        }

        //the reaction time will be the second to last segment of the string
       
        let timeString = segments[segments.count - 2]
        
        if (segments.count > 3){
            numIncorrectDrums += 1
        } else {
            numCorrectDrums += 1
        }
        
        //aggregate the values to later take the average
        accelValue = accelValue + Int(Double(accelString)!)
        timeValue = timeValue + Int(Double(timeString)!)


    }
    
    
    //Rob's function, loads data from plist
    func loadSessionDataFromFile() {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent(sessionDataFilename)
        
        
        let fileManager = NSFileManager.defaultManager()
        // check if file exists
        if(!fileManager.fileExistsAtPath(path)) {
            // if it doesn't, copy it from the default file in the bundle
            if let bundlePath = NSBundle.mainBundle().pathForResource("sessiondata", ofType: "plist") {
                do {
                    try fileManager.copyItemAtPath(bundlePath, toPath: path)
                } catch {
                    print("seeData: Unable to copy file")
                }
            } else {
                print("sessiondata.plist not found. Please make sure that it is part of the bundle.")
                print("Making new sessiondata.plist")
                let newArray = NSMutableArray()
                newArray.writeToFile(path, atomically: false)
            }
        } else {
            print("sessiondata.plist already exits at path.")
        }

        // load the file's contents into sessionData
       sessionData = NSMutableArray(contentsOfFile: path)!
       }

    
}



