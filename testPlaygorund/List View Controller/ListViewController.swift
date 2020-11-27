//
//  ListViewController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/25.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import PKHUD

class ListViewController: UIViewController {
    @IBOutlet weak var parkListTableView: UITableView!
    
    var mainTabBarController: MainTabBarController?
    var firstLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainTabBarController = parent as? MainTabBarController
        
        let nib = UINib(nibName: String(describing: ParkTableViewCell.self), bundle: nil)
        parkListTableView.register(nib, forCellReuseIdentifier: "cell")
        parkListTableView.dataSource = mainTabBarController
        parkListTableView.delegate = mainTabBarController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !firstLoaded {
            // 初期データの読み込み
            //parkListTableView.refreshControl?.beginRefreshing()
            HUD.show(.labeledProgress(title: "データ読み込み中", subtitle: nil))
            fetchParkData()
            firstLoaded = true
        }
    }
        
    private func fetchParkData() {
        mainTabBarController?.parkModel.fetchParkInformation {
            HUD.hide { _ in
                HUD.flash(.success, delay: 1.0)
            }
            self.parkListTableView.reloadData()
        } errorHandler: { error in
            HUD.hide { _ in
                HUD.flash(.labeledError(title: "ネットワークエラー", subtitle: error.localizedDescription), delay: 5.0)
            }
        }
    }
    
    @IBAction func reloadButton(_ sender: UIBarButtonItem) {
        HUD.show(.labeledProgress(title: "データ読み込み中", subtitle: nil))
        
        fetchParkData()
    }
}
