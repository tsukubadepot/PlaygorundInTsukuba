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
import MapKit
import FSPagerView

class MainTabBarController: UITabBarController {
    var parkModel = ParkModel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
            cell.imageThumbnailView.image = UIImage(named: "notvisit")
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

extension MainTabBarController: AnnotationMapViewDataSource {
    func numberOfAnnotations(in mapView: AnnotationMapView) -> Int {
        return parkModel.parks.count
    }
    
    func annotationMapView(_ mapView: AnnotationMapView, annotationFor: Int) -> MKPointAnnotation {
        let annotation = MKPointAnnotation()
        let park = parkModel.parks[annotationFor]
        
        let lat = park.coordinate.latitude
        let lon = park.coordinate.longitude
        
        let coordinate = CLLocationCoordinate2DMake(lat, lon)
        annotation.coordinate = coordinate
        annotation.title = park.name
        annotation.subtitle = park.comments.comment
        
        return annotation
    }
}

extension MainTabBarController: FSPagerViewDataSource {
    func numberOfItems(in pagerView: FSPagerView) -> Int {
        return parkModel.parks.count
    }
    
    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "cell", at: index)
        let park = parkModel.parks[index]
        
        
        guard let imageView = cell.imageView else {
            fatalError("cannot dequeue pagerView")
        }
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        
        if park.pictures.topImage.isEmpty {
            // 画像データがない（まだ訪問していない）公園の場合
            
            imageView.image = UIImage(named: "notvisit")
            
        } else {
            // 訪問済みの場合には、トップ画像などを表示
                        
            let url = URL(string: ncmbFileBaseURL + park.pictures.topImage)
            let processor = DownsamplingImageProcessor(size: imageView.bounds.size)
                        
            imageView.kf.indicatorType = .activity
            imageView.kf.setImage(
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
        // 公園名
        // textLabel は最後に設定しないと ImageView の後ろになる
        cell.textLabel?.text = park.name

        return cell
    }
}

