import UIKit

///ネットワークエラーを定義するenum
enum NetworkError: Error {
    case badUrl //不正なURLを示す
    case noData //データが取得できなかった場合
    case decodingError //デコードに失敗した場合
}

///投稿を表すモデル構造体
struct Post: Decodable {
    let title: String //投稿のタイトル
}

///投稿を非同期で取得する関数
///URLSessionの処理全体が非同期に行われるため、getPosts関数を呼び出したメインスレッド（UIスレッドなど）はブロックされずに他の操作が可能
///アクセスできないサードパーティ製の場合の場合もある
//返されるのはResult型（配列かエラー）
func getPosts(completion: @escaping (Result<[Post], NetworkError>) -> Void) {
    
    //URLオブジェクトを生成し、不正であればbadUrlエラーを返す
    guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
        completion(.failure(.badUrl))
        return
    }
    
    //URLSessionを使ってデータタスクを作成し、実行してデータを取得
    URLSession.shared.dataTask(with: url) { data, _, error in
        
        //データがない、またはエラーがあればnoDataエラーを返す
        guard let data = data, error == nil else {
            completion(.failure(.noData))
            return
        }
        
        //取得したデータをPostの配列にデコード
        let posts = try? JSONDecoder().decode([Post].self, from: data)
        //完了ハンドラーを呼び出して結果を返す
        //nilの場合は、空の配列を渡す
        completion(.success(posts ?? []))
        
        //非同期のデータタスクを開始
        //.resumeを忘れるとURLSessionが開始されない
    }.resume()
    
}


///コールバックを使用して結果を使用
getPosts { result in
    switch result {
    case .success(let posts): //成功した場合、取得した投稿を出力
        print(posts)
    case .failure(let error): //失敗した場合、エラーを出力
        print(error)
    }
}


///async/await 関数に変換
func getPosts() async throws -> [Post] {
    
    //withCheckedThrowingContinuationを用いて非同期処理を実行
    return try await withCheckedThrowingContinuation { continuation in
        //コールバックベースのgetPosts関数を呼び出し
        getPosts { result in
            switch result {
            case .success(let posts):
                //成功した場合、投稿の配列をContinuationを通して返す
                continuation.resume(returning: posts)
            case .failure(let error):
                //失敗した場合、エラーをContinuationを通して投げる
                continuation.resume(throwing: error)
            }
        }
    }
    
}

//非同期ブロックの実行
Task {
    do {
        //getPosts関数から投稿の配列を取得し、成功すれば出力
        let posts = try await getPosts()
        print(posts)
    } catch {
        //エラーが発生した場合は、エラーを出力
        print(error)
    }
}
