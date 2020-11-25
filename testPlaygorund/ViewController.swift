//
//  ViewController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/02/12.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import GoogleMobileAds
import PKHUD
import CoreLocation

struct PlayGround {
    // 公園名
    var name: String
    // 住所
    var address: String
    // 設備
    var facility: String
    // 設備の数
    var facilityCount: Int
    // 緯度・経度
    var lat: Double
    var lon: Double
    // 緯度・経度(参考)
    var latRef: Double
    var lonRef: Double
    
    // イニシャライザは省略
    
    // 指定した緯度経度から、指定した範囲(km)以内に公園があるか
    func isInsideLocation(lat: Double, lon: Double, range: Double) -> Bool {
        // 極半径
        let pole_radius = 6356.752314
        // 赤道半径
        let equator_radius = 6378.137
        
        // 1km　あたりの経度・経度
        let d_lat = 360.0 / ( 2.0 * Double.pi * pole_radius)
        let d_lon = 360.0 / ( 2.0 * Double.pi * equator_radius * cos((lat * Double.pi) / 180))
        
        // 指定したレンジでの緯度・経度
        let lat_range = d_lat * range
        let lon_range = d_lon * range
        
        // 目的地と公園情報の緯度経度の差分がレンジの範囲内か否か
        return (fabs(self.lat - lat) <= lat_range) && (fabs(self.lon - lon) <= lon_range)
    }
}

class ViewController: UIViewController, UISearchBarDelegate, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate {
    // 検索ボタン
    @IBOutlet weak var querySearch: UISearchBar!
    // セルの項目
    @IBOutlet weak var playgroundTableView: UITableView!
    // バナー
    @IBOutlet weak var bannerView: GADBannerView!
    // 検索範囲のラベル
    @IBOutlet weak var searchAreaLabel: UILabel!
    
    // 公園情報構造体の配列
    var playGroundOrig: [PlayGround]!
    var playGround = [PlayGround]()
    
    // 拡大表示率
    enum selectedZoomIndex: Int { case inside1km = 0, inside2km, inside4km, inside8km, wholeArea }
    var selectedZoomFactor: selectedZoomIndex = .wholeArea
    var selectedZoomText = ["半径1km以内",
                            "半径2km以内",
                            "半径4km以内",
                            "半径8km以内",
                            "つくば市内全域",
    ]
    
    // ロケーションマネージャ
    var locationManager: CLLocationManager!
    
    // 現在位置 -> つくば駅
    var currentLatitude = 36.0827 //36.087268509758374
    var currentLongitude = 140.1116 //140.09530876581513
    
    // https://qiita.com/motokiee/items/0ca628b4cc74c8c5599d
    // ビューの準備が整い、スクリーン上に表示された時に呼ばれる。
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        // 他のビューから遷移した時も実行される
        
        // ここで公園データを呼び出してみる
        // データのダウンロード
        // PKHUD は表示されるまでに時間遅れがあるので、ネットワーク状態がよければ表示されない
        HUD.flash(.progress)
        
        do {
            playGroundOrig = try downloadPlaygroundData()
            playGround = playGroundOrig
            
            // 新検索関数
            searchPlayground(name: querySearch.text, showAlert: false)
            
            HUD.hide()
        } catch {
            // TODO: とりあえずエラーで分類しない
            // 以前の HUD を消す
            HUD.hide()

            //アラートを出す
            let alertController = UIAlertController(title: "ダウンロード失敗",
                                                    message: "時間をおいてアプリを再起動してください。",
                                                    preferredStyle: .alert)
            let okAction = UIAlertAction(title: "確認", style: .destructive, handler: nil)
            alertController.addAction(okAction)
            
            // iPad 対策
            alertController.popoverPresentationController?.sourceView = view
            
            present(alertController, animated: true, completion: nil)
        }
        
