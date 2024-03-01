import UIKit

///同時実行性を活用して、特定のユーザーIDに基づくクレジットスコア（APR:利率）を、異なる二つの信用機関（EquifaxとExperian）から非同期に取得する
///ユーザーIDを渡すとランダムなクレジットスコアが返されるAPIを使用
///ユーザーIDが2のときはエラーとなり、通信はキャンセルされる

//ネットワークエラーを定義するenum
enum NetworkError: Error {
    case badUrl //不正なURLエラー
    case decodingError //デコーディングエラー
    case invalidId //IDエラー
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

///ユーザーIDを渡すと、非同期でAPRを取得する関数
func getAPR(userId: Int) async throws -> Double {

    //EquifaxとExperianのURLを取得し、いずれかがnilならエラーを投げる
    guard let equifaxUrl = Constants.Urls.equifax(userId: userId),
          let experianUrl = Constants.Urls.experian(userId: userId) else {
        throw NetworkError.badUrl
    }
    
    //Equifaxからデータを非同期に取得
    //async letを使用することで、複数の非同期処理を同時に開始し、後でその結果をawaitで取得できる
    async let (equifaxData, _) = URLSession.shared.data(from: equifaxUrl)
    //Experianからデータを非同期に取得
    async let (experianData, _) =  URLSession.shared.data(from: experianUrl)
    
    /*
     元の同期処理のコードはこちら
     通常は上のタスクが完了するのを待ってからデータの取得が開始するが、
     上の方法async letをしようすると順番を待たずにタスクを同時実行で並列化する＝全体の実行時間を短縮
     let (equifaxData, _) = try await URLSession.shared.data(from: equifaxUrl)
     
     let (experianData, _) = try await URLSession.shared.data(from: experianUrl)
     */
    
    //デコード
    //awaitでマーキングし、URLSessionの非同期処理の結果が得られるまで待機
    let equifaxCreditScore = try? JSONDecoder().decode(CreditScore.self, from: try await equifaxData)
    
    let experianCreditScore = try? JSONDecoder().decode(CreditScore.self, from: try await experianData)
    
    //アンラップ
    guard let equifaxCreditScore = equifaxCreditScore,
          let experianCreditScore = experianCreditScore else {
        throw NetworkError.decodingError
    }
    
    //APRの計算処理
    return calculateAPR(creditScores: [equifaxCreditScore, experianCreditScore])
}


///クレジットスコアを基にAPRを計算する関数（ダミーの実装）
///今回の内容において重要ではない
func calculateAPR(creditScores: [CreditScore]) -> Double {
    let sum = creditScores.reduce(0) { next, credit in
        return next + credit.score
    }
    return Double((sum/creditScores.count)/100)
}


// MARK: -

let ids = [1,2,3,4,5] //処理対象のユーザーID群

///タスクグループで使用する
///タスクグループとは：複数の非同期タスクを並列に実行し、全てのタスクが完了するまで待つこと。グループのタスクが実行中であっても新たなタスクを追加することができる。タスクグループ内で発生したエラーは、グループの外で一括して捕捉し、処理する。
///１のループの方法だと、２つの非同期処理を持つタスクが１件ずつ逐次的に実行されるが、この例では２つの非同期処理（子タスク）を持つ５つのタスクからなるタスクグループを作成。並列で子タスクを実行し、結果を集約する
///タスクグループの使用例：タスクグループを使用し、複数のAPIエンドポイントからのデータ取得を並列タスクとして同時にフェッチし、全てのデータが揃った後で次の処理を行うなど

func getAPRForAllUsers(ids: [Int]) async throws -> [Int: Double] {
    //各ユーザーIDとAPRの取得結果を格納する辞書
    var userAPR: [Int: Double] = [:]
    
    ///タスクグループ作成
    //try awaitとwithThrowingTaskGroupでラップ
    //withThrowingTaskGroup: 複数の非同期タスクをグループ化して実行し、タスクから投げられる可能性のあるエラーを扱う。グループ内のタスクが投げるエラーは一箇所でハンドリングする
    //of:で非同期タスクが返す値の型を指定し、body内でタスクグループを作成する
    try await withThrowingTaskGroup(of: (Int, Double).self, body: { group in
        
        //IDをループさせながら、タスクを追加する
        //タスクグループ内の各タスクが非同期に実行され、それぞれが(id, apr)形式のタプルを返す処理
        for id in ids {
            //group.addTask {}はクロージャを非同期の子タスクとしてタスクグループに追加し、並列に実行させる
            group.addTask {
                //どのタスクから終了するかわからないため、データの競合が発生しないように、タスクグループ内から変数を変更したりはできないようになっている。タスクが完了したらreturnして値を返す
                let apr = try await getAPR(userId: id)
                return (id, apr)
            }
        }

        //タスクグループ内の各タスクが完了するたびに、完了したタスクの結果だけを取り出し、一つずつ処理する
        //処理後は次のタスクが完了するまで待機
        //タスクグループ内の全てのタスクが完了し、それぞれの結果が処理されるまで繰り返す
        for try await (id, apr) in group {
            userAPR[id] = apr
        }
    })
    
    return userAPR
    
}

///親タスク
Task {
    let userAPRs = try await getAPRForAllUsers(ids: ids)
    print(userAPRs)
}
