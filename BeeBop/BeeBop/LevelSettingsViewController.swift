//
//  LevelSettingsViewController.swift
//  BeeBop
//
//  Created by Rob Lasell on April 25 2016
//  Copyright © 2016 Tufts. All rights reserved.
//
//  View Controller that allows the user to adjust the difficulty
//  level of BeeBop
//

import UIKit


class LevelSettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    let defaults = NSUserDefaults.standardUserDefaults()
    
    // a list of available difficulty levels from 0 to maxLevel
    var pickerData = [Int]()
    var maxLevel = 0
    // the user's chosen difficulty level
    var userLevel = 0
    
    // storyboard outlets
    @IBOutlet weak var levelPicker: UIPickerView!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        maxLevel = defaults.integerForKey(maxLevelKey)
        userLevel = defaults.integerForKey(userLevelKey)
        
        levelPicker.delegate = self
        levelPicker.dataSource = self
        
        levelPicker.selectRow((userLevel - 1), inComponent: 0, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    // MARK: - Picker view data source
    
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // number of available difficulty levels
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return maxLevel
    }
    
    // level number to return for the row that's passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row + 1)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // nothing to do if they select a row except wait for them to hit "Save"
    }

    // saves level to NSUserDefaults when the user presses the save button
    @IBAction func buttonPressed (sender : AnyObject) -> Void {
        userLevel = levelPicker.selectedRowInComponent(0) + 1
        defaults.setInteger(userLevel, forKey: userLevelKey)
    }
}
