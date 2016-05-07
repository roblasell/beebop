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


// MARK: - Global data

// global bluetooth connection manager for UART chips
let nrfManager = NRFManager.sharedInstance

// for resetting NSUserDefaults (testing)
let RESET: Bool = false

// keys and default values for NSUserDefaults
let maxLevelKey     = "maxLevel"
let defaultMaxLevel = 4
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


// MARK: - ViewController data

class ViewController: UIViewController, NRFManagerDelegate, UIPickerViewDelegate, UIPickerViewDataSource {
    
    let defaults = NSUserDefaults.standardUserDefaults()
    
    // due to the way bluetooth messages are sent, we divide messages from the device
    // into chunks of 20 bytes and send a final message containing this end token to
    // signal the end of the message
    let endToken = "END"
    var messageSoFar = ""
    
    // user settings from NSUserDefaults
    var drums = []
    var activeDrums = 0
    
    // an array of sessions (songs played)
    var sessionData = NSMutableArray()
    // the current/most recent session
    var session = NSMutableDictionary()
    
    // song names to choose from
    var pickerSongs = ["SpongeRon Mingpants", "A Very Ming Chow Christmas", "Ron Ron Ron Your Boat", "I'm Ming and You're Chow", "Do the Ming'n'Ron Dance", "Ron Top of Old Smokey", "Hello, It's Ming", "Space Rondity", "We 3 Mings", "You're the Only Ron for Me", "Doo Wop (That Ming)", "The Lasser of Two Evils", "What a Day for a Mobile Medical Device", ""]
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
    var userLevel = 1
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
    
    // parallel array of arrays of hard-coded sequences of beats (1) and rests(0) for each song;
    // inner arrays correspond to the challenge levels
    // for a given song
    var beatSequences = [
        [ // SpongeRon Mingpants
            // level 1
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,0,0,
             0,0,1,0,0,0,0,0,0,0,1,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,
             0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            // level 2
            [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,1,0,0,0,1,0,0,0,1,0,
             0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,0,0,1,0,
             0,0,1,0,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            // level 3
            [0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,1,0,1,0,0,0,1,0,
             1,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,0,0,1,0,1,0,1,0,1,0,1,0,
             1,0,1,0,1,0,1,0,0,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
            // level 4
            [0,0,0,0,0,1,0,0,0,0,0,0,1,0,0,0,0,0,0,0,0,0,1,0,1,0,1,1,1,1,1,0,
             1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,0,1,0,1,1,1,1,1,1,1,1,1,1,1,1,1,1,
             1,1,1,1,1,1,1,1,0,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0]
        ],
        [ // more songs would go here
            // level 1
            [],
            // level 2
            [],
            // level 3
            [],
            // level 4 (hard)
            []
        ]
        // etc
    ]
    
    
    // MARK: - ViewController initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nrfManager.delegate = self

        // initialize user settings, previous session data, and songs
        initializeDefaults()
        loadSessionDataFromFile()
        initializeSongURLS()
        
        // initialize the song to the first song in the picker
        currentSong = songs[0]
        currentSongIndex = 0
        
        songPlayer = AVAudioPlayer()
        songPicker.delegate = self
        songPicker.dataSource = self
    }
    
    // reassign the NRFManager delegate to ViewController
    override func viewDidAppear(animated: Bool) {
        nrfManager.delegate = self
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // set up "songs" array to contain URLs pointing to the song mp3s
    func initializeSongURLS() {
        // currently only contains one song, SpongeRon Mingpants
        let path = NSBundle.mainBundle().pathForResource("SpongeRon Mingpants", ofType: "mp3")!
        let spongeron = NSURL.fileURLWithPath(path)
        
        songs = [spongeron]
    }
    
    // initialize NSUserDefaults values for each key if they do not already exist
    func initializeDefaults() {
        // reset all values (for testing purposes)
        if (RESET) {
            defaults.removeObjectForKey(maxLevelKey)
            defaults.removeObjectForKey(userLevelKey)
            defaults.removeObjectForKey(drumsKey)
        }
        
        defaults.setInteger(defaultMaxLevel, forKey: maxLevelKey)
        
        // default level is 1 (easy)
        if (defaults.integerForKey(userLevelKey) > defaultMaxLevel
         || defaults.integerForKey(userLevelKey) < 1) {
            defaults.setInteger(1, forKey: userLevelKey)
        }
        
        // activate all drums
        if (defaults.arrayForKey(drumsKey) == nil) {
            defaults.setObject([1, 1, 1, 1], forKey: drumsKey)
        }
    }
    
    
    // MARK: - Picker view data source and delegate

    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // number of songs in the picker
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerSongs.count
    }
    
    // data (song name) to return for the given row (song index) of the picker
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerSongs[row]
    }
    
    // called when the user selects a new item from the song picker
    // sets the current song to the newly chosen picker item
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if (playing) {
            stopSong()
        }
        
