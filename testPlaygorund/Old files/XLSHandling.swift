//
//  XLSHandling.swift
//  testPlaygorund
//
//  Created by Jun Yamashita on 2020/02/18.
//  Copyright © 2020 Jun Yamashita. All rights reserved.
//

import Foundation
import CoreXLSX

func excel(path: String) -> [PlayGround] {
    // 公園情報
    var playGround = [PlayGround]()
    
    // Excelファイルをパースする
    guard let file = XLSXFile(filepath: path) else {
        print("path to file: \(path)")
        fatalError("XLSX file corrupted or does not exist")
    }
    
    var count = 0
    
    // SharedString を生成する
    let sharedStrings = try! file.parseSharedStrings() //エラー処理必要
    
    for path in try! file.parseWorksheetPaths() { // エラー処理
        let ws = try! file.parseWorksheet(at: path) // エラー処理
        for row in ws.data?.rows ?? [] {
            // 最初の行はパス
            if count == 0 { count = 1; continue }
            
            // 公園情報を抽出
            let name = sharedStrings.items[Int(row.cells[0].value!)!].text!
            let address = sharedStrings.items[Int(row.cells[1].value!)!].text!.convertFromFullToHalf()
            let facility = sharedStrings.items[Int(row.cells[2].value!)!].text!.remove(characterSet: .whitespaces)
            let lat = Double(row.cells[3].value!)!
            let lon = Double(row.cells[4].value!)!
            let latRef = Double(row.cells[5].value!)!
            let lonRef = Double(row.cells[6].value!)!
            let facilityCount = facility.components(separatedBy: CharacterSet(charactersIn: "、・")).count
            
            // 配列に追加
            playGround.append(PlayGround(name: name, address: address, facility: facility, facilityCount: facilityCount, lat: lat, lon: lon, latRef: latRef, lonRef: lonRef))
            
            count += 1
        }
    }
    return playGround
}

enum DownloadError : Error {
    case ClientSideError(String)
    case NoResponse
    case StatusWith(Int)
}

