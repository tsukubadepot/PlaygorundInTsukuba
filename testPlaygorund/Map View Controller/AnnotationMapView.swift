//
//  AnnotationMapView.swift
//  ParkInformationChecker
//
//  Created by Jun Yamashita on 2020/11/18.
//
import UIKit
import MapKit

protocol AnnotationMapViewDataSource: AnyObject {
    func numberOfAnnotations(in mapView: AnnotationMapView) -> Int
    func annotationMapView(_ mapView: AnnotationMapView, annotationFor: Int) -> MKPointAnnotation
}

protocol AnnotationMapViewDelegate: MKMapViewDelegate {
}

//typealias AnnotationMapViewDelegate = MKMapViewDelegate

class AnnotationMapView: MKMapView {
    weak var dataSource: AnnotationMapViewDataSource?
    
    /// MapView の範囲外にあるアノテーションも読み込むか否か
    var isLoadAllAnnotations = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        reloadAnnotations()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        reloadAnnotations()
    }
    
    
    /// 指定されたインデックスの Annotation を返す
    /// - Parameter index: 配列の index
    /// - Returns: index に対応した MKAnnotation. 存在しない場合には nil
    func getAnnotation(of index: Int) -> MKAnnotation? {
        if index < 0 || index >= annotations.count {
            return nil
        }

        return annotations[index]
    }
    
    func getAnnotation(of name: String) -> MKAnnotation? {
        return annotations.first { annotation -> Bool in
            return annotation.title == name
        }
    }
    
    
    /// アノテーションの読み込み
    func reloadAnnotations() {
        // 追加する注釈
        var annotationsInMap: [MKPointAnnotation] = []
        
        // dataSource が設定されていない場合、早期リターン
        guard let dataSource = dataSource else {
            return
        }
        
        let count = dataSource.numberOfAnnotations(in: self)
        
        for index in 0..<count {
            let annotation = dataSource.annotationMapView(self, annotationFor: index)
            
            // MKMapPoint に変換する
            let mapPoint = MKMapPoint(annotation.coordinate)
            
            if isLoadAllAnnotations {
                annotationsInMap.append(annotation)
            } else if self.visibleMapRect.contains(mapPoint) {
                // 表示領域内のみ Annotation に追加する
                annotationsInMap.append(annotation)
            }
        }
        addAnnotations(annotationsInMap)
    }
}
