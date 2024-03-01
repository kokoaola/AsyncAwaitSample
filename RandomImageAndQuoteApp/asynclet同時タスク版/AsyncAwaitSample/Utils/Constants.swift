//
//  File.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/02/27.
//

import Foundation

///アプリ全体で必要なさまざまな種類の定数を記述
struct Constants {
    
    struct Urls {
        
        //ランダム画像を取得するためのURL
        //キャッシュされた画像になってしまうことを防ぐため、取得するたびにIDを変更する
        static func getRandomImageUrl() -> URL? {
            return URL(string: "https://picsum.photos/200/300?uuid=\(UUID().uuidString)")
        }
        
        //ランダム引用を取得するためのURL
        static let randomQuoteUrl: URL? = URL(string: "https://api.quotable.io/random")
        
    }
    
}
