//
//  Webservice.swift
//  NewsApp
//
//  Created by Mohammad Azam on 6/30/21.
//

import Foundation

enum NetworkError: Error {
    case badUrl
    case invalidData
    case decodingError
}

class Webservice {
    // MARK: -
    ///コールバック関数をasync/awaitの形に書き換える
    func fetchSources(url: URL?) async throws -> [NewsSource] {
        //URLをアンラップ
        guard let url = url else {
            //失敗したらからの配列を返す
            return []
        }
        //URLが正しい場合は非同期でセッション開始
        //エラーが生じる可能性がある関数を実行するためtryを使う
        let (data, _) = try await URLSession.shared.data(from: url)
        //エラーが生じる可能性がああり、エラーが発生した時はnilを返す&発生しなかった時はoptional型を返しためtry?をつける
        let newsSourceResponse = try? JSONDecoder().decode(NewsSourceResponse.self, from: data)
        //ソースが利用できない場合は、空の配列を返す
        return newsSourceResponse?.sources ?? []
    }
    
    
    ///直す前の関数
    /*
    func fetchSources(url: URL?, completion: @escaping (Result<[NewsSource], NetworkError>) -> Void) {
        
        guard let url = url else {
            completion(.failure(.badUrl))
            ///ここのreturn忘れちゃだめ
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            
            guard let data = data, error == nil else {
                completion(.failure(.invalidData))
                return
            }
            
            let newsSourceResponse = try? JSONDecoder().decode(NewsSourceResponse.self, from: data)
            completion(.success(newsSourceResponse?.sources ?? []))
            
        }.resume()
    }*/
     
     
    // MARK: -
    ///Continuationを使ってコールバック関数をasync/awaitスタイルに変換する
    ///（今回は元のfetchNews関数がアクセス権のないサードAPIとし、上と同じように書き換えができないものと仮定する
    ///取得コードにアクセスできる場合は、実際にアクセスして関数を変更した方が良い）
    func fetchNewsAsync(sourceId: String, url: URL?) async throws -> [NewsArticle] {
        
        //withCheckedThrowingContinuationは非同期処理が成功した場合に結果を返すか、失敗した場合にエラーを投げる
        try await withCheckedThrowingContinuation { continuation in
            //withCheckedThrowingContinuationの中でコールバック関数を呼び出す
            fetchNews(sourceId: sourceId, url: url) { result in
                switch result {
                case .success(let newsArticles):
                    //非同期関数を完了し、結果を返して一時停止状態から復帰
                    continuation.resume(returning: newsArticles)
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }
        }
    }
    
    
    ///コールバックベースのサードAPI（アクセス権なし）
    private func fetchNews(sourceId: String, url: URL?, completion: @escaping (Result<[NewsArticle], NetworkError>) -> Void) {
        
        guard let url = url else {
            completion(.failure(.badUrl))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            
            guard let data = data, error == nil else {
                completion(.failure(.invalidData))
                return
            }
            
            let newsArticleResponse = try? JSONDecoder().decode(NewsArticleResponse.self, from: data)
            completion(.success(newsArticleResponse?.articles ?? []))
            
        }.resume()
    }
}
