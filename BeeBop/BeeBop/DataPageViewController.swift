//
//  DataPageViewController.swift
//  BeeBop
//
//  Created by Robert Lasell on 4/11/16.
//  Edited by Aristana Scourtas on 4/30/16.
//  Copyright © 2016 Tufts. All rights reserved.
//
// Guided by http://sourcefreeze.com/uisegmentedcontrol-example-using-swift-in-ios/
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




class DataPageViewController: UIViewController{
    
    
    @IBOutlet weak var filterControl: UISegmentedControl!
    
    
        
    
    
   
    @IBOutlet weak var percentCorrectGraphView: GraphView!

    @IBOutlet weak var hitForceGraphView: GraphView!
    @IBOutlet weak var reactionTimeGraphView: GraphView!

    var numIncorrectDrums:Int = 0
    var accelValue:Int = 0
    var timeValue:Int = 0
    var numStrings:Int = 0
    
    var numCorrectDrums:Int = 0
    var numAccelStrings:Int = 0
    
    /*************** FAKE DATA ******************/
    
    var sessionData = NSMutableArray()
    
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
    var test:[Double] = [0,0,0,0.2,0,0,0,0,
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
    var testForceWeek:[Double] = [0,0,0,20,0,0,0,0,
                     0,0,0,0,0,0,0,0,
                     0,0,0,20,0,0,0,0,
                     10,0,10,0,10,10,0,10,
                     10,20,10,0,10,20,10,10,
                     10,0,10,0,10,10,0,10,
                     10,0,10,20,10,0,10,10,
                     20,10,10,10,10,10,10,20,
                     10,10,10,10,10,10,20,10,
                     10,0,20,0]
    var testReactionTimesWeek:[Double] = [0,1,0.7,2,2.3,3,4,5,1,7]
    var testReactionTimesMonth:[Double] = [1, 3, 4, 2, 1, 4]
    var testReactionTimesYear:[Double] = [2,3,2,3,2,4,3,4,3]
    
    var reactionTimesWeek:[Double] = [0,0,0,0,0,0,0]
    var percentCorrectWeek:[Double] = [0,0,0,0,0,0,0]
    var hitForceWeek:[Double] = [0,0,0,0,0,0,0]
    
    var testPercentCorrectWeek:[Double] = [0.1, 0.2, 0.3, 1, 2, 3, 4,6]
    var testPercentCorrectMonth:[Double] = [9,8,7,6,5,4,3]
    var testPercentCorrectYear:[Double] = [10, 23, 34, 45, 46, 34]
    
    var testForceMonth:[Double] = [2, 4, 6, 4, 3, 0, 2, 4,6, 8, 10, 8, 6, 4]
    var testForceYear: [Double] = [39, 33, 12, 23, 12]
    
    var hitSequence = ["","","","","","","","",
                           "","","","","","","","",
                           "","","","","","","","",
                           "0 570","","3 1 1200","","1 3 3 3 0 4000","1 1000","1 0 2000","3 750",
                           "0 570","","3 1 1200","","1 3 3 3 0 4000","1 1000","1 0 2000","3 750",
                           "0 570","","3 1 1200","","1 3 3 3 0 4000","1 1000","1 0 2000","3 750",
                           "0 570","","3 1 1200","","1 3 3 3 0 4000","1 1000","1 0 2000","3 750",
                           "1 320","3 450","3 0 2400","1 1300","1 320","3 450","3 0 2400","1 1300",
                           "1 320","3 450","3 0 2400","1 1300","1 320","3 450","","1 1300",
                           "0 1 0 0 1 3 5738","","",""]
    let date = NSDate()
    
    /***************** END OF FAKE DATA ******************/
    
    override func viewDidLoad() {
        
        
        //fix the segment titles because it wasn't working in IB for some reason
        filterControl.setTitle("Week", forSegmentAtIndex: 0)
        filterControl.setTitle("Month", forSegmentAtIndex: 1)
        filterControl.setTitle("Year", forSegmentAtIndex: 2)
        
        super.viewDidLoad()
        print("loading data in DataPageViewController")
        
        //loads the data from all sessions in order to use it in graph point calculations
        loadSessionDataFromFile()
        
        
        var lastIndex = sessionData.count - 1
        var lastSession = sessionData[lastIndex]
        var mostRecentDate = lastSession.objectForKey(dateDataKey) as! NSDate
        var mostRecentWeekday = mostRecentDate.dayOfWeek()!
        
        var offset = 6 - mostRecentWeekday
        
        print("MOST RECENT DAY", mostRecentWeekday)
        
        //var today = 6 //last day
        var day = mostRecentWeekday
        //mod 7?
        
        numStrings = 0
        //if day of week == day of week mod 7 plus 1
        for i in (0...(sessionData.count - 1)).reverse() {

            print("IN MAIN LOOP")
            //if day > 7 days ago, end
            let tempSession = sessionData[i]
            
            //print("TEMP SESSION:",tempSession) // TEST
            
            let sessionDate = tempSession.objectForKey(dateDataKey) as! NSDate
            let sessionWeekday = sessionDate.dayOfWeek()
            
            //if we've moved on to the next day of the next week, stop
            if(mostRecentDate.timeIntervalSinceDate(sessionDate) > 518400){
                print("In if statement, you should not see this")
                break
            }
            
            //if we've progressed to the previous day
            if(sessionWeekday != day) {
                
                print("IN SESSIONWEEKDAY != DAY", sessionWeekday)
                
                storeDay(day, offset:offset)
                day = sessionWeekday!
                // reset all of the global variables
                
            }
            
            
            
            
            hitSequence = tempSession.objectForKey(hitSequenceDataKey) as! [String]
            
            for i in 0...(hitSequence.count - 1) {
                if (hitSequence[i] != "") {
                    print("parsing string:", hitSequence[i])
                    parseHitString(hitSequence[i])
                    numStrings += 1
                }
            }
        }
        
        storeDay(day, offset: offset)
        
        print("reactionTimesWeek", reactionTimesWeek)
        
  
        
        /*let testString:String = "1 2 3 2 0 1314 511"
        let testString2:String = "1 5672 388"
        let testString3:String = "0 3784 -1"
        //create a parse function, in that function add force to force array, add reaction time to reaction time array (seconds), increment numCorrectDrums, so that later we can divide that by total num of beats to get percent correct
        print("about to parse that sequence!")
        parseHitString(testString3)*/
        
        
        //send the appropriate views their respecive data
        hitForceGraphView.setHitForce(hitForceWeek)
        reactionTimeGraphView.setReactionTime(reactionTimesWeek)
        percentCorrectGraphView.setPercentCorrect(percentCorrectWeek)

 
        
        
        
    }
    
    func storeDay(day: Int, offset: Int) {
        print("IN STOREDAY with day =", day)
        reactionTimesWeek[day + offset] = Double(timeValue) / Double(numStrings)
        
        percentCorrectWeek[day + offset] = Double(numCorrectDrums) / (Double(numCorrectDrums) + Double(numIncorrectDrums))
        
        hitForceWeek[day + offset] = Double(accelValue) / Double(numAccelStrings)
        
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
        
        if(filterControl.selectedSegmentIndex == 2) {
            hitForceGraphView.setHitForce(testForceYear)
            hitForceGraphView.redisplayView()
            
            reactionTimeGraphView.setReactionTime(testReactionTimesYear)
            reactionTimeGraphView.redisplayView()
            
            percentCorrectGraphView.setPercentCorrect(testPercentCorrectYear)
            percentCorrectGraphView.redisplayView()
        }
       
        
    }
//    override func viewWillAppear(animated: Bool) {
//        hitForceGraphView.redisplayView()
//    }
    
    
    func parseHitString(sequenceStr:String){
        
        var segments =  sequenceStr.componentsSeparatedByString(" ")
        if (segments[segments.count - 1] == ""){
            segments.removeLast()
        }
        print(segments)
        //the acceleration will be the last segment of the string
        var accelString = "0"
        if (Double(segments[segments.count - 1]) != -1.00) {
            accelString = segments[segments.count - 1]
            numAccelStrings += 1
        }
        print("AFTER ACCELSTRING ASSIGNMENT IN PARSE", Int(Double(accelString)!))
        //the reaction time will be the second to last segment of the string
       
        var timeString = segments[segments.count - 2]
        print("TIMESTRING IS", timeString)
        
        if (segments.count > 3){
            numIncorrectDrums += 1
        } else {
            numCorrectDrums += 1
        }
        
        print("AFTER CORRECTDRUMS ASSIGNMENT IN PARSE")
        
        accelValue = accelValue + Int(Double(accelString)!)
        print("between!")
        timeValue = timeValue + Int(Double(timeString)!)
        
//        print("accelString is "+accelString)
//        print("timeString is "+timeString)
        
        
        //pre-split knowledge
//        //make the parameter a mutable variable
//        var sequence = sequence
//        
//        var index = sequence.startIndex
//
//        var accelString:String = ""
//        
//        var timeString:String = ""
//        
//        var numIncorrectDrums:Int = 0
//        
//        var accelStringLength:Int = 0
//        
//        
//        index = sequence.endIndex.predecessor()
//        
//        //check to see if there's valid acceleration data; if there isn't, there will be a "-1" at the end
//        let lastTwoChars =  String(sequence[index.predecessor()]) + String(sequence[index])
//        print("the last two chars are", lastTwoChars)
//        
//        //set the length of the acceleration string, with a +1 to account for the space
//        accelStringLength = lastTwoChars.characters.count + 1
//        
//        //if there's a valid acceleration value
//        if (lastTwoChars != "-1"){
//            print("in last 2 char if statement")
//            //find the index at which the acceleration starts
//            while (sequence[index] != " "){
//                index = index.predecessor()
//            
//            }
//            //copy over the acceleration from that index
//            while (index != sequence.endIndex){
//                accelString += String(sequence[index])
//                index = index.successor()
//            }
//            //update length of acceleration string accordingly, with a +1 to account for the space
//            accelStringLength = accelString.characters.count + 1
//        }
//        
//        print("acceleration is", accelString)
//        
//        
//       
//        
//        //delete the acceleration string from the main string
//        let stringRange = sequence.endIndex.advancedBy(-accelStringLength)..<sequence.endIndex
//        sequence.removeRange(stringRange)
//        
//        
//        print("sequence is now "+sequence+".")
//        //note: endIndex points off the end of the string
//        //start from the beginning of the string
//        index = sequence.startIndex
//        var nextChar = ""
//        var currentChar = ""
//        
//        while (index != sequence.endIndex.predecessor()){
//            print(sequence[index])
//            //need to cast as a string to convert into an int
//            
//            
//            currentChar = String(sequence[index])
//          //  if (String(sequence[index.successor()]) != nil){
//                nextChar = String(sequence[index.successor()])
//           // }
//            
//            if(currentChar != " "){
//              
//                //if there are 2 non-space char in a row, then it's a reaction time
//                if (nextChar != " " || index.successor() == sequence.endIndex){
//                    //if the reaction time is further than the 2nd index in the string (0-based), then wrong drums were hit
//                    if(index > sequence.startIndex.advancedBy(2-1)){
//                        print("first char of time stamp at index", index)
//                        numIncorrectDrums += 1
//                    }
//                    timeString = timeString + currentChar
//                }
////                if(nextChar == " "){
////               // var c = sequence[index]
////                //if this isn't a space but the next thing is, it must be a drumNum
////                    drumNum = Int(currentChar)!
////                }else if(nextChar != " "){
////                    num = num + Int(currentChar)!
////                }
//            }
//            
//            //iterate through string
//            index = index.successor()
//        }
//        
//        print("timeString is", timeString)
//        
////        for char in sequence.characters{
////            if(char != " "){
////               drumNum = Int(char)
////                
////            }
////        }
    }
    
    
    
    
    //Rob's function, loads data from plist
    func loadSessionDataFromFile() {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent(sessionDataFilename)
        
        print(path)
        
        
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
                newArray.writeToFile(path, atomically: false)//
            }
        } else {
            print("sessiondata.plist already exits at path.")
            // use this to delete file from documents directory
            // fileManager.removeItemAtPath(path, error: nil)
        }
        
        //let newArray = NSMutableArray()
        //newArray.writeToFile(path, atomically: false)
        
        // load the file's contents into sessionData
       sessionData = NSMutableArray(contentsOfFile: path)!
        
        //print(NSMutableArray(contentsOfFile: path))
        
       // print(sessionData)
        
        /* for testing purposes
         var testArray = NSArray(contentsOfFile: path)
         if let arr = testArray {
         //loading values
         let session1:NSDictionary = testArray![0] as! NSDictionary
         let session1tempo = session1.objectForKey(tempoDataKey)
         
         //print("session 1 tempo is ", session1tempo)
         //...
         } else {
         print("WARNING: Couldn't create array from sessiondata.plist! Default values will be used!")
         }
         */
        
    }

    
}



