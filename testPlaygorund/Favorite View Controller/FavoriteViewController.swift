//
//  FavoriteViewController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/12/01.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit

class FavoriteViewController: UIViewController {
    @IBOutlet weak var favoriteTableView: UITableView!
    
    var mainTabBarController: MainTabBarController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mainTabBarController = parent as? MainTabBarController
        
        let nib = UINib(nibName: String(describing: ParkTableViewCell.self), bundle: nil)
        favoriteTableView.register(nib, forCellReuseIdentifier: "cell")
        favoriteTableView.dataSource = mainTabBarController
        favoriteTableView.delegate = mainTabBarController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        favoriteTableView.reloadData()
    }
}
