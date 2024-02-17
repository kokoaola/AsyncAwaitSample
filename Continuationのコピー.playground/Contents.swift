import UIKit

///同時実行性を活用して、特定のユーザーIDに基づくクレジットスコア（APR:利率）を、異なる二つのデータソース（EquifaxとExperian）から非同期に取得する
///ユーザーIDを渡すとランダムなクレジットスコアが返されるAPIを使用

//ネットワークエラーを定義するenum
enum NetworkError: Error {
    case badUrl //不正なURLエラー
    case decodingError //デコーディングエラー
}

//クレジットスコアをデコードするためのモデル構造体
struct CreditScore: Decodable {
    let score: Int //ユーザーのクレジットスコア
}

///定数を管理する構造体
struct Constants {
    //URLを管理する構造体
    struct Urls {
        //EquifaxのAPIエンドポイントURLを生成
        static func equifax(userId: Int) -> URL? {
            return URL(string: "https://ember-sparkly-rule.glitch.me/equifax/credit-score/\(userId)")
        }
        
        //ExperianのAPIエンドポイントURLを生成
        static func experian(userId: Int) -> URL? {
            return URL(string: "https://ember-sparkly-rule.glitch.me/experian/credit-score/\(userId)")
        }
    }
}

///ユーザーIDを基にAPRを非同期で取得する関数
func getAPR(userId: Int) async throws -> Double {
    
    //EquifaxとExperianのURLを取得し、いずれかがnilならエラーを投げる
    guard let equifaxUrl = Constants.Urls.equifax(userId: userId),
          let experianUrl = Constants.Urls.experian(userId: userId) else {
        throw NetworkError.badUrl
    }
    
    //Equifaxからデータを非同期に取得
    let (equifaxData, _) = try await URLSession.shared.data(from: equifaxUrl)
    //Experianからデータを非同期に取得
    let (experianData, _) = try await URLSession.shared.data(from: experianUrl)
    
    //ここでAPRの計算処理を行う（現在は仮の値を返している）
    return 0.0
    
}
