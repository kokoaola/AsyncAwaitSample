//
//  File.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/02/27.
//
///各IDに対してより多くのタスクを同時に実行できるようになったTaskGroup版

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
        
        
        //MARK: -
        ///タスクグループ作成
        ///タスクを作る -> returnで結果を渡す -> 結果を非同期シーケンスで処理
        //try awaitとwithThrowingTaskGroupでラップ
        //withThrowingTaskGroup: 複数の非同期タスクをグループ化して実行し、グループ内のすべてのタスクから受け取るエラーをいっぺんにハンドリングする
        //of:で非同期タスクが返す結果の値の型を指定する（何も返さない場合はVoid.self）
        //body:内でタスクグループを作成する
        try await withThrowingTaskGroup(of: (Int, RandomImage).self, body: { group in
            
            ///IDをループさせながら、タスクを追加&実行
            //group.addTask {}のクロージャの中身がタスクの本体、ここではasync letで作成した２つの子タスク（getRandomImage）を作成して非同期で実行している
            //データの競合を防ぐため、タスクグループ内から変数を変更はできない。タスクが完了したものからreturnで値を外部に渡す
            for id in ids {
                group.addTask {
                    return (id, try await self.getRandomImage(id: id))
                }
            }
            
            
            ///非同期シーケンス部分
            ///タスクグループ内のすべての子タスクが完了したものから順に結果を取り出し、一つずつ処理する
            //処理後は次のタスクが完了するまで待機
            //タスクグループ内の全てのタスクが完了し、それぞれの結果が処理されるまで繰り返す
            for try await (_, randomImage) in group {
                // コンソールにランダム画像を出力（デバッグ用）
                print(randomImage)
                // 取得したランダム画像を配列に追加
                randomImages.append(randomImage)
            }
        })
        
        /*async let版
        //idをループさせ、各IDに対してgetRandomImage型のデータを取得
        //awaitで待機するため、取得が完了するまで次の処理は開始されない
        for id in ids {
            //ランダム画像を非同期に取得したら配列に追加
            let randomImage = try await getRandomImage(id: id)
            randomImages.append(randomImage)
        }*/
        
        //全てのランダム画像が含まれた配列を返す
        return randomImages
    }
    
    
    ///指定されたIDを使用してランダム画像を非同期に取得するプライベート関数
    func getRandomImage(id: Int) async throws -> RandomImage {
        
        //画像用URLを取得し、無効な場合はエラーを投げる
        guard let url = Constants.Urls.getRandomImageUrl() else {
            throw NetworkError.badUrl
        }
        
        //引用用URLを取得し、無効な場合はエラーを投げる
        guard let randomQuoteUrl = Constants.Urls.randomQuoteUrl else {
            throw NetworkError.badUrl
        }
        
        //async letで2つの子タスクを作成（ランダム画像取得と引用のデータ取得）
        //2つの非同期タスクを独立したバックグラウンドスレッドで並列に開始
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
