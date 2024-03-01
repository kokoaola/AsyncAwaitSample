import UIKit
///asynclet(２つの処理を同時に実行)
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
    //IDが２の時はエラーとしてタスクをキャンセル
    //処理を中断し、呼び出し元に対してタスクが成功しなかったことを通知する
//    if userId == 2 {
//        throw NetworkError.invalidId
//    }
    
    
    
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
///使用するとき
///単体

//Task {
//    let apr = try await getAPR(userId: 1)
//    print(apr,"%")
//}

// MARK: -
///使用するとき
///ループ

///id1のタスクは２つの非同期処理が完了した時点で初めてコンプリートされ、id2のタスクにすすむ
///同時に実行されるのはasync letの２つのタスクだけであり、非同期処理が10個貯まるわけではないことに注意

let ids = [1,2,3,4,5] //処理対象のユーザーID群
var invalidIds: [Int] = [] //無効なIDを格納する配列


///タスクが複数の時このコードを出力すると、id2以降は実行されなくなってしまう
///理由：idが2のときにgetAPR()関数から投げられるNetworkError.invalidIdエラーが捕捉されず、プログラムの実行が停止するため
///解決策：do-catchブロックを追加してエラー時の処理を追加することで、id3以降も続けられるようにする
//Task {
//    for id in ids {
//        try Task.checkCancellation()
//        let apr = try await getAPR(userId: id)
//        print(id, apr)
//    }
//}

///エラーハンドリングを追加したコード
///id3以降も無視されなくなる

Task {
    for id in ids {
        do {
            ///.checkCancellation：子タスク（２つのうちの１つのタスク）にエラーがないかどうかをチェックする
            ///キャンセルされていればCancellationErrorを投げタスクを終了させ、エラーハンドリングのコードブロックに処理が移る
            try Task.checkCancellation()
            //指定したユーザーIDでAPRを非同期に取得
            let apr = try await getAPR(userId: id)
            //取得したAPRを出力
            print(apr)
        } catch {
            //getAPR()と.checkCancellation()の
            //いずれかでエラーが発生した場合このcatchブロックが実行される
            //エラーが発生した場合はエラーを出力し、該当するユーザーIDはinvalidIds配列に追加
            print(error)
            invalidIds.append(id)
        }
    }
    //無効なIDのリストを出力
    print(invalidIds)
}
