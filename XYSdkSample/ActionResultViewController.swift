//
//  ActionResultViewController.swift
//  XYSdkSample
//
//  Created by Darren Sutherland on 9/19/18.
//  Copyright © 2018 Darren Sutherland. All rights reserved.
//

import UIKit

class ActionResultViewController: UIViewController {

    @IBOutlet weak var resultsTableView: UITableView!

    fileprivate var results = [XYBluetoothValue]()

    override func viewDidLoad() {
        super.viewDidLoad()

        resultsTableView.dataSource = self
        resultsTableView.delegate = self

        resultsTableView.register(UINib(nibName: "ActionResultTableViewCell", bundle: nil), forCellReuseIdentifier: "actionResultCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        resultsTableView.reloadData()
    }

    @IBAction func closeTapped(_ sender: Any) {
        self.dismiss(animated: true) {
            self.results.removeAll()
            self.resultsTableView.reloadData()
        }
    }

    func set(results: [XYBluetoothValue?]) {
        self.results = results.compactMap { $0 }
    }

    func convertValueToString(_ value: XYBluetoothValue) -> String {
        var result: String
        switch value.type {
        case .string: result = value.asString ?? "?"
        case .integer: result = "\(value.asInteger ?? 0)"
        default: result = "?"
        }

        return result
    }

}

extension ActionResultViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return results.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "actionResultCell") as! ActionResultTableViewCell

        let value = results[indexPath.row]
        cell.set(value.serviceCharacteristic.characteristicUuid.uuidString, value: convertValueToString(value))

        return cell
    }
}

extension ActionResultViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

    }

}
