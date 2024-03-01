///指定されたURLからgovファイルを非同期に読み込み、その内容を行単位で処理する例
///
import UIKit


///URL拡張で非同期にテキスト行を取得するメソッドを追加
extension URL {
    ///指定されたURLからテキストの全行を非同期で取得するasync関数
    func allLines() async -> Lines {
        Lines(url: self)
    }
}

//URLから読み込んだテキストデータを行単位で扱うSequence
struct Lines: Sequence {
    //テキストデータのソースとなるURL
    let url: URL
    
    //Sequenceプロトコルに準じたイテレータを生成
    func makeIterator() -> some IteratorProtocol {
        //URLからテキストデータを読み込み、改行文字で分割して行配列を生成
        //読み込みに失敗した場合は空の配列を使用
        let lines = (try? String(contentsOf: url))?.split(separator: "\n") ?? []
        //行配列を扱うイテレータを返す
        return LinesIterator(lines: lines)
    }
}

//LinesSequenceのイテレータ、次の行を順に返す
struct LinesIterator: IteratorProtocol {
    //IteratorProtocolが扱う要素の型をStringに指定
    typealias Element = String
    //行データを保持する配列
    var lines: [String.SubSequence]
    
    //次の要素（行）を返し、ない場合はnilを返す
    mutating func next() -> Element? {
        if lines.isEmpty {
            return nil
        }
        //配列の最初の要素を取り出し、String型に変換して返す
        return String(lines.removeFirst())
    }
}

///サンプルのURLを定義
let endpointURL = URL(string: "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/all_month.csv")!

///普通のシーケンス
/*
//非同期タスクを開始
Task {
    ///awaitで待機してURLのテキストデータを行単位で非同期に取得
    ///取得が全て完了したら各行をコンソールに出力
    for line in await endpointURL.allLines() {
        print(line)
    }
}
 */

///Asyncシーケンス
///ダウンロードしながらPrint処理を行っている
Task {
    //awaitの位置が違う
    //1つのの非同期呼び出しが完了するとすぐに待機しアクセスできるようになる
    for try await line in endpointURL.lines {
        print(line)
    }
}

