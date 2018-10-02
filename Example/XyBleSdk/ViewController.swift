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
    
    fileprivate let rangedDevicesManager = RangedDevicesManager.instance

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTable()
        setupNavBar()
    }

    override func viewDidAppear(_ animated: Bool) {
        rangedDevicesManager.setDelegate(self)
        rangedDevicesManager.startRanging()
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return identifier != ViewController.detailSegueIdentifier
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
    }
}

extension ViewController: RangedDevicesManagerDelegate {
    func showDetails() {
        self.spinner.stopAnimating()
        self.performSegue(withIdentifier: ViewController.detailSegueIdentifier, sender: nil)
    }

    func reloadTableView() {
        self.rangedDevicesTableView.reloadData()
    }
}

extension ViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.rangedDevicesManager.scan(for: indexPath.row)
        self.spinner.startAnimating()
    }

}
