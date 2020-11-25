//
//  StringExtensions.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/02/18.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import Foundation

// 文字列操作のための拡張
// https://qiita.com/shtnkgm/items/83e88f230366adfad8e8
// https://dishware.sakura.ne.jp/swift/archives/225
extension String {
    /// StringからCharacterSetを取り除く
    func remove(characterSet: CharacterSet) -> String {
        return components(separatedBy: characterSet).joined()
    }
    
    /// StringからCharacterSetを抽出する
    func extract(characterSet: CharacterSet) -> String {
        return remove(characterSet: characterSet.inverted)
    }
    
    /// 全角英数字を半角に変換する
    func convertFromFullToHalf() -> String {
        let pattern = "[Ａ-Ｚａ-ｚ０-９（）　]+"  // 全角の英数字と全角括弧と全角スペース。[ ]と - と + は半角です。
        var string = self
        for _ in 0...self.count {
            if let foundRange = string.range(of: pattern, options: .regularExpression, range: string.range(of: string), locale: .current) {
                if let replacing = string[foundRange.lowerBound..<foundRange.upperBound].applyingTransform(.fullwidthToHalfwidth, reverse: false) {
                    string = string.replacingOccurrences(of: pattern, with: replacing, options: .regularExpression, range: foundRange)
                }
            } else {
                break
            }
        }
        return string
    }
}
