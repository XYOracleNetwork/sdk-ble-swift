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

    @IBOutlet weak var spinner: UIActivityIndicatorView!
    @IBOutlet weak var rangedDevicesTableView: UITableView!
    @IBOutlet weak var deviceCountLabel: UILabel!
    @IBOutlet weak var pulseCount: UILabel!

    fileprivate let rangedDevicesManager =   RangedDevicesManager.instance // MockRangedDevicesManager() //
    // fileprivate let bgTestManager = BackgroundDeviceTestManager()

    fileprivate var pauseButton: UIBarButtonItem?
    fileprivate var playButton: UIBarButtonItem?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupNavBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        rangedDevicesManager.setDelegate(self)
        self.navigationItem.rightBarButtonItem = self.pauseButton
        rangedDevicesManager.startRanging()

//        FirmwareTester.loadFirmware()
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier != ViewController.detailSegueIdentifier
    }

}

private extension ViewController {

    @objc func pauseTapped() {
        self.rangedDevicesManager.stopRanging()
        self.navigationItem.rightBarButtonItem = self.playButton
    }

    @objc func playTapped() {
        self.rangedDevicesManager.startRanging()
        self.navigationItem.rightBarButtonItem = self.pauseButton
    }
}

private extension ViewController {
    func setupTable() {
        rangedDevicesTableView.dataSource = self.rangedDevicesManager
        rangedDevicesTableView.delegate = self
        rangedDevicesTableView.register(RangedDeviceTableViewCell.self, forCellReuseIdentifier: "rangedDevicesCell")
        rangedDevicesTableView.rowHeight = UITableViewAutomaticDimension
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
    }
}

extension ViewController: RangedDevicesManagerDelegate {
    func buttonPressed(on device: XYFinderDevice) {
        let alert = UIAlertController(title: "Button Pressed", message: device.id, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
        self.present(alert, animated: true)
    }

    func showDetails() {
        self.spinner.stopAnimating()
        self.performSegue(withIdentifier: ViewController.detailSegueIdentifier, sender: nil)
    }

    func reloadTableView() {
        self.rangedDevicesTableView.reloadData()
        self.deviceCountLabel.text = "\(rangedDevicesManager.rangedDevices.count)"
        self.pulseCount.text = "\(rangedDevicesManager.rangedDevices.reduce(0, { $0 + $1.totalPulseCount }))"
    }
}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.rangedDevicesManager.scan(for: indexPath.row)
        self.spinner.startAnimating()
    }

}
