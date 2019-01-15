//
//  OptionsViewController.swift
//  XyBleSdk_Example
//
//  Created by Darren Sutherland on 12/3/18.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit
import XyBleSdk

class OptionsViewController: UIViewController {

    fileprivate let manager = RangedDevicesManager.instance

    @IBOutlet weak var rssiValueLabel: UILabel!
    @IBOutlet weak var rssiSlider: UISlider!
    @IBOutlet weak var xyFamilyFilterTableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupTable()
    }

    @IBAction func rssSliderChanged(_ sender: UISlider) {
        var value = Int(sender.value)
        if value == -201 { value = 0 }
        self.manager.rssiRangeToDisplay = value
        rssiValueLabel.text = value < 0 ? "\(value)" : "All"
    }

    override func viewWillAppear(_ animated: Bool) {
        let sliderValue = self.manager.rssiRangeToDisplay
        self.rssiValueLabel.text = sliderValue < 0 ? "\(sliderValue)" : "All"
        self.rssiSlider.value = Float(sliderValue)
    }

}

private extension OptionsViewController {

    func setupTable() {
        xyFamilyFilterTableView.dataSource = self
        xyFamilyFilterTableView.delegate = self
    }

}

extension OptionsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let family = XYFinderDeviceFamily.valuesToRange[indexPath.row]
        self.manager.toggleFamilyFilter(for: family)
        self.xyFamilyFilterTableView.reloadData()
    }

}

extension OptionsViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return XYFinderDeviceFamily.valuesToRange.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "xyFinderFamilyFilterCell")!
        let family = XYFinderDeviceFamily.valuesToRange[indexPath.row]
        cell.textLabel?.text = family.familyName
        cell.accessoryType = manager.xyFinderFamilyFilter.contains(family) ? .checkmark : .none
        return cell
    }

}
