//
//  DetailViewController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/27.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import Kingfisher

class DetailViewController: UIViewController {
    // MARK: - local properties
    /// 公園情報
    var park: ParkInfo!
    
    // MARK: - ヘッダ UI
    /// 公園名
    @IBOutlet weak var parkNameLabel: UILabel!
    /// 公園の住所
    @IBOutlet weak var parkAddressLabel: UILabel!
    /// トップイメージ
    @IBOutlet weak var topImage: UIImageView! {
        didSet {
            // 短辺基準に全体表示
            topImage.contentMode = .scaleAspectFill
            topImage.isUserInteractionEnabled = true
        }
    }
    /// 公園短文コメント
    @IBOutlet weak var commentLabel: UILabel!
    /// お気に入りボタン
    @IBOutlet weak var likeButton: UIButton! {
        didSet {
            likeButton.layer.cornerRadius = likeButton.frame.height / 2
        }
    }
    
    // MARK: - 設備情報
    @IBOutlet weak var parkingImageView: UIImageView!
    @IBOutlet weak var toiletImageView: UIImageView!
    @IBOutlet weak var multiPurposeImageView: UIImageView!
    @IBOutlet weak var storeImageView: UIImageView!
    @IBOutlet weak var venderImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // MARK: ヘッダ部
        parkNameLabel.text = park.name
        parkAddressLabel.text = park.address
        
        // MARK: トップ画像
        topImage.loadImage(forName: park.pictures.topImage)
        
        // 公園の簡単な紹介
        commentLabel.text = park.comments.comment
        
        parkingImageView.image = park.facilities.parking == 1 ? UIImage(named: "parking") : UIImage(named: "no-parking")
        
        toiletImageView.image = park.facilities.toilet == 1 ? UIImage(named: "toilet") : UIImage(named: "no-toilet")
        
        multiPurposeImageView.image = park.facilities.multipurpose == 1 ? UIImage(named: "bf") : UIImage(named: "no-bf")
        
        storeImageView.image = park.facilities.convenience == 1 ? UIImage(named: "shop") : UIImage(named: "no-shop")
        
        venderImageView.image = park.facilities.vender == 1 ? UIImage(named: "vender") : UIImage(named: "no-vender")
        
        //        // MARK: 設備情報
        //        setFacilitiesSegment()
        //
        //        // MARK: 公園詳細コメント
        //        descriptionTextField.text = parkInfo.comments.description.isEmpty ? "コメント未入力" : parkInfo.comments.description
        //
        //        // MARK: 詳細画像
        //        loadImage(forView: subImageView1, forName: parkInfo.pictures.subImage1)
        //        loadImage(forView: subImageView2, forName: parkInfo.pictures.subImage2)
        //
        //        // MARK: 近隣地図表示
        //        showMap()
        
    }
        
    @IBAction func backButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
}
