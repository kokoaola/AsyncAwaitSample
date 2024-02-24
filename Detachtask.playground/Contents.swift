import UIKit

/// サムネイル画像を非同期に取得する関数
func fetchThumbnails() async -> [UIImage] {
    // 空のUIImage配列を返す
    return [UIImage()]
}

/// UIを更新するための非同期関数
func updateUI() async {
    // サムネイル画像を非同期に取得
    let thumbnails = await fetchThumbnails()
    
    //サムネイル画像の取得とは切り離して（デタッチして）、画像をバックグラウンドでキャッシュに書き込む。
    //スレッドを完全に切り離してローカルキャッシュに保存
    Task.detached(priority: .background) {
        // キャッシュへの書き込み処理を実行
        writeToCache(images: thumbnails)
        print(Task.currentPriority == .background)
    }
}

/// 画像をキャッシュに書き込むための関数
private func writeToCache(images: [UIImage]) {
    // キャッシュへの書き込みを行う
}

/// UIの更新処理を非同期に実行するタスク
Task {
    // UI更新関数を非同期に呼び出す
    await updateUI()
}

/*
 
 
 Task.detached(priority: .background)を使用する理由は、特定の非同期処理を現在の実行コンテキストや親タスクから独立して、特定の優先度（この場合はバックグラウンド優先度）で実行したい場合に適しているからです。このコードのコンテキストでTask.detachedが使用される主な目的は、以下になります：
 
 バックグラウンドでの実行
 priority: .backgroundを指定することで、このタスクがバックグラウンドで実行されることが示されます。これは、UIの更新やユーザーインタラクションに直接関連しない、リソースを消費する作業や時間がかかる処理をバックグラウンドで行いたい場合に有効です。画像をキャッシュに書き込む処理は、ユーザーの操作を妨げることなく裏で静かに行われるべき作業の一例です。
 
 独立性
 Task.detachedを使用すると、この非同期タスクは親タスクやその他の実行コンテキストから独立しています。つまり、このタスクは親タスクの完了やキャンセルに影響されずに実行されます。これにより、親タスクが完了しても、キャッシュへの書き込み処理は影響を受けずに完了することが保証されます。
 
 エラーハンドリングの分離
 Task.detachedによって起動されるタスクは、エラーハンドリングも独立しています。つまり、このタスク内で発生したエラーは、タスクを起動したコンテキストには自動的に伝播されません。エラー処理をこの非同期タスク内で完結させたい場合、Task.detachedは適切な選択となります。
 
 用途に応じた適切な選択
 Task.detachedの使用は、上述したような特定のシナリオにおいて有効ですが、全ての非同期処理において推奨されるわけではありません。構造化並行性の利点（エラーハンドリングの容易さ、リソース管理の明確さなど）を享受するため、TaskやTaskGroupを利用することが一般的には推奨されます。しかし、バックグラウンドでの独立した処理が必要な場合には、Task.detachedが適切なツールとなるでしょう。
 
 */
