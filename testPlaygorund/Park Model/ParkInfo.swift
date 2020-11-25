//
//  ParkInfo.swift
//  ParkInformationChecker
//
//  Created by Jun Yamashita on 2020/11/05.
//

import Foundation
import NCMB
import MapKit

/// DB の作成・更新日時
class Dates {
    /// レコード作成日
    var createDate = ""
    /// レコード更新日
    var updateDate = ""
}

/// 公園の写真
class ParkImages {
    /// トップ画像
    var topImage = ""
    /// 参考画像
    var subImage1 = ""
    var subImage2 = ""
}

/// 公園のコメント
class Comments {
    /// comments
    var comment = ""
    var description = ""
}

/// 付帯設備
class Facilities {
    ///  駐車場有無（parking）
    var parking = -1
    ///  コンビニ有無（convenience）
    var convenience = -1
    ///  自動販売機有無（vender）
    var vender = -1
    ///  トイレ有無（toilet）
    var toilet = -1
    ///  多目的トイレ有無（multipurpose）
    var multipurpose = -1
}

/// 公園の情報
class ParkInfo {
    /// NCMB のオブジェクト ID
    var objectID = ""
    
    /// 公園名
    var name = ""
    
    /// 住所
    var address = ""
    
    /// 緯度軽度
    var coordinate = CLLocationCoordinate2D()
    
    /// 情報更新日・登録日
    var dates = Dates()
    
    /// 画像
    var pictures = ParkImages()
    
    /// コメント
    var comments = Comments()
    
    /// 設備情報
    var facilities = Facilities()
    
    /// 遊具一覧（facilities）：[String]
    var playEquipments: [String] = []
    
    /// 公園情報の更新を行う
    /// - Parameters:
    ///   - completionHandler: 更新が問題なく終わったときの処理
    ///   - errorHandler: 更新にエラーがあったときの処理
    func update(completionHandler: @escaping () ->(), errorHandler: @escaping (Error)->()) {
        let obj = NCMBObject(className: "Parks")
        obj.objectId = objectID
        
        obj["address"] = address
        obj["name"] = name
        
        // 画像については逐一変更しているので、まとめて更新しない
        //        obj["topImage"]
        //        obj["subImage1"]
        //        obj["subImage2"]
        
        obj["comment"] = comments.comment
        obj["description"] = comments.description
        
        obj["parking"] = facilities.parking
        obj["convenience"] = facilities.convenience
        obj["vender"] = facilities.vender
        obj["toilet"] = facilities.toilet
        obj["multipurpose"] = facilities.multipurpose
        
        obj["facilities"] = playEquipments
        
        obj.saveInBackground { result in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    completionHandler()
                }
                
            case .failure(let error):
                DispatchQueue.main.async {
                    errorHandler(error)
                }
            }
        }
        
    }
}
