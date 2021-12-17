//
//  MainTabBarController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/25.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import NCMB
//import Kingfisher
import AlamofireImage
import MapKit
import FSPagerView

class MainTabBarController: UITabBarController {
    var parkModel = ParkModel()
    
    var coordinateModel = Coordinate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // NCMB の初期化
        NCMB.initialize(applicationKey: applicationkey, clientKey: clientkey)
        
        // 匿名ログイン
        login()
        
        coordinateModel.setupLocationManager()
    }
    
    private func login() {
        // UUID取得
        guard let uuid = UIDevice.current.identifierForVendor?.uuidString else {
            abort()
        }
        
        print("uuid:\(uuid)")

        // 匿名ログイン
        NCMBUser.logInInBackground(userName: uuid, password: uuid) { result in
            // 1. すでに登録してある場合には、最終ログイン日とログイン回数を更新する
            // 2. 未登録の場合には、最終ログイン日とログイン回数を初期化して登録する
            switch result {
            case .success:
                // すでに登録してある場合
                print("ログインに成功しました")
                
                // 最終ログイン日時取得
                let user = NCMBUser.currentUser!
                let lastLoginDate: String = user["updateDate"]!
                let count: Int = user["count"]!
                
                // ログイン日時の上書き
                user["lastLoginDate"] = lastLoginDate
                user["count"] = count + 1
                
                user.saveInBackground { updateResult in
                    switch updateResult {
                    case .success:
                        // 保存成功時の処理
                        print("最終ログイン日時の保存に成功しました。")
                        break
                    case let .failure(update_error):
                        // 保存失敗時の処理
                        print("最終ログイン日時の保存に失敗しました。エラーコード：\(update_error)")
                    }
                    
                }

            case let .failure(login_error):
                // ログイン失敗時の処理
                print("ログインに失敗しました。エラーコード：\(login_error)")
                // 初回利用（会員未登録）の場合
                if (login_error as? NCMBApiError)?.errorCode == .authenticationErrorWithIdPassIncorrect { // 401002：ID/Pass認証エラー
                    let newUser = NCMBUser()
                    newUser.userName = uuid
                    newUser.password = uuid
                    
                    newUser.signUpInBackground {signupResult in
                        switch signupResult {
                        case .success:
                            // 会員登録成功時の処理
                            print("会員登録に成功しました。")
                            
                            /* mBaaSデータの保存 */
                            let lastLoginDate = newUser["createDate"]! as Any
                            
                            // 最終ログイン日
                            newUser["lastLoginDate"] = lastLoginDate
                            // ログイン回数
                            newUser["count"] = 1
                            
                            newUser.saveInBackground(callback: { newUpdateResult in
                                switch newUpdateResult {
                                case .success:
                                    // 保存成功時の処理
                                    print("最終ログイン日時の保存に成功しました。")
                                    break
                                case let .failure(newUpdate_error):
                                    // 保存失敗時の処理
                                    print("最終ログイン日時の保存に失敗しました。エラーコード：\(newUpdate_error)")
                                }
                            })
                        case let .failure(signup_error):
                            // 会員登録失敗時の処理
                            print("会員登録に失敗しました。エラーコード：\(signup_error)")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - UITableViewDataSource
extension MainTabBarController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch self.selectedIndex {
        case 0:
            return parkModel.filterdParks.count
            
        case 2:
            return parkModel.likedParks.count == 0 ? 1 : parkModel.likedParks.count
            
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // お気に入り登録がない場合は、「登録促進セル」を表示して終了
        if self.selectedIndex == 2 && parkModel.likedParks.count == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "FavoriteCell", for: indexPath)
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ParkTableViewCell
        
        var park: ParkInfo!
        
        switch self.selectedIndex {
        case 0:
            park = parkModel.filterdParks[indexPath.row]
            
        case 2:
            park = parkModel.likedParks[indexPath.row]
            
        default:
            return UITableViewCell()
            //fatalError("TabBarController のインデックスが不明")
        }
        
        cell.imageThumbnailView.loadImage(forName: park.pictures.topImage)
        
        cell.parknameLabel.text = park.name
        cell.addressLabel.text = park.address
        cell.commentLabel.text = park.comments.comment
        
        switch park.playEquipments.count {
        case 0:
            // 遊具なし
            cell.equipmentCountLabel.text = "遊具なし"
        case 1:
            // 遊具1つ
            cell.equipmentCountLabel.text =  park.playEquipments.first!
        default:
            // 2つ以上
            cell.equipmentCountLabel.text = park.playEquipments.randomElement()! + "ほか" + String(park.playEquipments.count - 1) + "個"
        }
        
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MainTabBarController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // お気に入りがない場合はここで終了
        if self.selectedIndex == 2 && parkModel.likedParks.count == 0  {
            return
        }
        
        let vc = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
  
        switch self.selectedIndex {
        case 0:
            vc.park = parkModel.filterdParks[indexPath.row]
            
        case 2:
            vc.park = parkModel.parks.filter { park -> Bool in
                parkModel.liked.contains(park.objectID)
            }[indexPath.row]
            
        default:
            fatalError("TabBarController のインデックスが不明")
        }
        
        vc.parkModelController = self
        
        vc.modalTransitionStyle = .crossDissolve
        vc.modalPresentationStyle = .overFullScreen
        
        present(vc, animated: true, completion: nil)
    }
}

// MARK: - AnnotationMapViewDataSource
extension MainTabBarController: AnnotationMapViewDataSource {
    func numberOfAnnotations(in mapView: AnnotationMapView) -> Int {
        if let _ = mapView.callerView as? DetailViewController {
            // 詳細画面から呼び出した場合は全てのアノテーションを表示させる
            return parkModel.parks.count
        } else {
            return parkModel.filterdParks.count
        }
    }
    
    func annotationMapView(_ mapView: AnnotationMapView, annotationFor: Int) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        let park: ParkInfo
            
        if let _ = mapView.callerView as? DetailViewController {
            // 詳細画面から呼び出した場合は全てのアノテーションを表示させる
            park = parkModel.parks[annotationFor]
        } else {
            park = parkModel.filterdParks[annotationFor]
        }
        
        let lat = park.coordinate.latitude
        let lon = park.coordinate.longitude
        
        let coordinate = CLLocationCoordinate2DMake(lat, lon)
        annotation.coordinate = coordinate
        annotation.title = park.name
        annotation.subtitle = park.comments.comment
        
        return annotation
    }
    
    func firstIndex(_ mapView: AnnotationMapView, ofName name: String) -> Int? {
        if let _ = mapView.callerView as? DetailViewController {
            // 詳細画面から呼び出した場合は全てのアノテーションを表示させる
            return parkModel.parks.firstIndex { park -> Bool in
                park.name == name
            }
        } else {
            return parkModel.filterdParks.firstIndex { park -> Bool in
                park.name == name
            }
        }
    }
}

// MARK: - FSPagerViewDataSource
extension MainTabBarController: FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return parkModel.filterdParks.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        let park = parkModel.filterdParks[index]
                
        guard let imageView = cell.imageView else {
            fatalError("cannot dequeue pagerView")
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        imageView.loadImage(forName: park.pictures.topImage)

        // 公園名
        // textLabel は最後に設定しないと ImageView の後ろになる
        cell.textLabel?.text = park.name

        return cell
    }
}
