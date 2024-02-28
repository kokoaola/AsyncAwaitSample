//
//  File.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/02/27.
//

///Webserviceファイルはランダムな画像とランダムなコードのデータを取得する
import Foundation


///NetworkError：ネットワークリクエスト中に発生する可能性のあるエラーを定義する
enum NetworkError: Error {
    case badUrl
    case invalidImageId(Int)
    case decodingError
}


///Webserviceクラス：ランダムな画像と引用を取得するためのAPI呼び出しを担当するクラス
class Webservice {
    
    ///受け取ったIDに基づいてランダム画像の配列を非同期に取得する関数
    func getRandomImages(ids: [Int]) async throws -> [RandomImage] {
        
        //ランダム画像を保持するための空の配列を初期化
        var randomImages: [RandomImage] = []
        
        //idをループさせ、各IDに対してgetRandomImage型のデータを取得
        //awaitで待機するため、取得が完了するまで次の処理は開始されない
        for id in ids {
            //ランダム画像を非同期に取得したら配列に追加
            let randomImage = try await getRandomImage(id: id)
            randomImages.append(randomImage)
        }
        //全てのランダム画像が含まれた配列を返す
        return randomImages
    }
    
    
    ///指定されたIDを使用してランダム画像を非同期に取得するプライベート関数
    private func getRandomImage(id: Int) async throws -> RandomImage {
        
        //画像用URLを取得し、無効な場合はエラーを投げる
        guard let url = Constants.Urls.getRandomImageUrl() else {
            throw NetworkError.badUrl
        }
        
        //引用用URLを取得し、無効な場合はエラーを投げる
        guard let randomQuoteUrl = Constants.Urls.randomQuoteUrl else {
            throw NetworkError.badUrl
        }
        
        //async letでランダム画像と引用のデータ、2つの非同期タスクを独立したバックグラウンドスレッドで並列に開始
        //それぞれの非同期処理を並列で開始するが、お互いの処理の完了を待たずに次に進み、awaitに到達したらそれぞれのタイミングで待機する
        async let (imageData, _) = URLSession.shared.data(from: url)
        async let (randomQuoteData, _) = URLSession.shared.data(from: randomQuoteUrl)
        
        //awaitでrandomQuoteDataの結果を待ってから引用データをデコードし、失敗した場合はエラーを投げる
        //この時点で、randomQuoteDataの取得が完了していなければ、awaitによって完了するまで処理が待機する
        guard let quote = try? JSONDecoder().decode(Quote.self, from: try await randomQuoteData) else {
            throw NetworkError.decodingError
        }
        
        //ランダム画像データと引用を使用してRandomImageインスタンスを返す
        //image:imageDataを取得する非同期処理が完了するまで待機させたいので、try awaitが必要
        //quote:１行上で待機させ、既に処理済みのデータとして存在するため、try awaitは不要
        return RandomImage(image: try await imageData, quote: quote)
    }
    
}
