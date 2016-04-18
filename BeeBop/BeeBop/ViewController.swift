//
//  ViewController.swift
//  BeeBop
//
//  Created by Robert Lasell on 4/11/16.
//  Copyright © 2016 Tufts. All rights reserved.
//

import UIKit
import AVFoundation

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var songPickerLabel: UILabel!
    @IBOutlet weak var songPicker: UIPickerView!
    
    var songPlayer: AVAudioPlayer?
    var currentSong: NSURL!
    
    let defaults = NSUserDefaults.standardUserDefaults()

    // song names to choose from
    var pickerSongs: [String] = ["SpongeRon Mingpants", "A Very Ming Chow Christmas", "Ron Ron Ron Your Boat", "I'm Ming and You're Chow", "Do the Ming'n'Ron Dance", "Ron Top of Old Smokey", "You're the Only Ron for Me", "Doo Wop (That Ming)", "The Lasser of Two Evils", "What a Day for a Mobile Medical Device"]
    
    // array of songs corresponding to pickerSongs
    // array would be expanded given more time and resources
    var songs: [NSURL] = [NSURL]()
    // parallel array of base tempos for each song
    var tempos = [120]
    // parallel array of hard-coded sequences of beats (1) and rests(0) for each song
    var beatSequences = [
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
    
    // songs for squares
    // let boringSongs = ["Song1", "Song2", "Song3", "Song4", "Song5", "Song6", "Song7"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initializeDefaults()
        
        let spongebobPath = NSBundle.mainBundle().pathForResource("spongebob", ofType: "mp3")!
        songs = [NSURL.fileURLWithPath(spongebobPath)]

        songPicker.delegate = self
        songPicker.dataSource = self
    }
    
    func initializeDefaults() {
        defaults.setInteger(3, forKey: "speed")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerSongs.count
        //return boringSongs.count
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerSongs[row]
        //return boringSongs[row]
    }
    
    // what happens when you select a new item from the song picker
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
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
    
    // gets called when you press the start/stop button
    @IBAction func buttonPressed (sender : AnyObject) -> Void {
        songPlayer?.play()
    }
}

