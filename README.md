# BeeBop
### Overview

BeeBop is a combination iOS app and physical device designed to help improve living conditions for children with hemiplegia, a neurological disorder. It was designed and built in the spring of 2016 by Ari Scourtas, Ferdinand Dowouo, Jake Hellman, Katia Kravchenko, Rob Lasell, Trish O'Connor for Ming Chow and Ron Lasser's Mobile Medical Devices class at Tufts University.

### Implementation Details

The iOS side of the project has three main modes: playing the game, choosing settings, and viewing the game data.

1. Playing the game

   On the main page, the user chooses a song from a list that we provide, and plays the song. Behind the scenes, when the user is playing a song, the app counts beats alongside the actual music, and follows along with a sequence of hits that we have hard-coded into the app beforehand. Whenever the user is supposed to hit a drum, the app sends a signal to the drums with a single integer indicating which drum to hit (the app chooses a random drum from the list of currently active drums).

   The drum peripheral then illuminates the LEDs around that drum, and when the user hits the drum, sends a signal back to the app containing information about the correct and incorrect drums hit for that beat, along with information about the reaction time and hit force of the user. This is encoded in a protocol of our own invention, which goes like this: Incorrect Drums, Correct Drum, Reaction Time (ms), Hit Force. For example, "0 1 3 1 2 1450 320.00" indicates that the user was meant to hit drum 2, but they first hit drums 0, 1, 3, and 1 in that order. When they did hit drum 2, 1.45 seconds had elapsed, and they hit the drum with a force of 320 (there are no units for hit force, as it is a relative value). Note that only one drum (0) currently has an accelerometer, so the other drums' messages end in a "-1.00" for hit force.

   Meanwhile, the app enters a waiting state while it continues to play through the song and wait for a message from the bluetooth device. If it reaches another beat without receiving a message, the song playback stops until a message is received.

   Finally, when the song has finished running, the data from the session (session meaning the playing of one song) is written to a .plist file in the iOS device's memory so that the user can view their previous sessions at a later time. The .plist file contains an array of sessions in chronological order, with each session represented by a dictionary containing the session's:

      * tempo
      * song name
      * challenge level
      * date
      * active drums
      * beat sequence
      * hit sequence (i.e. the user's hit data in the form of the messages received from the bluetooth device)

2. Choosing settings

   The settings part of the app is relatively uncomplicated; the user can use the various settings pages to set the values stored in NSUserDefaults for:

      * which drums are active
      * the challenge level
      * the connected bluetooth device

   The first two are straightforward, and the bluetooth scanner simply uses methods from the NRFManager class to scan for available devices and connect to one (or disconnect) when directed by the user. It may be noteworthy that the scanner times out after 10 seconds of searching for devices or attempting to connect.

3. Viewing the data

   The user can view aggregate data from previous sessions (pulled from the stored .plist file) on the data page. Currently, they can view graphs of average values for relative hit force, reaction time, and percentage of correct drum hits. The data can be viewed for the most recent week, month, or year. Currently, all data in this section except for the most recent week is example data, not pulled from the real .plist file. We wanted to demonstrate the capability to pull real data and display it, but the time commitment to create weeks and months worth of real data would have been prohibitive. Similarly, the pages that display data for individual sessions are currently simple dummy pages, as we decided to focus on finalizing the pages we had already implemented.

### Files

This is a description of the main files associated with the iOS app, provided to ease perusal of the project.

   * ViewController.swift

      This is the view controller for the main page, where users can choose a song to play and play that song. This file primarily contains code relating to what we call the "drum logic" (that is, tracking the tempo and beat to send messages to and from the drum peripheral) and the storage and loading of long-term data in a plist file.

      - SettingsTableViewController.swift

         This is the view controller for the 

### Notes and Issues

We have been having some issues with storyboards when pulling from GitHub - if elements are not displaying on the storyboard, try changing the width and height at the bottom of the page to Compact and Regular, respectively.