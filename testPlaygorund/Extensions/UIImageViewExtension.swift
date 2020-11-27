//
//  UIImageViewExtension.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/11/27.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import UIKit
import Kingfisher

extension UIImageView {
    func loadImage(forName name: String) {
        if name.isEmpty {
            self.image = UIImage(named: "notvisit")
        } else {
            let url = URL(string: ncmbFileBaseURL + name)
            let processor = DownsamplingImageProcessor(size: self.bounds.size)
            
            
            self.kf.indicatorType = .activity
            self.kf.setImage(
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
    }

}
