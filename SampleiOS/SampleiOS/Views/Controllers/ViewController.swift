//
//  ViewController.swift
//  XyBleSdk
//
//  Created by Darren Sutherland on 09/26/2018.
//  Copyright (c) 2018 Darren Sutherland. All rights reserved.
//

import UIKit
import XyBleSdk
import CoreBluetooth

class ViewController: UIViewController {

    public static let xyGreen = UIColor(red: 0/255, green: 127/255, blue: 109/255, alpha: 1.0)
    public static let detailSegueIdentifier = "detailViewSegue"
    public static let optionsSegueIdentifier = "optionViewSegue"

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var rangedDevicesTableView: UITableView!
    @IBOutlet weak var deviceCountLabel: UILabel!
    @IBOutlet weak var centralStateLabel: UILabel!

    fileprivate let rangedDevicesManager = RangedDevicesManager.instance

    fileprivate var pauseButton: UIBarButtonItem?
    fileprivate var playButton: UIBarButtonItem?

    fileprivate let sectionHeaderHeight: CGFloat = 25

    fileprivate var shouldReload: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupNavBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        rangedDevicesManager.setDelegate(self)
        self.navigationItem.rightBarButtonItem = self.pauseButton
        rangedDevicesManager.startRanging()
    }

    override func viewWillDisappear(_ animated: Bool) {
        rangedDevicesManager.stopRanging()
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier != ViewController.detailSegueIdentifier
    }

}

private extension ViewController {

    @objc func pauseTapped() {
        self.shouldReload = false
        self.rangedDevicesManager.stopRanging()
        self.navigationItem.rightBarButtonItem = self.playButton
    }

    @objc func playTapped() {
        self.shouldReload = true
        self.rangedDevicesManager.startRanging()
        self.navigationItem.rightBarButtonItem = self.pauseButton
    }

    @objc func optionsTapped() {
        self.performSegue(withIdentifier: ViewController.optionsSegueIdentifier, sender: nil)
    }
}

private extension ViewController {
    func setupTable() {
        rangedDevicesTableView.dataSource = self.rangedDevicesManager
        rangedDevicesTableView.delegate = self
        rangedDevicesTableView.register(RangedDeviceTableViewCell.self, forCellReuseIdentifier: "rangedDevicesCell")
        rangedDevicesTableView.rowHeight = UITableView.automaticDimension
        rangedDevicesTableView.estimatedRowHeight = 200.0
    }

    func setupNavBar() {
        self.navigationController?.navigationBar.barStyle = .default
        self.navigationController?.navigationBar.barTintColor = ViewController.xyGreen
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.tintColor = UIColor.white

        let logoContainer = UIView(frame: CGRect(x: 0, y: 0, width: 54.4, height: 28.16))
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 54.4, height: 28.16))
        imageView.contentMode = .scaleAspectFit
        let image = UIImage(named: "WhiteLogo")
        imageView.image = image
        logoContainer.addSubview(imageView)
        navigationItem.titleView = logoContainer

        self.pauseButton = UIBarButtonItem(barButtonSystemItem: .pause, target: self, action: #selector(pauseTapped))
        self.playButton = UIBarButtonItem(barButtonSystemItem: .play, target: self, action: #selector(playTapped))

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Options", style: .plain, target: self, action: #selector(optionsTapped))
    }
}

extension ViewController: RangedDevicesManagerDelegate {
    func buttonPressed(on device: XYBluetoothDevice) {
        self.showBasicAlert(title: "Button Pressed", message: device.id)
    }
    
    func deviceDisconnected(device: XYBluetoothDevice) {
        self.spinner.stopAnimating()
        self.showBasicAlert(title: "Disconnected", message: device.id)
    }
    

    func showDetails() {
        self.spinner.stopAnimating()
        self.performSegue(withIdentifier: ViewController.detailSegueIdentifier, sender: nil)
    }

    func reloadTableView() {
        guard self.shouldReload else { return }
        self.rangedDevicesTableView.reloadData()
        let deviceCount = rangedDevicesManager.rangedDevices.reduce(0, { $0 + $1.value.count })
        self.deviceCountLabel.text = "\(deviceCount)"
    }

    func stateChanged(_ newState: CBManagerState) {
        self.centralStateLabel.text = newState.toString
    }
}

private extension ViewController {

    func showBasicAlert(title: String?, message: String?) {
        guard self.rangedDevicesManager.showAlerts else { return }
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard
            let tableSection = TableSection(rawValue: section),
            let devices = rangedDevicesManager.rangedDevices[tableSection],
            devices.count > 0  else { return 0 }

        return sectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = UIView(frame: CGRect(x: 0, y: 0, width: tableView.bounds.width, height: sectionHeaderHeight))
        view.backgroundColor = ViewController.xyGreen
        let label = UILabel(frame: CGRect(x: 15, y: 0, width: tableView.bounds.width - 30, height: sectionHeaderHeight))
        label.font = UIFont.boldSystemFont(ofSize: 15)
        label.textColor = UIColor.white
        if let tableSection = TableSection(rawValue: section) {
            label.text = tableSection.title
        }
        view.addSubview(label)
        return view
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.rangedDevicesManager.connect(for: TableSection(rawValue: indexPath.section), deviceIndex: indexPath.row)
        self.spinner.startAnimating()
    }

}
