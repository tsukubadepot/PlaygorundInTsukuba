//
//  UIImageViewExtension.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/27.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import AlamofireImage

extension UIImageView {
    func loadImage(forName name: String) {
        if name.isEmpty {
            self.image = UIImage(named: "notvisit")
        } else {
            let url = URL(string: ncmbFileBaseURL + name)

            // NCMB が MIME Type を text/plain すことへの対策
            ImageResponseSerializer.addAcceptableImageContentTypes(["text/plain"])
            
            let filter = AspectScaledToFillSizeFilter(size: self.bounds.size)

            // FSPagerView の UIImage が (0, 0) を返した時の対策。
            // (0, 0) の場合はスケールしない
            if self.bounds.size.equalTo(.zero) {
                self.af.setImage(withURL: url!, cacheKey: name, placeholderImage: UIImage(named: "loading-temp"), imageTransition: .crossDissolve(0.5))
            } else {
                self.af.setImage(withURL: url!, cacheKey: name, placeholderImage: UIImage(named: "loading-temp"), filter: filter, imageTransition: .crossDissolve(0.5))
            }
        }
    }

}
