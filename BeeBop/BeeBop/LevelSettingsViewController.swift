//
//  LevelSettingsViewController.swift
//  BeeBop
//
//  Created by Robert Lasell on 4/25/16.
//  Copyright © 2016 Tufts. All rights reserved.
//

import UIKit

class LevelSettingsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {

    let defaults = NSUserDefaults.standardUserDefaults()
    
    @IBOutlet weak var levelPicker: UIPickerView!
    var pickerData = [Int]()
    var maxLevel = 0
    var userLevel = 0
    
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
    
    // The number of columns of data
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    
    // The number of rows of data
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return maxLevel
    }
    
    // The data to return for the row and component (column) that's being passed in
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return String(row + 1)
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // Nothing to do if they select a row except wait for them to hit "Save"
    }

    // gets called when you press the save button
    @IBAction func buttonPressed (sender : AnyObject) -> Void {
        userLevel = levelPicker.selectedRowInComponent(0) + 1
        defaults.setInteger(userLevel, forKey: userLevelKey)
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