        //
        playgroundTableView.reloadData()
    }
    
    // ビューが消えたとき
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
    }
    
    // viewがロードされた後に呼び出される。
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Search Bar の Delegate 通知先を設定
        querySearch.delegate = self
        
        // プレースホルダーの設定
        querySearch.placeholder = "公園名、遊具名、住所で検索"
        
        // 検索範囲の表示
        searchAreaLabel.text = "検索範囲：" + selectedZoomText[selectedZoomFactor.rawValue]
        
        // table view の data source, delegate を設定
        playgroundTableView.dataSource = self
        playgroundTableView.delegate = self
        
        // AdMob
        bannerView.adUnitID = adUnitID
        bannerView.rootViewController = self
        bannerView.load(GADRequest())
//        // デバッグ用
//        GADMobileAds.sharedInstance().requestConfiguration.testDeviceIdentifiers = testDeviceIdentifiers
        
        // データのダウンロード -> viewDidAppear() でダウンロードする
        
        // ロケーションマネージャのセットアップ
        // Info.plist のプライバシーの項目に　Privacy - Location When In Use Usage Description　追加
        setupLocationManager()
        
        // tableView を更新
        playgroundTableView.reloadData()
    }
    
    /// ロケーションマネージャのセットアップ
    // CLLocationManagerDelegate プロトコルを追加
    func setupLocationManager() {
        locationManager = CLLocationManager()
        
        // 権限をリクエスト
        guard let locationManager = locationManager else { return }
        locationManager.requestWhenInUseAuthorization()
        
        // マネージャの設定
        let status = CLLocationManager.authorizationStatus()
        
        // ステータスごとの処理
        if status == .authorizedWhenInUse {
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
        }
    }
    
    // 位置情報が更新された際、位置情報を格納する delegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.first
        let latitude = location?.coordinate.latitude
        let longitude = location?.coordinate.longitude
        // 位置情報を格納する
        // Unwrapper value なので、nil の時はつくば駅を中心とする
        currentLongitude = longitude ?? 140.1116
        currentLatitude = latitude ?? 36.0827
    }
     
    // 検索範囲の設定
    @IBAction func setZoonButton(_ sender: Any) {
        // マネージャの設定
        let status = CLLocationManager.authorizationStatus()
        print("setZoom")
        dump(status)
        if status == .denied {
            let alertTitle = "位置情報取得が許可されていません。"
            let alertMessage = "現在地近辺の公園を検索するためには、設定から「プライバシー > 位置情報サービス」を選び、位置情報取得を許可してください。"
            let alert: UIAlertController = UIAlertController(
                title: alertTitle,
                message: alertMessage,
                preferredStyle:  UIAlertController.Style.alert
            )
            // OKボタン
            let defaultAction: UIAlertAction = UIAlertAction(
                title: "OK",
                style: UIAlertAction.Style.default,
                handler: nil
            )
            // UIAlertController に Action を追加
            alert.addAction(defaultAction)
            // Alertを表示
            present(alert, animated: true, completion: nil)
        } else if status == .authorizedWhenInUse {
            let alertController = UIAlertController(title: "検索範囲の指定",
                                                    message: "現在地を中心とした検索範囲を指定できます",
                                                    preferredStyle: .actionSheet)
            
            let zoonOneAction = UIAlertAction(title: selectedZoomText[selectedZoomIndex.inside1km.rawValue],
                                              style: .default) { _ in self.updateZoomFactor(.inside1km) }
            alertController.addAction(zoonOneAction)
            let zoonTwoAction = UIAlertAction(title: selectedZoomText[selectedZoomIndex.inside2km.rawValue],
                                              style: .default) { _ in self.updateZoomFactor(.inside2km) }
            alertController.addAction(zoonTwoAction)
            let zoonThreeAction = UIAlertAction(title: selectedZoomText[selectedZoomIndex.inside4km.rawValue],
                                                style: .default) { _ in self.updateZoomFactor(.inside4km) }
            alertController.addAction(zoonThreeAction)
            let zoonFourAction = UIAlertAction(title: selectedZoomText[selectedZoomIndex.inside8km.rawValue],
                                               style: .default) { _ in self.updateZoomFactor(.inside8km) }
            alertController.addAction(zoonFourAction)
            let zoonFiveAction = UIAlertAction(title: selectedZoomText[selectedZoomIndex.wholeArea.rawValue],
                                               style: .default) { _ in self.updateZoomFactor(.wholeArea) }
            alertController.addAction(zoonFiveAction)
            
            let cancelAction = UIAlertAction(title: "キャンセル", style: .cancel, handler: nil)
            alertController.addAction(cancelAction)
            
            // iPad 対策
            alertController.popoverPresentationController?.sourceView = view
            
            // present() はブロックしない。
            present(alertController, animated: true, completion: nil)
        }
    }
    
    // クロージャ内部の処理用
    // 検索範囲での絞り込みもここで行う
    func updateZoomFactor(_ factor: selectedZoomIndex) {
        selectedZoomFactor = factor
        searchAreaLabel.text = "検索範囲：" + selectedZoomText[selectedZoomFactor.rawValue]
        
        // 新検索関数
        searchPlayground(name: querySearch.text, showAlert: true)
        
        // tableView を更新
        playgroundTableView.reloadData()
    }
    
    // 検索ボタンをタップしたときの動作 (delegate)
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        // キーボードを閉じる
        view.endEditing(true)
        
        // 新検索関数
        searchPlayground(name: querySearch.text, showAlert: true)
        
        // tableView を更新
        playgroundTableView.reloadData()
    }
    
    // キャンセルボタンを押したときの処理(delegate)
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        // キーボードを閉じる
        view.endEditing(true)
        
        // 表示する言葉は統一する
        querySearch.text = "" // 空文字に設定しないとプレースホルダーが表示されない
        querySearch.placeholder = "公園名、遊具名、住所で検索"
        
        // 再検索
        searchPlayground(name: querySearch.text, showAlert: true)
        
        // tableView を更新
        playgroundTableView.reloadData()
    }
    
    // サーチバー以外の部分をクリックしたらキーボードを閉じる -> 消えない
    // Table View 内部であれば、カスタムクラスを作り、その中でも override する必要がある
    //    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    //        print("chain to the next responder")
    //        // touchesBeganを次のResponderへ
    //        self.next?.touchesBegan(touches, with: event)
    //    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        return true
    }
    
    // table view の data source
    // セルの総数を返す
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return playGround.count
    }
    
    // セルに値を設定する
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // 表示を行う Cell オブジェクト（一行）を得る
        let cell = playgroundTableView.dequeueReusableCell(withIdentifier: "playgroundCell", for: indexPath)
        // 公園名を表示する
        cell.textLabel?.text = playGround[indexPath.row].name + "（遊具数: \(playGround[indexPath.row].facilityCount)）"
        
        // 住所を表示する
        cell.detailTextLabel?.text = playGround[indexPath.row].address
        
        // 設定済みのオブジェクトを返す
        return cell
    }
    
    // とりあえず
    //var selectedPlayground: PlayGround?
    
    // セルが選択されたときに呼び出される delegate メソッド
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // ここにもキーボードを消す操作を入れておかないと、きちんとキーボードが消えない
        view.endEditing(true)
        
        // ハイライト解除
        playgroundTableView.deselectRow(at: indexPath, animated: true)
        
        // 選ばれている公園情報
        // TODO: 直接呼び出し先のクラスにアクセスできないので、いったん別のプロパティに保存する
        // 渡せないのはindexpath.row
        //        playgroundTableView.indexPathForSelected.row
        //selectedPlayground = playGround[indexPath.row]
        
        // 公園情報の詳細を表示するビューコントローラのインスタンスを得る
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: "PlayGroundDetailView") as! PlaygroundDetailViewController
        vc.playGroundInfo = playGround[indexPath.row]
        vc.currentLatitude = currentLatitude
        vc.currentLongitude = currentLongitude
        // 次のビューコントローラを呼び出す
        navigationController?.pushViewController(vc, animated: true)
        // Storyboard でSegueを設定して、それを呼び出す
        // performSegueを使う場合には上記の手法は使えないので、prepare()で値渡しの処理をする
        // performSegue(withIdentifier: "test", sender: nil)
    }
    
    // segueが実行される時に呼び出される
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: segue の identifier ごとに処理を分ける
//        if let nextViewController = segue.destination as? PlaygroundDetailViewController {
//            nextViewController.playGroundInfo = selectedPlayground
//            nextViewController.currentLatitude = currentLatitude
//            nextViewController.currentLongitude = currentLongitude
//        }
    }
    
    // 公園データベース操作関連関数
    func searchPlayground(name: String?, showAlert: Bool) {
        // 検索でフィルタリング後の公園情報
        let playGroundFilterd: [PlayGround]!
        let playGroundFilterdArea: [PlayGround]!
        
        // まずはエリアサーチ
        if selectedZoomFactor == .wholeArea {
            // 市内全域の場合はすべての情報を使う
            playGroundFilterdArea = playGroundOrig
        } else {
            // 現在地周辺の公園を検索する
            playGroundFilterdArea = playGroundOrig.filter {
                $0.isInsideLocation(lat: currentLatitude, lon: currentLongitude, range: pow(2.0, Double(selectedZoomFactor.rawValue)))
            }
        }
        
        // 次に全文検索
        if let searchText = name, searchText.isEmpty == false {
            // 全角と半角で区切る
            let searchWords = searchText.components(separatedBy: CharacterSet(charactersIn: "　 "))
            
            // 検索条件を入れる
            // https://qiita.com/masa-321/items/076c5519e2c0f643956e
            // $0にはconditions:[(PlayGround) -> Bool]のelement、すなわちPlayGround型のelementが入る
            var conditions = [(PlayGround) -> Bool]()
            for w in searchWords {
                // 空白を除いた後検索条件を追加する
                let word = w.remove(characterSet: .whitespaces)
                
                if word != "" {
                    conditions.append { $0.name.contains(word) || $0.address.contains(word) || $0.facility.contains(word) }
                }
            }
            
            // $0には初めtrueが初期値として設定されています。$1にはconditionsの戻り値の要素（Bool値）が順々に入っていくことになります。
            // conditionsにはsearchWords.countの数だけBool値があり、それがreduceによって畳み込まれます。
            // つまり、全てtrueならtrueとなりfilterを通過し、1つでもfalseならfalseとなり弾かれます。
            playGroundFilterd = playGroundFilterdArea.filter { article in
                conditions.reduce(true) { $0 && $1(article) }
            }
        } else {
            // 検索テキストが nil もしくは "" の場合
            playGroundFilterd = playGroundFilterdArea
        }
        
        
        if playGroundFilterd.isEmpty == true {
            // 検索結果ゼロ
            playGround.removeAll()
            
            if showAlert {
                // 検索結果がなかった場合にはアラートを出す
                let alertController = UIAlertController(title: "検索失敗",
                                                        message: "条件に一致する公園は見つかりませんでした。",
                                                        preferredStyle: .alert)
                let defaultAction = UIAlertAction(title: "戻る", style: .default, handler: nil)
                alertController.addAction(defaultAction)
                present(alertController, animated: true, completion: nil)
            }
        } else {
            // 検索完了
            playGround = playGroundFilterd
            
            if showAlert {
                let alertController = UIAlertController(title: "検索完了",
                                                        message: "条件に一致する公園は\(playGround.count)ヶ所ありました。",
                    preferredStyle: .alert)
                // クロージャで公園情報をセットする
                let defaultAction = UIAlertAction(title: "戻る", style: .default, handler: nil)
                
                alertController.addAction(defaultAction)
                present(alertController, animated: true, completion: nil)
            }
        }
    }
}

