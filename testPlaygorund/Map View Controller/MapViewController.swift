//
//  MapViewController.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/27.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import MapKit
import FSPagerView

class MapViewController: UIViewController {
    // MARK: - local properties
    /// parkModel を持っているコントローラのインスタンス
    weak var parkModelController: MainTabBarController?
    
    // MARK: - IB Outlets
    @IBOutlet weak var annotationMapView: AnnotationMapView! {
        didSet {
            annotationMapView.delegate = self
            annotationMapView.layer.borderColor = UIColor.gray.cgColor
            annotationMapView.layer.borderWidth = 1
            // MapView の範囲外にある Annotation も読み込ませる
            annotationMapView.isLoadAllAnnotations = true
        }
    }
    
    @IBOutlet weak var pagerView: FSPagerView! {
        didSet {
            pagerView.register(FSPagerViewCell.self, forCellWithReuseIdentifier: "cell")
            
            // 前後のセルを見せるために縮小する
            pagerView.itemSize = pagerView.frame.size.applying(CGAffineTransform(scaleX: 0.8, y: 0.8))
            
            pagerView.isInfinite = true
            pagerView.delegate = self
            
            //pagerView.transformer = FSPagerViewTransformer(type: .linear)
            pagerView.transformer = FSPagerViewTransformer(type: .overlap)
            pagerView.backgroundColor = .clear
        }
    }
    
    // MARK: - Instances of additional views
    lazy var scaleView: MKScaleView = {
        let sv = MKScaleView(mapView: annotationMapView)
        sv.scaleVisibility = .visible
        sv.translatesAutoresizingMaskIntoConstraints = false
        
        return sv
    }()
    
    lazy var compassButton: MKCompassButton = {
        let cb = MKCompassButton(mapView: annotationMapView)
        cb.compassVisibility = .visible
        cb.translatesAutoresizingMaskIntoConstraints = false
        
        return cb
    }()
    
    // MARK: - life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // AnnotationMapView, FSPagerView のデータソースは MainTabBarController で管理している
        if let parent = parent as? MainTabBarController {
            parkModelController = parent
            annotationMapView.dataSource = parkModelController
            pagerView.dataSource = parkModelController
        }
        
        var mapRegion = MKCoordinateRegion()
        
        // TODO: 将来は現在地にする
        mapRegion.center = CLLocationCoordinate2DMake(36.0874632, 140.0930501)
        
        let mapRegionSpan = 0.01
        mapRegion.span.latitudeDelta = mapRegionSpan
        mapRegion.span.longitudeDelta = mapRegionSpan
        
        annotationMapView.setRegion(mapRegion, animated: true)
        
        view.addSubview(scaleView)
        view.addSubview(compassButton)
        
        //annotationMapView.showsUserLocation = true
        
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        // ScaleView
        scaleView.topAnchor.constraint(equalTo: annotationMapView.topAnchor, constant: 12).isActive = true
        scaleView.leftAnchor.constraint(equalTo: annotationMapView.leftAnchor, constant: 12).isActive = true
        scaleView.widthAnchor.constraint(equalTo: annotationMapView.widthAnchor, multiplier: 0.33).isActive = true
        
        // CompassButton
        compassButton.topAnchor.constraint(equalTo: annotationMapView.topAnchor, constant: 12).isActive = true
        compassButton.rightAnchor.constraint(equalTo: annotationMapView.rightAnchor, constant: -12).isActive = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // すでに登録している Annotation があれば一度削除する
        let visibleAnnotations = annotationMapView.annotations
        annotationMapView.removeAnnotations(visibleAnnotations)
        
        annotationMapView.loadAllAnnotations()
    }
}

// MARK: - AnnotationMapViewDelegate
extension MapViewController: AnnotationMapViewDelegate {
    // アノテーションがクリックされたら呼び出される delegate
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let annotation = view.annotation else {
            return
        }
        
        // 選択されたピンの色を green にする
        if let view = view as? MKMarkerAnnotationView {
            view.markerTintColor = UIColor.green
        }
        
        let selectedCoordination = annotation.coordinate
        
        // アニメーションしながら選択されたピンを中心に持ってくる
        mapView.setCenter(selectedCoordination, animated: true)
        
        // 選択されたアノテーションに合わせて、 FSPagerView の画像を変更する
        if let model = parkModelController,
           let index = model.parkModel.index(of: annotation.title!!) {
            self.pagerView.scrollToItem(at: index, animated: true)
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        // ピンの色を戻す
        if let view = view as? MKMarkerAnnotationView {
            view.markerTintColor = nil
        }
        
    }
    
    // 表示領域が変わったら呼び出される delegate
    //    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
    // 既に表示されている Annotation は一度消す
    // TODO: 消すと拡大表示されている annotation も消えるのでその対策が必要。
    //        let visibleAnnotations = mapView.annotations
    //
    //        mapView.removeAnnotations(visibleAnnotations)
    //
    //        let v = mapView as! AnnotationMapView
    //        v.reloadAnnotations()
    //    }
}

// MARK: - FSPagerViewDelegate
extension MapViewController: FSPagerViewDelegate {
    // セルをタップしたら呼び出される delegate
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        let currentIndex = pagerView.currentIndex
        
        pagerView.deselectItem(at: index, animated: true)
        
        if currentIndex != index {
            pagerView.scrollToItem(at: index, animated: true)
        } else {
            // 同じセルをクリックすると二つの値が同じになる

            // TODO: ここもリファクタリングできないか？ MainTabBarController の TableView と関連づけたい
            let vc = storyboard?.instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
            
            vc.park = parkModelController!.parkModel.parks[index]
            vc.parkModelController = parkModelController
            
            vc.modalTransitionStyle = .crossDissolve
            vc.modalPresentationStyle = .overFullScreen
            
            present(vc, animated: true, completion: nil)
        }
    }
    
    // 自動スクロールが終了した時点で呼び出される delegate
    func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
        moveTo(index: pagerView.currentIndex)
    }
    
    // ドラッグが終了した時点で呼び出される delegate
    func pagerViewWillEndDragging(_ pagerView: FSPagerView, targetIndex: Int) {
        moveTo(index: targetIndex)
    }
    
    /// index に対応する Annotation を拡大表示させる
    /// - Parameter index: FSPagerView でのインデックス
    private func moveTo(index: Int) {
        // index から公園名を取得し、公園名から対応する Annotation を検索する
        guard let model = parkModelController,
              let name = model.parkModel.getParkName(of: index),
              let annotation = annotationMapView.getAnnotation(of: name) else {
            return
        }
        
        let selectedCoordination = annotation.coordinate
        
        // アニメーションしながら選択されたピンを中心に持ってくる
        annotationMapView.setCenter(selectedCoordination, animated: true)
        annotationMapView.selectAnnotation(annotation, animated: true)
    }
    
    // 前後含めて最後に表示された pagerView の index が表示されるので注意する
    //    func pagerView(_ pagerView: FSPagerView, willDisplay cell: FSPagerViewCell, forItemAt index: Int) {
    //    }
}
