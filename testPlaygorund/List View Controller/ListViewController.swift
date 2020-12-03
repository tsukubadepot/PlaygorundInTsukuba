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
    
    // MARK: - local properties
    /// parkModel を持っているコントローラのインスタンス
    weak var parkModelController: MainTabBarController?
    
    var firstLoaded = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        parkModelController = parent as? MainTabBarController
        
        let nib = UINib(nibName: String(describing: ParkTableViewCell.self), bundle: nil)
        parkListTableView.register(nib, forCellReuseIdentifier: "cell")
        parkListTableView.dataSource = parkModelController
        parkListTableView.delegate = parkModelController
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // TODO: この位置だと、DataSource で正しいインデックス番号が取得できない
        // viewDidAppear(_:) に移動させる
        //parkListTableView.reloadData()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if !firstLoaded {
            // 初期データの読み込み
            //parkListTableView.refreshControl?.beginRefreshing()
            HUD.show(.labeledProgress(title: "データ読み込み中", subtitle: nil))
            fetchParkData()
            firstLoaded = true
        } else {
            parkListTableView.reloadData()
        }
    }
        
    private func fetchParkData() {
        parkModelController?.parkModel.fetchParkInformation {
            HUD.hide { _ in
                HUD.flash(.success, delay: 1.0)
            }

            // 検索条件に従って検索を実行
            self.parkModelController?.parkModel.filter()

            self.parkListTableView.reloadData()
        } errorHandler: { error in
            HUD.hide { _ in
                HUD.flash(.labeledError(title: "ネットワークエラー", subtitle: error.localizedDescription), delay: 5.0)
            }
        }
    }
    
    @IBAction func searchButton(_ sender: UIBarButtonItem) {
        if let vc = storyboard?.instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController {
            vc.parkModelController = parkModelController
            
            present(vc, animated: true, completion: nil)
        }
    }
    
    @IBAction func reloadButton(_ sender: UIBarButtonItem) {
        HUD.show(.labeledProgress(title: "データ読み込み中", subtitle: nil))
        
        // TODO: - リロード時、検索条件をクリアするかどうかは検討が必要
        
        fetchParkData()
    }
}
