///既存のアプリに非同期シーケンスを適応させる例
///BitcoinPriceMonitorクラスでビットコインの価格を定期的に更新し、その価格を非同期ストリームを通じて処理する
///方AsyncStreamを使用することで、非同期に生成されるデータのシーケンスをfor awaitループを使って逐次的に処理できる


import UIKit


///ビットコインの価格を監視するクラス
///定期的に変更または更新されたビットコイン価格を提供
class BitcoinPriceMonitor {
    
    var price: Double = 0.0 //現在のビットコイン価格
    var timer: Timer? //価格更新を行うタイマー
    var priceHandler: (Double) -> Void = { _ in } //価格が更新されたときの処理を保持するハンドラ
    
    ///価格の自動更新を開始する
    func startUpdating() {
        //1秒ごとにgetPriceメソッドを繰り返し実行
        //timeInterval: 1.0: 1.0秒ごとにタイマーが発火
        //target: self: タイマー発火時に呼ばれるメソッドのレシーバ（受信オブジェクト）を指定。ここでは、BitcoinPriceMonitorインスタンス
        //selector: #selector(getPrice): タイマーが発火したときに実行されるメソッドを指定
        //userInfo: nil: タイマーに関連付けるユーザー情報を指定。特に情報を渡す必要がないためnilが指定
        //repeats: true: タイマーが一度だけか、繰り返し発火するかどうか指定。trueでタイマーが無効化されるまで繰り返される
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(getPrice), userInfo: nil, repeats: true)
    }
    
    ///価格の自動更新を停止する
    func stopUpdating() {
        timer?.invalidate() //タイマーを無効化
    }
    
    
    ///価格をランダムに更新してハンドラに渡す
    ///#selectorを使用するので @objc必須
    @objc func getPrice() {
        //20000から40000の間でランダムな価格を生成し、priceHandlerを通じて通知
        priceHandler(Double.random(in: 20000...40000))
    }
    
}


//MARK: - Asyncシーケンスを使用しないもの
////BitcoinPriceMonitorインスタンスを作成
//let bitcoinPriceMonitor = BitcoinPriceMonitor()
//    bitcoinPriceMonitor.priceHandler = {
//        print($0)
//    }
//    //ビットコイン価格の監視を開始
//    bitcoinPriceMonitor.startUpdating()



//MARK: - Asyncシーケンスを使用
//ちょっとわからない

///AsyncStreamを使用してビットコイン価格の非同期ストリームを作成
let bitcoinPriceStream = AsyncStream(Double.self) { continuation in
    //BitcoinPriceMonitorインスタンスを作成
    let bitcoinPriceMonitor = BitcoinPriceMonitor()
    //価格更新時にAsyncStreamに価格を送信するように設定
    bitcoinPriceMonitor.priceHandler = {
        continuation.yield($0)
    }

    //ビットコイン価格の監視を開始
    bitcoinPriceMonitor.startUpdating()
}

//非同期タスクでビットコイン価格のストリームを消費
Task {
    //ビットコイン価格ストリームから価格を非同期に取得し、出力
    for await bitcoinPrice in bitcoinPriceStream {
        print(bitcoinPrice)
    }
}




