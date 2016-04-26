//
//  ViewController.swift
//  BeeBop
//
//  Created by Rob Lasell on 4/11/16.
//  Copyright © 2016 Tufts. All rights reserved.
//
//  View controller for the main screen of BeeBop,
//  where users can play a song and play along on
//  the BeeBop drum peripheral.
//


import UIKit
import AVFoundation

// for resetting NSUserDefaults (testing)
let RESET: Bool = false

// keys and default values for NSUserDefaults
let maxLevelKey     = "maxLevel"
let defaultMaxLevel = 3
let userLevelKey    = "userLevel"
let drumsKey        = "drums"

// keys for storing to plist
let tempoDataKey        = "tempo"
let levelDataKey        = "level"
let songNameDataKey     = "song_name"
let drumsDataKey        = "drums"
let beatSequenceDataKey = "beat_sequence"
let hitSequenceDataKey  = "hit_sequence"

// plist file used to store session data
let sessionDataFilename = "sessiondata.plist"


class ViewController: BTCommunicationViewController, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // storyboard outlets
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var songPickerLabel: UILabel!
    @IBOutlet weak var songPicker: UIPickerView!
    
    var songPlayer: AVAudioPlayer?
    var currentSong: NSURL!
    var playing: Bool = false
    
    // an array of sessions (songs played)
    var sessionData = NSMutableArray()
    // the current/most recent session
    var session = NSMutableDictionary()

    // song names to choose from
    var pickerSongs: [String] = ["SpongeRon Mingpants", "A Very Ming Chow Christmas", "Ron Ron Ron Your Boat", "I'm Ming and You're Chow", "Do the Ming'n'Ron Dance", "Ron Top of Old Smokey", "You're the Only Ron for Me", "Doo Wop (That Ming)", "The Lasser of Two Evils", "What a Day for a Mobile Medical Device"]
    
    // array of songs corresponding to pickerSongs
    // array would be expanded given more time and resources
    var songs: [NSURL] = [NSURL]()
    // parallel array of base tempos for each song
    var tempos = [120]
    
    // parallel array of arrays of hard-coded sequences
    // of beats (1) and rests(0) for each song;
    // inner arrays correspond to the challenge levels
    // for a given song
    var beatSequences = [
        [[], [],
        
         [0,0,0,0,0,0,0,0,
         0,0,0,0,0,0,0,0,
         0,0,0,0,0,0,0,0,
         1,0,1,0,1,1,1,1,
         1,0,1,0,1,1,1,1,
         1,0,1,0,1,1,1,1,
         1,0,1,0,1,1,1,1,
         1,1,1,1,1,1,1,1,
         1,1,1,1,1,1,0,1,
         1,0,0,0]
        ]
    ]
    
    // songs for squares
    // let boringSongs = ["Song1", "Song2", "Song3", "Song4", "Song5", "Song6", "Song7"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeFakeData()
        
        serial = DZBluetoothSerialHandler(delegate: self)
        
        initializeDefaults()
        
        loadSessionDataFromFile()
        
        // for deomnstration purposes
        let spongebobPath = NSBundle.mainBundle().pathForResource("spongebob", ofType: "mp3")!
        songs = [NSURL.fileURLWithPath(spongebobPath)]
        
        // initialize the song and song player to
        // the first song in the picker
        currentSong = songs[0]
        do {
            try songPlayer = AVAudioPlayer(contentsOfURL: currentSong)
        } catch {
            print("Player not available")
        }

        songPicker.delegate = self
        songPicker.dataSource = self
    }
    
    // initialize NSUserDefaults values for each key
    // if they do not already exist
    func initializeDefaults() {
        // reset all values for testing purposes
        if (RESET) {
            defaults.removeObjectForKey(maxLevelKey)
            defaults.removeObjectForKey(userLevelKey)
            defaults.removeObjectForKey(drumsKey)
        }
        
        defaults.setInteger(defaultMaxLevel, forKey: maxLevelKey)
        
        if (defaults.integerForKey(userLevelKey) > defaultMaxLevel
         || defaults.integerForKey(userLevelKey) < 1) {
            defaults.setInteger(1, forKey: userLevelKey)
        }
        
        if (defaults.arrayForKey(drumsKey) == nil) {
            defaults.setObject([1, 1, 0, 1], forKey: drumsKey)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerSongs.count
    }
    
    // data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerSongs[row]
    }
    
    // called when the user selects a new item from the song picker
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // ensure that the user can only play the
        // demonstration song, "SpongeRon MingPants"
        if (row == 0) {
            currentSong = songs[row]
            do {
                try songPlayer = AVAudioPlayer(contentsOfURL: currentSong)
            } catch {
                print("Player not available")
            }
        } else {
            currentSong = NSURL()
            songPlayer = AVAudioPlayer()
        }
    }
    
    // called when the user presses the start/stop button;
    // plays or stops the chosen song
    @IBAction func buttonPressed (sender : AnyObject) -> Void {
        if (!playing) {
            songPlayer?.play()
            playing = true
            startStopButton.setTitle("Stop Song", forState: UIControlState.Normal)
        } else {
            songPlayer?.stop()
            playing = false
            startStopButton.setTitle("Start Song", forState: UIControlState.Normal)
            saveData()
        }
    }
    
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
    func makeFakeData() {
        sessionData = NSMutableArray()
        makeFakeSession1()
        sessionData.addObject(session)
        makeFakeSession2()
        sessionData.addObject(session)
        
        //print(data)
    }
    
    func makeFakeSession1() {
        session = NSMutableDictionary()
        session.setObject(tempos[0], forKey: tempoDataKey)
        session.setObject(3, forKey: levelDataKey)
        session.setObject(pickerSongs[0], forKey: songNameDataKey)
        session.setObject(defaults.arrayForKey(drumsKey) as! [Int], forKey: drumsDataKey)
        session.setObject(beatSequences[0][2], forKey: beatSequenceDataKey)
        
        let fakeHitSequence = ["","","","","","","","",
                               "","","","","","","","",
                               "","","","","","","","",
                               "0 570","","3 1 1200","","1 3 3 3 0 4000","1 1000","1 0 2000","3 750",
                               "0 570","","3 1 1200","","1 3 3 3 0 4000","1 1000","1 0 2000","3 750",
                               "0 570","","3 1 1200","","1 3 3 3 0 4000","1 1000","1 0 2000","3 750",
                               "0 570","","3 1 1200","","1 3 3 3 0 4000","1 1000","1 0 2000","3 750",
                               "1 320","3 450","3 0 2400","1 1300","1 320","3 450","3 0 2400","1 1300",
                               "1 320","3 450","3 0 2400","1 1300","1 320","3 450","","1 1300",
                               "0 1 0 0 1 3 5738","","",""]
        
        session.setObject(fakeHitSequence, forKey: hitSequenceDataKey)
    }
    
    func makeFakeSession2() {
        session = NSMutableDictionary()
        session.setObject(80, forKey: tempoDataKey)
        session.setObject(1, forKey: levelDataKey)
        session.setObject(pickerSongs[1], forKey: songNameDataKey)
        session.setObject(defaults.arrayForKey(drumsKey) as! [Int], forKey: drumsDataKey)
        
        let fakeBeatSequence = [0,0,1,1,1,0,1,0,1,0]
        session.setObject(fakeBeatSequence, forKey: beatSequenceDataKey)
        
        let fakeHitSequence = ["","","0 1750","1 0 3 3457","3 1 2345","","0 0 0 1 244","","1 3 3245",""]
        session.setObject(fakeHitSequence, forKey: hitSequenceDataKey)
    }
    
    // write session data to a plist file
    // partially sourced from http://rebeloper.com/read-write-plist-file-swift/
    func saveData() {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent(sessionDataFilename)
        
        sessionData.writeToFile(path, atomically: false)
    }
    
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
            }
        } else {
            print("sessiondata.plist already exits at path.")
            // use this to delete file from documents directory
            // fileManager.removeItemAtPath(path, error: nil)
        }
        
        // load the file's contents into sessionData
        sessionData = NSMutableArray(contentsOfFile: path)!

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