func downloadPlaygroundData() throws -> [PlayGround] {
    let locationOfExcel = "https://www.city.tsukuba.lg.jp/_res/projects/default_project/_page_/001/004/978/playgroundequipment.xlsx"
    let url = URL(string: locationOfExcel)!
    // 公園情報のダウンロード先
    var playgroundPath: String!
    // エラー情報
    var downloadError: DownloadError?
    
    // ダウンロード制御用のフラグ
    // サーバのエクセルファイルは更新されているか
    var isExcelModified = false
    // ローカルにエクセルファイルが保存されて「いない」か
    var isExcelNotSaved = false
    
    // userDefaults のインスタンス
    let userDefaults = UserDefaults.standard
    
    // デバッグ用に一userDefaultsを一括削除するコードを埋め込む
//        if let domain = Bundle.main.bundleIdentifier {
//            print("saved UserDefaults were removed.")
//            userDefaults.removePersistentDomain(forName: domain)
//        }
    
    // userDefaultsに保存するデータ
    // a. 保存したデータのファイル名
    // b. サーバ上の更新日付
    
    // 流れ
    // 1. 保存したデータがない -> データダウンロード
    // 2. 更新日付をチェック -> 新しければデータダウンロード
    // 3. iPhone上の Excel ファイルを使用
    
    // データ保存用のパスを作成
    let filename = "playgroundequipment.xlsx"
    let fileManager = FileManager.default
    let docURL = try! fileManager.url(for: .documentDirectory,
                                      in: .userDomainMask,
                                      appropriateFor: nil,
                                      create: true)
    let filePathURL = docURL.appendingPathComponent(filename)
    
    // 1. 保存したデータがあるかチェック
    if let _ = userDefaults.url(forKey: "filePathURL") {
        print("Saved Excel file is found.")
        isExcelNotSaved = false
    } else {
        // ローカルにエクセルファイルが見つからない
        isExcelNotSaved = true
    }
    
    ///
    // HTTPリクエストを生成
    var request = URLRequest(url: url)
    // まずは HEAD メソッドで更新日時のみ取得する
    request.httpMethod = "HEAD"
    // ロックをかけて同期処理にする
    let condition = NSCondition()
    
    
    // クロージャでダウンロードする
    let session = URLSession.shared
    let task = session.downloadTask(with: request) { url, urlResponse, error in
        defer {
            // エラーが起きても起きなくてもロックは解除
            condition.signal()
            condition.unlock()
            
        }

        //
        condition.lock()
        
        if let error = error {
            // クライアントサイドエラー
            print("Client side error: ", error.localizedDescription)
            downloadError = .ClientSideError(error.localizedDescription)
            
            return
        }
        
        if let location = url {
            // ダウンロード先 -> "HEAD"メソッドの時にはファイルサイズがゼロ
            print(location.absoluteString)
        }
        
        if let urlResponse = urlResponse as? HTTPURLResponse {
            if urlResponse.statusCode == 200 {
                //            print("Status: \(urlResponse.statusCode)")
                //            print("Last-Modified: ", terminator: "")
                //            print(urlResponse.allHeaderFields["Last-Modified"]!)
                
                // 2. 更新日付のチェック
                if let storedFileDate = userDefaults.string(forKey: "Last-Modified") {
                    if storedFileDate == urlResponse.allHeaderFields["Last-Modified"] as! String {
                        print("Excel data on the server is not updated.")
                    } else {
                        print("Excel data on the server is updated.")
                        isExcelModified = true
                    }
                } else {
                    // UserDefaults にキーが存在しない
                    print("UserDefaults for Last-Modified is not found")
                    
                    // キーが存在しない場合は再度ダウンロードする
                    isExcelModified = true
                    isExcelNotSaved = true
                }
            } else {
                // statusCode が 200 以外の場合
                print("Server error may happen. ", urlResponse.statusCode)
                downloadError = .StatusWith(urlResponse.statusCode)
            }
        } else {
            // サーバからのレスポンスがない場合
            print("No response. ")
            downloadError = .NoResponse
            
            return
        }
        // ロック解除は defer {} で定義済み
    }
    
    condition.lock()
    task.resume()
    condition.wait()
    condition.unlock()
    
    if let error = downloadError, isExcelNotSaved {
        // クロージャ内の処理でエラーが発生し、かつ Excel のキャッシュが存在していない場合
        throw error
    }
    
    // Excelファイルが更新されている、もしくはローカルに存在しない場合
    if isExcelModified || isExcelNotSaved {
        // HTTPリクエストを生成
        //var request = URLRequest(url: url)
        // ファイル本体を取得する
        request.httpMethod = "GET"
        // ロックをかけて同期処理にする
        //  let condition = NSCondition()
        
        // クロージャでダウンロードする
        let sessionGet = URLSession.shared
        let taskGet = sessionGet.downloadTask(with: request) { url, urlResponse, error in
            //
            condition.lock()
            
            if let location = url {
                // ダウンロード先 -> "GET"メソッドの時には実際にダウンロードする
                print(location.absoluteString)
            }
            
            if let urlResponse = urlResponse as? HTTPURLResponse {
                //            print("Status: \(urlResponse.statusCode)")
                //            print("Last-Modified: ", terminator: "")
                //            print(urlResponse.allHeaderFields["Last-Modified"]!)
                
                // b. userDefaults にパス名を保存
                userDefaults.set(urlResponse.allHeaderFields["Last-Modified"]!, forKey: "Last-Modified")
                // データの同期
                userDefaults.synchronize()
            }
                        
            // ファイルがある場合は削除
            do {
                //            print("Delete old file: ", filePathURL)
                
                try fileManager.removeItem(at: filePathURL)
            } catch {
                print("***Delete failed.")
            }
            
            // 保存
            do {
                try fileManager.moveItem(at: url!, to: filePathURL)
                //            print("saved at: \(filePathURL)")
                
                // a. userDefaults にパス名を保存
                userDefaults.set(filePathURL, forKey: "filePathURL")
                // データの同期
                userDefaults.synchronize()
                
            } catch {
                print("***error in moveItem")
            }

            condition.signal()
            condition.unlock()
        }
        
        condition.lock()
        taskGet.resume()
        condition.wait()
        condition.unlock()
    }
    
    // URL をパス名に変換
    playgroundPath = filePathURL.absoluteString
    playgroundPath.removeFirst(7) // スキーム名(file://) を削除->スマートな方法が欲しい
    
    // Excelファイルを分析する
    return excel(path: playgroundPath)
}
