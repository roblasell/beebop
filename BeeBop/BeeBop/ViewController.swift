//
//  ViewController.swift
//  BeeBop
//
//  Created by Rob Lasell on April 4 2016
//  With contributions by Aristana Scourtas on May 4 2016
//  Copyright © 2016 Tufts. All rights reserved.
//
//  View controller for the main screen of the BeeBop companion app,
//  where users can play a song and play along on the BeeBop drum peripheral.
//

import UIKit
import AVFoundation
import CoreBluetooth

// global bluetooth connection manager for UART chips
let nrfManager = NRFManager.sharedInstance

// for resetting NSUserDefaults (testing)
let RESET: Bool = false

// keys and default values for NSUserDefaults
let maxLevelKey     = "maxLevel"
let defaultMaxLevel = 3
let userLevelKey    = "userLevel"
let drumsKey        = "drums"

// keys for session dictionaries to be stored in a plist file
let tempoDataKey        = "tempo"
let levelDataKey        = "level"
let songNameDataKey     = "song_name"
let drumsDataKey        = "drums"
let beatSequenceDataKey = "beat_sequence"
let hitSequenceDataKey  = "hit_sequence"

// plist file used to store session data
let sessionDataFilename = "sessiondata.plist"


// MARK: - View Controller

class ViewController: UIViewController, NRFManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // user settings from NSUserDefaults
    var drums = []
    var activeDrums = 0
    
    // an array of sessions (songs played)
    var sessionData = NSMutableArray()
    // the current/most recent session
    var session = NSMutableDictionary()
    
    // song names to choose from
    var pickerSongs = ["SpongeRon Mingpants", "A Very Ming Chow Christmas", "Ron Ron Ron Your Boat", "I'm Ming and You're Chow", "Do the Ming'n'Ron Dance", "Ron Top of Old Smokey", "You're the Only Ron for Me", "Doo Wop (That Ming)", "The Lasser of Two Evils", "What a Day for a Mobile Medical Device"]
    // songs for squares
    // let boringSongs = ["Song1", "Song2", "Song3", "Song4", "Song5", "Song6", "Song7"]
    
    // array of songs corresponding to pickerSongs
    // like tempos, currently only contains one entry (for SpongeRon Mingpants)
    var songs: [NSURL] = [NSURL]()
    // parallel array of base tempos for each song
    var tempos = [120]
    
    /* data related to the playing of the audio */
    var songPlayer: AVAudioPlayer?
    var playing = false
    var paused = false
    
    /* current song data based on the user's choice from the picker data */
    var currentSong: NSURL!
    var currentSongIndex = 0
    var currentTempo = 0
    // seconds per beat, based on the chosen song's tempo
    var secPerBeat = 0.0
    // sequence of beats to play, based on the chosen song and difficulty level
    var beatSequence = [Int]()
    
    /* variables for the actual drum-playing logic */
    // the beat that the song is currently "on"
    var beatCounter = 0
    // the beat that we are waiting to hear back from the bluetooth device about
    var mostRecentBeat = 0
    // whether or not we are waiting to hear back from the bluetooth device
    var waiting = false
    // keeps time for the song, firing once per beat
    var timer = NSTimer()
    // stored data about the drums played by the user, received from the bluetooth device
    var hitSequence = [String]()
    
    // storyboard outlets
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var songPickerLabel: UILabel!
    @IBOutlet weak var songPicker: UIPickerView!
    
    // TODO: Beats seem to skip back a bit when waiting for bluetooth
    
    // parallel array of arrays of hard-coded sequences
    // of beats (1) and rests(0) for each song;
    // inner arrays correspond to the challenge levels
    // for a given song
    var beatSequences = [
        [ // SpongeRon Mingpants
            // level 1
            [0,0,0,0,1,0,0,0,0,0,1,0,0,0,0,0,
             0,0,0,1,0,0,0,0,1,0,1,0,1,1,1,1,
             1,0,1,0,1,1,1,1,1,0,1,0,1,1,1,1,
             1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,
             1,1,1,1,1,1,0,1,1,0,0,0],
            // level 2
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
             0,0,0,0,0,0,0,0,1,0,0,0,1,0,1,0,
             1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,
             1,0,0,0,1,0,1,0,1,0,1,0,1,0,1,0,
             1,0,1,0,1,0,0,1,1,0,0,0],
            // level 3
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
             0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,
             1,0,1,0,1,1,1,1,1,0,1,0,1,1,1,1,
             1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,
             1,1,1,1,1,1,0,1,1,0,0,0]
        ]
    ]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        makeFakeData()
        
        nrfManager.delegate = self
        
        initializeDefaults()
        
        loadSessionDataFromFile()
        
        // for demonstration purposes
        let spongebobPath = NSBundle.mainBundle().pathForResource("spongebob", ofType: "mp3")!
        songs = [NSURL.fileURLWithPath(spongebobPath)]
        
        // initialize the song and song player to
        // the first song in the picker
        currentSong = songs[0]
        currentSongIndex = 0
        
        songPlayer = AVAudioPlayer()

        songPicker.delegate = self
        songPicker.dataSource = self
    }
    
    //reassign the delegate so that it persists even if the view is changed
    override func viewDidAppear(animated: Bool) {
        nrfManager.delegate = self
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
        if (playing) {
            stopSong()
        }
        
        //if it's the SpongeRon MingPants song
        if (row == 0) {
            currentSong = songs[row]
            currentSongIndex = row
        } else {
            currentSong = NSURL()
            currentSongIndex = 0
            songPlayer = AVAudioPlayer()
        }
    }
    
    // called when the user presses the start/stop button;
    // plays or stops the chosen song
    @IBAction func buttonPressed (sender : AnyObject) -> Void {
        if (!playing) {
            playSong()
        } else {
            stopSong()
        }
    }
    
    func loadSongPlayer() {
        do {
            try songPlayer = AVAudioPlayer(contentsOfURL: currentSong)
        } catch {
            print("Player not available")
        }
    }
    
    func playSong() {
        let level = defaults.integerForKey(userLevelKey)
        currentTempo = tempos[currentSongIndex]
        let songName = pickerSongs[currentSongIndex]
        beatSequence = beatSequences[currentSongIndex][level - 1]
        beatCounter = 0
        mostRecentBeat = 0
        
        loadSongPlayer()
        
        activeDrums = 0
        drums = defaults.arrayForKey(drumsKey) as! [Int]
        // set activeDrums for use with randomDrum
        for d in drums {
            if d as! Int == 1 {
                activeDrums += 1
            }
        }
        
        //set time interval used in timer
        secPerBeat = 60.0 / Double(currentTempo)
        waiting = false
        paused = false
        
        session = NSMutableDictionary()
        session.setObject(currentTempo, forKey: tempoDataKey)
        session.setObject(level, forKey: levelDataKey)
        session.setObject(songName, forKey: songNameDataKey)
        session.setObject(drums, forKey: drumsDataKey)
        session.setObject(beatSequence, forKey: beatSequenceDataKey)
        
        hitSequence = [String](count: beatSequence.count, repeatedValue: "")
        
        playing = true
        startStopButton.setTitle("Stop Song", forState: UIControlState.Normal)
        songPlayer?.play()
        
        // Create a scheduled timer
        startTimer()
        
        // Add the timer to the main runloop
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    //stop the song if the song is over or if the user didn't hit the correct
    //beat in time
    func stopSong() {
        songPlayer?.stop()
        songPlayer = AVAudioPlayer()
        //stop the timer
        timer.invalidate()
        sendToDevice(String(drums.count))
        playing = false
        saveData()
        startStopButton.setTitle("Start Song", forState: UIControlState.Normal)
    }
    
    // called by timer, once per beat
    func singleBeat() {
        print("WHY, HELLO THERE! This is beat:", beatCounter)
        //if the song is playing and it's not the last beat of the song
        if (playing && beatCounter < beatSequence.count) {
            if (beatSequence[beatCounter] == 1) { //beat was a 1 i.e. not a rest
                if (!waiting) {
                    let drum = randomDrum()
                    sendToDevice(String(drum))
                    waiting = true
                    mostRecentBeat = beatCounter
                    beatCounter += 1
                } else { // waiting for confirmation
                    print("waiting for response for beat:", mostRecentBeat)
                    timer.invalidate()
                    paused = true
                    songPlayer?.pause()
                }
            } else { // beat was a 0 i.e. a rest
                beatCounter += 1
            }
        } else { // song stopped playing for whatever reason
            stopSong()
        }
    }
    
    func startTimer() {
        print("start timer")
        //create a new instance of the timer every time the song starts/resumes
        timer = NSTimer.scheduledTimerWithTimeInterval(
            secPerBeat,
            target: self,
            selector: #selector(ViewController.singleBeat),
            userInfo: nil,
            repeats: true)
        print(timer)
    }
    
    //send data string to peripheral
    func sendToDevice(msg: String) {
        print("sending:", msg, "to device")
        nrfManager.writeString(msg)
        //serial.sendMessageToDevice(msg)
        //serial.sendMessageToDevice("a")
    }
    
    //generate a random drum number to be hit
    func randomDrum() -> Int {
        let r = Int(arc4random_uniform(UInt32(activeDrums)))
        print("random is", r)
        var d = 0
        
        for i in 0...(drums.count - 1) {
            if (drums[i] as! NSObject == 1) {
                if (d == r) {
                    return i
                } else {
                    d += 1
                }
            }
        }
        
        return 0
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
        
        session.setObject(hitSequence, forKey: hitSequenceDataKey)
        sessionData.addObject(session)
        sessionData.writeToFile(path, atomically: false)
    }
    
    func loadSessionDataFromFile() {
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent(sessionDataFilename)
        
        //print(path)
        
        
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
        
        //print(sessionData)
        
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
    
    // called when the bluetooth device sends the app a message
    func nrfReceivedData(nrfManager: NRFManager, data: NSData?, string: String?) {
        print("in nrfReceivedData")
        hitSequence[mostRecentBeat] = string!
        waiting = false
        
        print (hitSequence)
        
        print("received", string!)
        
        if (!playing) {
            print("ViewController: Received a message from the bluetooth device, but song was not playing")
            return
        }
        
        if (paused) {
            print("in paused conditional with mostRecentBeat:", mostRecentBeat)
            //if paused, need to also start timer and song
            print("setting song to time:", String(secPerBeat * Double(beatCounter)))
            songPlayer?.currentTime = secPerBeat * Double(beatCounter)
            print("starting timer")
            startTimer()
            print("starting song at beat:", beatCounter)
            songPlayer?.play()
            paused = false
        } else {
            print ("not paused")
        }
        
        print("at end of nrfReceivedData")
    }
    
    // called if the device disconnects for whatever reason
    func nrfDidDisconnect(nrfManager: NRFManager) {
        // reloadView()
        //display the progress in the overlay
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Disconnected from Device"
        hud.hide(true, afterDelay: 1.0)
    }
    
    func nrfDidUpdateStatus(nrfManager: NRFManager, state: CBCentralManagerState) {
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        if(state == .PoweredOn){
            hud.labelText = "Bluetooth Enabled"
        } else if (state == .PoweredOff){
            hud.labelText = "Bluetooth Disabled"
        }
        hud.hide(true, afterDelay: 1.0)
    }
}

