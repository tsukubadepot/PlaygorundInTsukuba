//
//  ParkModel.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/25.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import Foundation
import NCMB
import MapKit

class ParkModel {
    /// 公園に関する生データ
    var parks:[ParkInfo] = []
    
    /// お気に入りに入った公園
    var likedParks: [ParkInfo] = []
    
    /// お気に入り公園。objectID の配列
    var liked: [String] {
        get {
            UserDefaults.standard.stringArray(forKey: "liked") ?? []
        }
        
        set {
            UserDefaults.standard.set(newValue, forKey: "liked")
            updateLikedParks()
        }
    }
    
    /// お気に入り情報の更新
    private func updateLikedParks() {
        likedParks = parks.filter { park -> Bool in
            liked.contains(park.objectID)
        }
    }
    
    /// 取得するオブジェクトの上限数
    var fetchLimit: Int = 250
    
    /// NCMB から取得したオブジェクトを配列に追加する
    /// - Parameter array: [NCMBObject]
    private func getParkInformation(objects array: [NCMBObject]) {
        parks.removeAll()
        
        for park in array {
            let parkInfo = ParkInfo()
            
            guard let objectID: String = park["objectId"],
                  let address: String = park["address"],
                  let name: String = park["name"],
                  let createDate: String = park["createDate"],
                  let updateDate: String = park["updateDate"],
                  let topImage: String = park["topImage"],
                  let subImage1: String = park["subImage1"],
                  let subImage2: String = park["subImage2"],
                  let comment: String = park["comment"],
                  let descriptionCommnet: String = park["description"],
                  let parking: Int = park["parking"],
                  let convenience: Int = park["convenience"],
                  let vender: Int = park["vender"],
                  let toilet: Int = park["toilet"],
                  let multipurpose: Int = park["multipurpose"],
                  let playEquipments: [String] = park["facilities"],
                  let coordinate: NCMBGeoPoint = park["coordinate"] else {
                fatalError("Cannot find or cast objects")
            }
            
            parkInfo.objectID = objectID
            parkInfo.name = name
            parkInfo.address = address
            parkInfo.coordinate = CLLocationCoordinate2DMake(coordinate.latitude, coordinate.longitude)
            
            parkInfo.dates.createDate = createDate
            parkInfo.dates.updateDate = updateDate
            
            parkInfo.pictures.topImage = topImage
            parkInfo.pictures.subImage1 = subImage1
            parkInfo.pictures.subImage2 = subImage2
            
            parkInfo.comments.comment = comment
            parkInfo.comments.description = descriptionCommnet
            
            parkInfo.facilities.parking = parking
            parkInfo.facilities.convenience = convenience
            parkInfo.facilities.vender = vender
            parkInfo.facilities.toilet = toilet
            parkInfo.facilities.multipurpose = multipurpose
            
            parkInfo.playEquipments = playEquipments
            
            parks.append(parkInfo)
        }
        
        // TODO: - 一時的な処理
//        parks.sort { (park1, park2) -> Bool in
//            park1.comments.comment < park2.comments.comment
//        }
        
        print("公園数:", parks.count)
        
        // お気に入りを更新する
        updateLikedParks()
    }
    
    /// 公園情報の取得
    func fetchParkInformation(completionHandler: (() -> ())? = nil, errorHandler: ((Error) -> ())? = nil) {
        // クエリの作成
        var query = NCMBQuery.getQuery(className: "Parks")
        
        // フィールド名 address を降順で検索する
        query.order = ["address"]
        // 検索上限数
        // 設定しなければ上限100件になる。
        query.limit = fetchLimit
        
        // 検索
        query.findInBackground { result in
            switch result {
            case let .success(array):
                // 検索に成功した場合の処理
                print("検索に成功しました。")
                
                self.getParkInformation(objects: array)
                
                if let completion = completionHandler {
                    DispatchQueue.main.async {
                        completion()
                    }
                    
                }
                
            case let .failure(error):
                // 検索に失敗した場合の処理
                print("検索に失敗しました。エラーコード：\(error)")
                
                if let completion = errorHandler {
                    DispatchQueue.main.async {
                        completion(error)
                    }
                }
            }
        }
    }
    
    /// 指定された公園のインデックスを返す
    /// - Parameter parkName: 公園名
    /// - Returns: 配列内のインデックス。公園名が存在しないときには nil
    func index(of parkName: String) -> Int? {
        return parks.firstIndex { parkInfo -> Bool in
            return parkInfo.name == parkName
        }
    }
    
    /// インデックスから公園名を得る
    /// - Parameter index: インデックス
    /// - Returns: 公園名。インデックスが範囲外の場合には nil
    func getParkName(of index: Int) -> String? {
        if index < 0 || index >= parks.count {
            return nil
        }
        
        return parks[index].name
    }
}
