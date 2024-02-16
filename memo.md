# Swift Concurrency

## スレッドとキュー
- スレッドとは
    - PCやスマホのCPUに対して、タスクを割り当てる仕組みのこと。
    - CPUを効率よく使わないと、アプリのパフォーマンスが低下する。
    - 複数のスレッドを独立させてCPUの割り当てることで、処理を同時に効率よく実行させていくことができ、パフォーマンスが向上する。

- キューとは
    - タスクが実行されるまでの待ち行列のこと。一般的には、「先入れ先出し」（FIFO: First In, First Out）の原則で、最初に届いた処理から順番に実行される。
    - タスクの待ち行列の管理、データの一時的な保管、タスクの順序付けなど、さまざまななプログラミング言語で広く使用されている概念
- スレッドは実行の「方法」に関わり、キューは実行される「タスクや順序」に関わる。スレッドとキューを組み合わせることで効率的なプログラムを作ることができる

## スレッドの種類
1. メインスレッド(UIスレッド)
    - アプリ内で発生するすべての画面描写を担当するスレッドのこと。
    - アプリのユーザーインターフェイスで発生するすべての処理は、メインスレッドで処理されるため、処理が集中するとフリーズしたりする。
2. バックグラウンドスレッド
    - データの読み込み、ネットワークリクエスト、重い計算など、時間がかかる処理を担当するスレッドのこと。
    - アプリケーションの裏側で動作するため、メインスレッドのパフォーマンスを妨げない。


## Concurrencyという考え
- Concurrencyとは：同時並行処理、非同期処理とも言われる。複数のタスクを同時に実行したり、高速で切り替えながら実行すること。サンドイッチを食べながらプログラミングをする。友達と電話をしながら洗濯物を畳む。リクエストを送り、レスポンスが返るまでの待ち時間に他の処理をするなど
- スクロールなどのUIイベントと、画像のダウンロードをメインスレッドで同時に実行すると、ダウンロードが完了するまでUIイベントがフリーズしてしまう。これをを阻止するために、UIイベントのみをメインスレッドで、ダウンロードはバックグラウンドスレッドで分担させて必要がある。このように効率よく仕事を割り当てることが


## Grand Central Dispatch (GCD)
### GCDとは
Swift、Objective-Cに組み込まれている平行処理のためのAPIのこと。開発者がタスクを複数のスレッドに割り当ててることで、アプリケーションのパフォーマンスを向上させる。

### ディスパッチキューとは
- GCD内で使用される特別なキューのことで、シリアル（一度に1つのタスクを実行）またはコンカレント（複数のタスクを同時に実行）に設定できる
    - シリアルキュー
        - メインスレッド(UIスレッド)で使用されることが多く、UIの更新などに利用される。
        - FIFO（先入れ先出し）の原則に従うキュー。タスクが追加された順番に実行する。厳密な順序制御が可能であるため、タスク間の依存関係が重要な場合に有効。
        - 処理が集中するとUIがフリーズする可能性があるため、重い処理はバックグラウンドで行うべき。
    - グローバルキュー
        - コンカレントキューとも言われる。バックグラウンドスレッドで使用され、データの読み込みや計算などのCPUを多用する処理に適している。
        - このキューのタスクは複数同時に実行される。完了する順序はタスクによって異なるため（処理時間が短いほど早い）、追加された順番とは異なる可能性がある。これにより、効率的なマルチタスク処理が可能になる。
- GCDを活用することで、開発者は複雑なスレッド管理や同期処理について深く考えることなく、効率的な並行処理を実装できる。

### Swiftにおけるディスパッチキューの作成方法(簡単)
#### シリアルキューの作成方法
- 同期処理。上から順に実行され、タスク終了後に次のタスクが開始される
- 指定がないためメインスレッドで実行される
```Swift
//カスタムラベルでキューを作成
let queue = DispatchQueue(label: "SerialQueue")

//タスクの実行
queue.async{
    //最初のタスク
}

queue.async{
    //２番目のタスク
}
```