        // ensure that the user can only play the demonstration song, "SpongeRon MingPants"
        if (row == 0) { // index of SRMP
            currentSong = songs[row]
            currentSongIndex = row
        } else { // any other song
            currentSong = NSURL()
            currentSongIndex = 0
            songPlayer = AVAudioPlayer()
        }
    }
    
    
    // MARK: - IBActions
    
    // called when the user presses the start/stop button;
    // plays or stops the chosen song
    @IBAction func buttonPressed (sender : AnyObject) -> Void {
        if (!playing) {
            startSong()
        } else {
            stopSong()
        }
    }
    
    
    // MARK: - Song and drum logic
    
    // set up song and session data based on the user's song choice and settings
    func prepareToPlaySong() {
        // first, set variables that track user and song settings
        userLevel = defaults.integerForKey(userLevelKey)
        currentTempo = tempos[currentSongIndex]
        beatSequence = beatSequences[currentSongIndex][userLevel - 1]
        
        activeDrums = 0
        drums = defaults.arrayForKey(drumsKey) as! [Int]
        // set activeDrums for use with randomDrum
        for d in drums {
            if d as! Int == 1 {
                activeDrums += 1
            }
        }
        
        // initialize variables used for drum logic
        beatCounter = 0
        mostRecentBeat = 0
        //set time interval used in timer
        secPerBeat = 60.0 / Double(currentTempo)
        hitSequence = [String](count: beatSequence.count, repeatedValue: "")
        
        // initialize session that will later be saved
        session = NSMutableDictionary()
        session.setObject(currentTempo, forKey: tempoDataKey)
        session.setObject(userLevel, forKey: levelDataKey)
        session.setObject(pickerSongs[currentSongIndex], forKey: songNameDataKey)
        session.setObject(drums, forKey: drumsDataKey)
        session.setObject(beatSequence, forKey: beatSequenceDataKey)
        
        // prepare song player
        loadSongPlayer()
        waiting = false
        paused = false
    }
    
    // set up the song player before playing the drums
    func loadSongPlayer() {
        do {
            try songPlayer = AVAudioPlayer(contentsOfURL: currentSong)
        } catch {
            print("Player not available")
        }
    }
    
    // start an NSTimer that fires once every secPerBeat seconds (i.e., once per beat);
    // every time it fires, the timer calls singleBeat
    func startTimer() {
        //create a new instance of the timer every time the song starts/resumes
        timer = NSTimer.scheduledTimerWithTimeInterval(
            secPerBeat,
            target: self,
            selector: #selector(ViewController.singleBeat),
            userInfo: nil,
            repeats: true)
    }
    
    // prepare to play a song and begin the drum logic
    func startSong() {
        // set up current song and session data
        // in anticipation of the drum logic
        prepareToPlaySong()
        
        playing = true
        startStopButton.setTitle("Stop Song", forState: UIControlState.Normal)
        
        // start the audio and the beat timer
        songPlayer?.play()
        startTimer()
        // add the timer to the main runloop
        NSRunLoop.mainRunLoop().addTimer(timer, forMode: NSRunLoopCommonModes)
    }
    
    // called by timer, once per beat;
    // this is the majority of the drum logic
    func singleBeat() {
        //if the song is playing and we have not reached the end of the song
        if (playing && beatCounter < beatSequence.count) {
            if (beatSequence[beatCounter] == 1) { //beat was a 1 i.e. not a rest
                print("BEAT:", beatCounter) // TEST output
                if (!waiting) { // enter a waiting state if not already waiting
                    // chooses a random drum from the currently active drums
                    let drum = randomDrum()
                    
                    // tell the bluetooth device to cue the user to play the drum
                    sendToDevice(String(drum))
                    
                    waiting = true
                    mostRecentBeat = beatCounter
                    beatCounter += 1
                } else { // pause song if waiting for confirmation from bt device
                    print("waiting for response for beat:", mostRecentBeat)
                    timer.invalidate()
                    paused = true
                    songPlayer?.pause()
                }
            } else { // beat was a 0 i.e. a rest
                print("rest:", beatCounter) // TEST output
                beatCounter += 1
            }
        } else { // song stopped playing for whatever reason
            stopSong()
        }
    }
    
    
    //send data string to bluetooth peripheral
    func sendToDevice(msg: String) {
        //print("sending:", msg, "to device") // TEST
        nrfManager.writeString(msg)
    }
    
    //generate a random drum number to be hit,
    // choosing from the currently active drums
    func randomDrum() -> Int {
        let r = Int(arc4random_uniform(UInt32(activeDrums)))
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
    
    // stop the song if the song is over or stops for some other reason
    func stopSong() {
        // end song player
        songPlayer?.stop()
        songPlayer = AVAudioPlayer()
        
        //stop the timer
        timer.invalidate()
        
        // tell the drum peripheral the song is over
        sendToDevice(String(drums.count))
        
        playing = false
        startStopButton.setTitle("Start Song", forState: UIControlState.Normal)
        
        // store the session with the
        // previous sessions in a plist file
        saveData()
    }

    
    // MARK: - Data loading and storage
    
    /* Session Data Structure Legend
     * * * * * * * * * * * * * * * *
     * sessions  -> array
     * - session     -> dictionary
     * --- tempo         -> int
     * --- level         -> int
     * --- song_name     -> string
     * --- drums         -> [int]
     * --- beat_sequence -> [int]
     * --- hit_sequence  -> [string]
     */
    
    // write session data to a plist file
    func saveData() {
        // get path for the data file
        let paths = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true) as NSArray
        let documentsDirectory = paths.objectAtIndex(0) as! NSString
        let path = documentsDirectory.stringByAppendingPathComponent(sessionDataFilename)
        
        // add hit sequence to session, add session to the list of
        // previous sessions, and write the list to the data file
        session.setObject(hitSequence, forKey: hitSequenceDataKey)
        sessionData.addObject(session)
        sessionData.writeToFile(path, atomically: false)
    }
    
    // load the data from previous sessions into sessionData
    // data is stored in a plist file on the iOS device
    func loadSessionDataFromFile() {
        // get path for the data file
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
            // if there is no default, make a new file with an empty session list
            } else {
                print("sessiondata.plist not found. Please make sure that it is part of the bundle.")
                print("Making new sessiondata.plist")
                let newArray = NSMutableArray()
                newArray.writeToFile(path, atomically: false)//
            }
        } else {
            print("sessiondata.plist already exits at path.")
            
            // uncomment to delete file from documents directory
            // fileManager.removeItemAtPath(path, error: nil)
        }
        
        // load the file's contents into sessionData
        sessionData = NSMutableArray(contentsOfFile: path)!

        
        /* TEST: print the loaded data
        var testArray = NSArray(contentsOfFile: path)
        if let arr = testArray {
            //loading values
            let session1:NSDictionary = testArray![0] as! NSDictionary
            let session1tempo = session1.objectForKey(tempoDataKey)
            
            //print("session 1 tempo is ", session1tempo)
            //...
        } else {
            print("No data found!")
        }
        */
    }
    
    // MARK: - NRFManagerDelegate methods
    
    // called when the bluetooth device sends the app a message
    func nrfReceivedData(nrfManager: NRFManager, data: NSData?, string: String?) {
        // if a song is not in progress, throw the message out
        if (!playing) {
            print("ViewController: Received a message from the bluetooth device, but song was not playing")
            return
        // do nothing until combineMessages confirms that
        // all chunks for the current message have been received
        } else if (combineMessages(string!)) {
            // store the message for its associated beat in hitSequence
            hitSequence[mostRecentBeat] = messageSoFar
            
            waiting = false
            messageSoFar = ""
            
            // if paused, need to start timer and song
            if (paused) {
                // TODO: song skipping happens here
                // set the song player to the time of the current beat, just in case
                songPlayer?.currentTime = secPerBeat * Double(beatCounter)
                songPlayer?.play()
                
                startTimer()
                paused = false
            }
        }
    }
    
    // helper function for nrfReceivedData to concatenate data chunks
    // (bluetooth messages can only contain <= 20B of data);
    // returns true if the message contains the end token
    func combineMessages(msg: String) -> Bool {
        // messages come terminated in a null character ('\0')
        let str = removeTerminatingChar(msg)
        
        if (str == endToken) {
            return true
        } else {
            // concatenate the message with the previous messages
            messageSoFar += str
            return false
        }
    }
    
    // removes a terminating '\0' from string if it exists
    private func removeTerminatingChar(msg: String) -> String {
        let r: Range<String.Index>? = msg.rangeOfString("\0")
        
        if let range = r {
            let foundIndex: Int = msg.startIndex.distanceTo(range.startIndex)
            let cutOffIndex = msg.startIndex.advancedBy(foundIndex)
            return msg.substringToIndex(cutOffIndex)
        } else {
            return msg
        }
    }
    
    // called if the bluetooth device disconnects for whatever reason
    func nrfDidDisconnect(nrfManager: NRFManager) {
        //display a message in the overlay
        let hud = MBProgressHUD.showHUDAddedTo(view, animated: true)
        hud.mode = MBProgressHUDMode.Text
        hud.labelText = "Disconnected from Device"
        hud.hide(true, afterDelay: 1.0)
    }
    
    // called when bluetooth is turned on or off;
    // alerts the user of the change in state
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
    
    // MARK: - TEST METHODS
    // TODO: delete these when no longer necessary
    
    func makeFakeData() {
        sessionData = NSMutableArray()
        makeFakeSession1()
        sessionData.addObject(session)
        makeFakeSession2()
        sessionData.addObject(session)
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
}

