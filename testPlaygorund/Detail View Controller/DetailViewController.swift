//
//  DetailViewController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/27.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import Kingfisher
import MapKit

class DetailViewController: UIViewController {
    // MARK: - local properties
    /// Model View Controller
    weak var parkModelController: MainTabBarController!
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
    
    // MARK: - 遊具情報
    @IBOutlet weak var equipmentTable: UITableView! {
        didSet {
            equipmentTable.dataSource = self
            equipmentTable.delegate = self
            // 選択不可
            equipmentTable.allowsSelection = false
            // スクロールできないようにする
            equipmentTable.isScrollEnabled = false
        }
    }
    
    /// UITableView の高さに関する制約
    @IBOutlet weak var equipmentTableHeightConstraint: NSLayoutConstraint!
    
    /// Cell の高さ
    let cellHeight: CGFloat = 30
    
    // MARK: 公園コメント
    @IBOutlet weak var descriptionLabel: UILabel!

    // MARK: 園内写真
    @IBOutlet weak var subImageView1: UIImageView! {
        didSet {
            // 短辺基準に全体表示
            subImageView1.contentMode = .scaleAspectFill
            subImageView1.isUserInteractionEnabled = true
        }
    }
    
    @IBOutlet weak var subImageView2: UIImageView! {
        didSet {
            // 短辺基準に全体表示
            subImageView2.contentMode = .scaleAspectFill
            subImageView2.isUserInteractionEnabled = true
        }
    }
    
    // MARK: 周辺地図
    @IBOutlet weak var mapView: AnnotationMapView! {
        didSet {
            mapView.layer.borderWidth = 1
            mapView.layer.borderColor = UIColor.gray.cgColor
            // 全てのアノテーションを読み込み
            mapView.isLoadAllAnnotations = true
        }
    }
    
    @IBOutlet weak var showAllAnnotationsSwitch: UISwitch! {
        didSet {
            showAllAnnotationsSwitch.isOn = false
        }
    }
    
    
    @IBOutlet weak var sendCommentButton: UIButton! {
        didSet {
            sendCommentButton.layer.cornerRadius = sendCommentButton.frame.height / 2
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // ヘッダ部
        setHeader()
        
        // 設備情報
        setFacilities()
        
        // 公園詳細コメント
        setDescriptionComment()
        
        // 詳細画像
        setSubImages()
        
        // 近隣地図表示
        mapView.dataSource = parkModelController
        showMap()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // コンテンツの内容に応じて UITableView の高さを変える
        let itemCount = park.playEquipments.count
        equipmentTableHeightConstraint.constant = CGFloat(itemCount) * cellHeight
    }
    
    // MARK: IBActions
    /// 戻るボタン
    @IBAction func backButton(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    /// 周辺公園表示のスイッチが切り替わった場合
    @IBAction func showAnnotationSelected(_ sender: UISwitch) {
        showAnnotations()
    }
    
    // MARK: - private methods
    /// ヘッダ部の表示
    fileprivate func setHeader() {
        // ヘッダ部
        parkNameLabel.text = park.name
        parkAddressLabel.text = park.address
        
        // トップ画像
        topImage.loadImage(forName: park.pictures.topImage)
        
        // 公園の簡単な紹介
        commentLabel.text = park.comments.comment
    }

    /// 設備情報の表示
    fileprivate func setFacilities() {
        // 駐車場
        parkingImageView.image = park.facilities.parking == 1 ? UIImage(named: "parking") : UIImage(named: "no-parking")
        
        // トイレ
        toiletImageView.image = park.facilities.toilet == 1 ? UIImage(named: "toilet") : UIImage(named: "no-toilet")
        
        // 多目的トイレ
        multiPurposeImageView.image = park.facilities.multipurpose == 1 ? UIImage(named: "bf") : UIImage(named: "no-bf")
        
        // 近隣店舗
        storeImageView.image = park.facilities.convenience == 1 ? UIImage(named: "shop") : UIImage(named: "no-shop")
        
        // 自動販売機
        venderImageView.image = park.facilities.vender == 1 ? UIImage(named: "vender") : UIImage(named: "no-vender")
    }
    
    /// 詳細コメントの表示
    fileprivate func setDescriptionComment() {
        var attributes: [NSAttributedString.Key: Any] = [:]
        let paragraphStyle = NSMutableParagraphStyle()
        let descriptionText = park.comments.description.isEmpty ? "コメント未入力" : park.comments.description

        paragraphStyle.lineSpacing = 10.0
        paragraphStyle.alignment = .natural
        attributes.updateValue(paragraphStyle, forKey: .paragraphStyle)
        descriptionLabel.attributedText = NSAttributedString(string: descriptionText, attributes: attributes)
    }

    /// 公園詳細画像の表示
    fileprivate func setSubImages() {
        subImageView1.loadImage(forName: park.pictures.subImage1)
        subImageView2.loadImage(forName: park.pictures.subImage2)
    }
        
    /// 近隣地図の表示
    private func showMap() {
        setRegion()
        showAnnotations()
    }
    
    fileprivate func setRegion() {
        var mapRegion = MKCoordinateRegion()
        
        let mapRegionSpan = 0.01
        mapRegion.center = park.coordinate
        mapRegion.span.latitudeDelta = mapRegionSpan
        mapRegion.span.longitudeDelta = mapRegionSpan
        
        mapView.setRegion(mapRegion, animated: true)
    }

    private func showAnnotations() {
        // TODO: この地図で他のアノテーションをクリックした時の動作をどのようにするのか
        
        // すでに登録している Annotation があれば一度削除する
        let visibleAnnotations = mapView.annotations
        mapView.removeAnnotations(visibleAnnotations)
        
        if showAllAnnotationsSwitch.isOn {
            mapView.loadAllAnnotations()
        } else {
            // 一度中心を戻す
            setRegion()
            mapView.loadAnnotation(forName: park.name)
        }
    }
}

// MARK: - 遊具情報の表示と情報の追加
extension DetailViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return park.playEquipments.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! PlayEquipmentTableViewCell
        
        cell.equipmentLabel.text = park.playEquipments[indexPath.row]
        
        return cell
    }
    
    // Cell の高さ
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return cellHeight
    }
}