#### グローバルキューの作成方法
- 非同期で実行される。上から順に実行されるが、終了時間はバラバラになる
- 指定がないためメインスレッドで実行される
```Swift
//カスタムラベルでキューを作成
let queue = DispatchQueue(label: "ConcurrentQueue", attributes: .concurrent)

//タスクの実行
queue.async{
    //最初のタスク
}

queue.async{
    //２番目のタスク
}
```

#### バックグラウンドスレッドで処理を実行したい時の記述方法
```Swift
DispatchQeue.global().async{
    //データのダウンロード
}
```

#### バックグラウンドスレッドで処理を実行後、メインスレッドに切り替えてUIを更新する
```Swift
DispatchQeue.global().async{
    //データのダウンロード
    
    //UIについての処理はメインスレッドにキューを切り替える
    DispatchQeue.global().async{
        //UIの更新
    }
}
```


### 非同期処理を行う関数の作成方法
```Swift
///asyncをつける
    private func getDate() async -> CurrentDate?{
        //URLをアンラップ
        guard let url = URL(string: "https://glorious-neat-antarctopelta.glitch.me/current-date")else{
            fatalError("URL is incorrect!")
        }
        //URLが間違っていない場合は非同期でセッション開始
        //エラーが生じる可能性があるでthrowsとtryをつけている
        try await URLSession.shared.data(from: url)
    }
```
- URLSessionなどのAPIはすでにasyncとawaitが備わって作られている


## Continuationとは
- Continuationとは、従来のコールバックベースの非同期API等の処理を、async/await構文で扱えるようにするための機能のこと。サードパーティの関数に対してもasync/awaitに変換できて便利

#### コールバックベースの非同期関数
```Swift
//Postの配列を非同期で取得するコールバックでの非同期処理
//非同期処理を実行し、完了したらcompletionハンドラを呼び出す
func fetchPosts(completion: ([Post]) -> Void){
    //データの取得の処理

    //データを返すコンプリーションハンドラを呼び出す
    completion(posts)
}

//使う時
fetchPosts { posts in
    //戻り値postsを使った処理(UIの更新等)をここに記述
    DispatchQueue.main.async {
        self.tableView.reloadData()
    }
}

```

#### async/awaitパターンで使用するための関数
```Swift
// Postの配列を非同期で取得する関数
func getPosts() async -> [Post] {
    await withCheckedContinuation { continuation in
        // 既存のコールバックベースの非同期関数を呼び出し
        fetchPosts { posts in
            // 非同期処理が完了したら、resumeで一時停止を解放しContinuationを通じて結果を返す
            continuation.resume(returning: posts)
        }
    }
}

//使う時
func exampleUsage() async {
    let posts = await getPosts()
    //戻り値postsを使った処理(UIの更新等)を続けて記述
    DispatchQueue.main.async {
        self.tableView.reloadData()
    }
}

```

#### UIと関連づけて非同期関数を使用する
```Swift
//ビューの表示の際に非同期タスクを実行
//.taskクロージャは.onAppearの非同期処理版
Circle()
    .task {
    await newsSourceListViewModel.getSources()
    }

//ボタンで実装
    .navigationBarItems(trailing: Button(action: {
        //非同期用のクロージャにいないため、Taskキーワードが必須
        Task{
            await newsSourceListViewModel.getSources()
        }
    }, label: {
        Image(systemName: "arrow.clockwise.circle")
    }))
```

## @MainActorとは
- @MainActorとは、UIの更新などをブロック単位でまとめてメインスレッドで実行する操作を扱うための機能
- クラスに装飾すると、すべてのプロパティとすべての関数がメインスレッドを使用する
- 修飾された関数内でawaitを使用すると、awaitの非同期関数から戻った後のコードがメインスレッドで実行されることが保証される
- 非同期処理の結果をメインスレッドで安全に扱うための仕組み
- ディスパッチに関するDispatchQueue.main.async { }の記述は要らなくなる

```Swift
@MainActor func getData() async {
    let data = await fetchData() // バックグラウンドでデータをフェッチ
    // fetchDataの実行が完了し、ここに制御が戻ると、以下のUI更新コードはメインスレッドで実行される
    self.label.text = data
}
```

## メモ
- iOS15からasync{}キーワードが登場したものの、XCode13より廃止となりTask{}キーワードに変更された
- asyncDetached{}も同様に廃止となり、Task.detached{}に変更された
