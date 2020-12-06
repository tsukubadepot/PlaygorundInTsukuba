//
//  SearchViewController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/12/03.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    // MARK: - local properties
    /// Model View Controller
    weak var parkModelController: MainTabBarController!

    /// ヘッダのタイトルとスイッチの状態
    var headerState: [(title: String, isOpen: Bool)] = [("設備で検索する", false), ("遊具で検索する", false)]
    
    /// TableView のセルのラベル名と選択状態
    var facilitiesSection: [(title: Facilites, isOn: Bool)] =
        [(.parking, false), (.toilet, false), (.multipurpose, false), (.convenience, false), (.vender, false)]
    var equipmentSection: [(title: String, isOn: Bool)] =
    //    [("ブランコ", false), ("すべり台", false), ("鉄棒", false), ("砂場", false) ]
        [("FRP遊具", false), ("スプリング遊具", false), ("コンクリート遊具", false), ("木製遊具", false), ("ディッグウッド", false), ("コンビネーション", false), ("ブランコ", false),
         ("すべり台", false), ("コンクリートすべり", false), ("砂場", false), ("シーソー", false), ("回転ハッピー", false), ("うんてい", false), ("鉄棒", false), ("登り棒", false),
         ("トンネル", false), ("キャッスルクレーン", false), ("グローブジャングル", false), ("ジャングルジム", false), ("ロープウェイ", false), ("ネット渡り", false),
         ("ネットクライム", false), ("バスケットゴール", false), ("健康遊具", false), ("広場", false), ("ランニングコース", false), ("遊歩道", false),
         ("テニスコート", false), ("野球場", false)]
    
    // MARK: - UITableView
    @IBOutlet weak var searchTableView: UITableView! {
        didSet {
            searchTableView.dataSource = self
            searchTableView.delegate = self
            
            // 複数行の選択を可能にする
            searchTableView.allowsMultipleSelection = true
        }
    }
    
    // MARK: - 検索実行ボタン
    @IBOutlet weak var showResultButton: UIButton! {
        didSet {
            showResultButton.layer.cornerRadius = showResultButton.frame.height / 2
        }
    }
    
    // MARK: - reset button
    @IBOutlet weak var resetButton: UIButton! {
        didSet {
            resetButton.layer.cornerRadius = resetButton.frame.height / 2
        }
    }
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        // セクションヘッダの登録
        let nib = UINib(nibName: String(describing: SearchHeaderView.self), bundle: nil)
        searchTableView.register(nib, forHeaderFooterViewReuseIdentifier: "Header")
        
        // 検索条件のリストア
        if !parkModelController.parkModel.facilitiesQuery.isEmpty {
            headerState[0].isOpen = true
            parkModelController.parkModel.facilitiesQuery.forEach { title in
                if let index = facilitiesSection.firstIndex(where: { row in
                    row.title == title
                }) {
                    facilitiesSection[index].isOn = true
                }
            }
        }
        
        if !parkModelController.parkModel.playEquipmentsQuery.isEmpty {
            headerState[1].isOpen = true
            
            parkModelController.parkModel.playEquipmentsQuery.forEach { title in
                if let index = equipmentSection.firstIndex(where: { row in
                    row.title == title
                }) {
                    equipmentSection[index].isOn = true
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let count = parkModelController.parkModel.filterdParks.count
        
        showResultButton.setTitle("\(count) 件の結果表示", for: .normal)
        
    }
    
    /// TableView のヘッダにつけたスイッチの状態が変化したときに呼ばれるメソッド
    /// - Parameter sender: sender UI
    @objc func switchChanged(_ sender: UISwitch) {
        if let headerView = sender.superview?.superview as? SearchHeaderView {
            let section = headerView.tag - 1
            
            headerState[section].isOpen.toggle()
            sender.isOn = headerState[section].isOpen
            
            // 検索
            query()
            
            // アニメーション付きで指定したセクションをリロードする
            searchTableView.reloadSections(NSIndexSet(index: section) as IndexSet, with: .automatic)
        }
    }
    
    /// 戻るボタン
    /// - Parameter sender: sender
    @IBAction func backButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func showResultButton(_ sender: UIButton) {
        
        // 呼び出し側が　FavoriteViewController だった場合は
        // tableView をリロードする
        if let callerViewController = parkModelController.viewControllers?[parkModelController.selectedIndex] {
            switch callerViewController {
            case is ListViewController:
                // 一覧表示を更新する
                let vc = callerViewController as! ListViewController
                vc.parkListTableView.reloadData()

            case is MapViewController:
                //
                let vc = callerViewController as! MapViewController
                // 前回のアノテーションを一度削除し、検索条件に応じて再度表示しなおす
                let annotations = vc.annotationMapView.annotations
                vc.annotationMapView.removeAnnotations(annotations)
                vc.annotationMapView.loadAllAnnotations()
                // pagerView の再読み込み
                vc.pagerView.reloadData()

            default:
                fatalError("cannot guess caller View Controller")
            }
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func resetButton(_ sender: UIButton) {
        // let 扱いになるので map では処理できない
        for i in 0..<facilitiesSection.count {
            facilitiesSection[i].isOn = false
        }
        
        for i in 0..<equipmentSection.count {
            equipmentSection[i].isOn = false
        }
        
        //
        parkModelController.parkModel.facilitiesQuery.removeAll()
        parkModelController.parkModel.playEquipmentsQuery.removeAll()
        parkModelController.parkModel.filter()
        
        updateSearchButtonStatus()
        
        searchTableView.reloadData()
    }
    
    func query() {
        parkModelController.parkModel.facilitiesQuery.removeAll()
        parkModelController.parkModel.playEquipmentsQuery.removeAll()
        
        // 設備検索が有効の場合、チェックがついた検索条件を追加する
        if headerState[0].isOpen {
            facilitiesSection.forEach {
                if $0.isOn {
                    parkModelController.parkModel.facilitiesQuery.append($0.title)
                }
            }
        }

        // 遊具検索が有効の場合、チェックがついた検索条件を追加する
        if headerState[1].isOpen {
            equipmentSection.forEach {
                if $0.isOn {
                    parkModelController.parkModel.playEquipmentsQuery.append($0.title)
                }
            }
        }

        parkModelController.parkModel.filter()
        
        updateSearchButtonStatus()
    }
    
    private func updateSearchButtonStatus() {
        let count = parkModelController.parkModel.filterdParks.count
        showResultButton.setTitle("\(count) 件の結果表示", for: .normal)
        
        if count == 0 {
            showResultButton.isEnabled = false
        } else {
            showResultButton.isEnabled = true
        }
    }
    
}

extension SearchViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return headerState[section].isOpen ? (section == 0 ? facilitiesSection.count : equipmentSection.count) : 0
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        switch indexPath.section {
        case 0:
            let selectedItem = facilitiesSection[indexPath.row]
            cell.textLabel?.text = selectedItem.title.description
            cell.accessoryType = selectedItem.isOn ? .checkmark : .none
        case 1:
            let selectedItem = equipmentSection[indexPath.row]
            cell.textLabel?.text = selectedItem.title
            cell.accessoryType = selectedItem.isOn ? .checkmark : .none
        default:
            fatalError()
        }
            
        // 選択時に反転させないようにする
        cell.selectionStyle = .none
        
        return cell
    }

}

extension SearchViewController: UITableViewDelegate {
    /// セクション数
    func numberOfSections(in tableView: UITableView) -> Int {
        return headerState.count
    }

    /// セクションヘッダ
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableHeaderFooterView(withIdentifier: "Header") as? SearchHeaderView else {
            return UIView()
        }
        
        cell.headerTitleView.text = headerState[section].title
        cell.tag = section + 1
        cell.headerSwitch.isOn = headerState[section].isOpen
        
        cell.headerSwitch.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        
        return cell
    }
    
    /// セクションヘッダの高さ
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 50
    }
    
    /// セルが選択された時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .checkmark
            
            switch indexPath.section {
            case 0:
                facilitiesSection[indexPath.row].isOn = true
            case 1:
                equipmentSection[indexPath.row].isOn = true
            default:
                fatalError()
            }
            
            //
            query()
        }
    }
    
    /// セルの選択が解除された時の処理
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.accessoryType = .none
            
            switch indexPath.section {
            case 0:
                facilitiesSection[indexPath.row].isOn = false
            case 1:
                equipmentSection[indexPath.row].isOn = false
            default:
                fatalError()
            }
            
            //
            query()
        }
    }
}


