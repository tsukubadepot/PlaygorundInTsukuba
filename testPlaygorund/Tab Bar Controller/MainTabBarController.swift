//
//  MainTabBarController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/25.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import NCMB
import Kingfisher

class MainTabBarController: UITabBarController {
    var parkModel = ParkModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print(#file)
        // NCMB の初期化
        NCMB.initialize(applicationKey: applicationkey, clientKey: clientkey)
    }
}

extension MainTabBarController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return parkModel.parks.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! ParkTableViewCell
        let park = parkModel.parks[indexPath.row]
        
        if park.pictures.topImage.isEmpty {
            // トップイメージが設定されていない場合
            cell.imageThumbnailView.image = nil
            cell.imageThumbnailView.backgroundColor = .gray
        } else {
            // トップイメージがある場合
            let url = URL(string: ncmbFileBaseURL + park.pictures.topImage)
            let processor = DownsamplingImageProcessor(size: cell.imageThumbnailView.bounds.size)
            
            cell.imageThumbnailView.kf.indicatorType = .activity
            cell.imageThumbnailView.kf.setImage(
                with: url,
                placeholder: UIImage(named: "loading-temp"),
                options: [
                    .processor(processor),
                    .scaleFactor(UIScreen.main.scale),
                    .transition(.fade(1)),
                    .cacheOriginalImage
                ], completionHandler:
                    {
                        result in
                        switch result {
                        case .success(let value):
                            print("Task done for: \(value.source.url?.absoluteString ?? "")")
                        case .failure(let error):
                            print("Job failed: \(error.localizedDescription)")
                        }
                    })
        }
        
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

