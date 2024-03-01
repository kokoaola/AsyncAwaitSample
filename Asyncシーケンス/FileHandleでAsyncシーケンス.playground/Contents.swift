///非同期処理を用いて様々なタスクを実行する例
///ファイルの読み込み、ネットワークリクエスト、およびシステム通知の監視などを並行して実行


import Foundation
import UIKit
import _Concurrency
import CoreLocation

//メインバンドル内のすべてのtxtファイルのパスを取得
let paths = Bundle.main.paths(forResourcesOfType: "txt", inDirectory: nil)

//最初のtxtファイルの読み取り用のファイルハンドルを開く
let fileHandle = FileHandle(forReadingAtPath: paths[0])

//ファイルハンドルから非同期にバイトを読み込み、各バイトを出力
Task {
    for try await line in fileHandle!.bytes {
        print(line)
    }
}

//ファイルの内容を非同期に行単位で読み込み、各行を出力
Task {
    let url = URL(fileURLWithPath: paths[0])
    
    for try await line in url.lines {
        print(line)
    }
}

//指定されたURLからデータを非同期に取得し、取得した各バイトを出力
let url = URL(string: "https://www.google.com")!
Task {
    let (bytes, _) = try await URLSession.shared.bytes(from: url)
    for try await byte in bytes {
        print(byte)
    }
}

//アプリケーションがバックグラウンドに入ったときの通知を非同期に待ち、特定の条件に一致する最初の通知を処理
Task {
    let center = NotificationCenter.default
    let _ = await center.notifications(named: UIApplication.didEnterBackgroundNotification).first {
        guard let key = ($0.userInfo?["Key"]) as? String else { return false }
        return key == "SomeValue"
    }
}

