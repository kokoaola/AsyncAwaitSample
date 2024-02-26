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
#### 同期処理
- 同期処理では、ある処理が完了するまでプログラムの実行がその場で停止する。この間、プログラムは他の作業を行うことができず、処理が完了するまで次の行に進むことができない
#### 非同期処理とawait
- 非同期処理では、awaitで非同期タスクの完了を待つ
- 同期処理との違いは、プログラムの実行そのものはブロックされないため、非同期タスクが完了するのを待つ間に、プログラムは他のタスクを実行することができる
- 非同期タスクが完了すると、プログラムの実行はawaitの次の行から再開される
#### async/await
- asyncキーワードは、関数が非同期処理を行うことを示す
- asyncキーワードを持つ関数内で非同期処理を待つ場合、awaitキーワードを使用する

```Swift
///asyncをつける
    private func getDate() async -> CurrentDate?{
        //URLをアンラップ
        guard let url = URL(string: "https://.....")else{
            fatalError("URL is incorrect!")
        }
        //非同期でセッション開始        
        //awaitで非同期処理を待つ
        //throws：関数がエラーを投げる可能性があることを示す。この関数を呼び出す際は、tryキーワードを使ってエラーハンドリングを行う
        try await URLSession.shared.data(from: url)
    }
```
- URLSessionなどのAPIはすでにasyncとawaitが備わって作られている


## Continuationとは
- Continuationとは、従来のコールバックベースの非同期API等の処理を、async/await構文で扱えるようにするための機能のこと
- アクセスできないサードパーティの関数に対してもasync/awaitに変換できて便利

#### コールバックベースの非同期関数
```Swift
//Postの配列を非同期で取得するコールバックでの非同期処理
//非同期処理を実行し、完了したらcompletionハンドラを呼び出す
func fetchPosts(completion: ([Post]) -> Void){
    //データの取得の処理
    completion(posts)//データを返すコンプリーションハンドラを呼び出す
}

//使う時
fetchPosts { posts in
    //戻り値postsを使った処理(UIの更新等)をここに記述
    DispatchQueue.main.async {
        self.tableView.reloadData()
    }
}

```

#### async/awaitパターンでラップして使用する関数
```Swift
// Postの配列を非同期で取得する関数
func getPosts() async -> [Post] {
    //withCheckedThrowingContinuationは非同期処理が成功した場合に結果を返すか、失敗した場合にエラーを投げる
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


## 同時実行性とは
- 同時実行性とは、複数の操作が並行して実行されることを可能にする特製のこと
- async/await構文による非同期プログラミングで実現できる
- 同時タスクを実行できる async let 
- グループに基づいて複数の子タスクを実行できるTask Group
- Unstructured Tasks
- Detached Tasks

### ２つタスクを同時に実行するサンプル
- データの取得処理は、複数ある場合通常上から順に実行されるが、順番を待たずに非同期で同時実行したいというパターン
#### 元のコード
```Swift
    let (equifaxData, _) = try await URLSession.shared.data(from: equifaxUrl)
    
    let (experianData, _) = try await URLSession.shared.data(from: experianUrl)
```

#### 同時実行に変更したコード
```Swift  
    //async letを使用することで、複数の非同期処理を同時に開始し、後でその結果をawaitで取得できる
    async let (equifaxData, _) = URLSession.shared.data(from: equifaxUrl)

    async let (experianData, _) =  URLSession.shared.data(from: experianUrl)

    //URLSessionの呼び出しによって開始された非同期のネットワークリクエストの完了をawaitで待つ
    let equifaxCreditScore = try? JSONDecoder().decode(CreditScore.self, from: try await equifaxData)
    
    let experianCreditScore = try? JSONDecoder().decode(CreditScore.self, from: try await experianData)

```

### ループで実行
```Swift
///WebAPIタスクを２つ同時実行する関数
func getAPR(userId: Int) async throws -> Double {
    
    //１つめのWebAPIの処理....
    //２つめのWebAPIの処理....

    return [...]
}


///ループで使用するとき
let ids = [1,2,3,4,5]//処理対象のユーザーID群
//id1のタスクは２つの非同期処理が完了した時点で初めてコンプリートされ、id2のタスクにすすむ
//非同期処理が10個貯まるわけではないことに注意
Task {
    for id in ids {
        try Task.checkCancellation()
        let apr = try await getAPR(userId: id)
        print(id, apr)
    }
}

```



タスクグループで実行
#### タスクグループとは：
- 複数の非同期タスクを並列に実行し、全てのタスクが完了するまで待つこと。グループのタスクが実行中であっても新たなタスクを追加することができる。タスクグループ内で発生したエラーは、グループの外で一括して捕捉し、処理する。
- 上のループの方法だと、２つの非同期処理を持つタスクが１件ずつ逐次的に実行されるが、タスクグループは２つの非同期処理を持つ５つのタスクを全てを作成して並列で実行し、結果を集約する
- 動的データがあり、同時タスクの数が実際にはわからない場合などに使われる。

```Swift

//処理対象のユーザーID群
//動的な配列であると仮定
let ids = [1,2,3,4,5] 


func getAPRForAllUsers(ids: [Int]) async throws -> [Int: Double] {
    //各ユーザーIDとAPRの取得結果を格納する辞書
    var userAPR: [Int: Double] = [:]
    
    //try awaitとwithThrowingTaskGroupでラップ
    //withThrowingTaskGroup: 複数の非同期タスクをグループ化して実行し、タスクから投げられる可能性のあるエラーを扱う。グループ内のタスクが投げるエラーは一箇所でハンドリングする
    //of:で非同期タスクが返す値の型を指定し、body内でタスクグループを作成する
    try await withThrowingTaskGroup(of: (Int, Double).self, body: { group in
        
        //IDをループさせながら、タスクを追加する
        //タスクグループ内の各タスクが非同期に実行され、それぞれが(id, apr)形式のタプルを返す処理
        for id in ids {
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

Task {
    let userAPRs = try await getAPRForAllUsers(ids: ids)
    print(userAPRs)
}


```


タスクの処理のキャンセル
- Task.checkCancellation()を使用すると、asyncの関数で条件を満たした時、エラーを投げて非同期タスクをキャンセルできる
- .checkCancellation：非同期タスクがキャンセルされたかどうかをチェックする関数

```Swift  

///ユーザーIDを渡すと、非同期でAPRを取得する関数
func getAPR(userId: Int) async throws -> Double {
    
    //IDが２の時はエラー
    if userId == 2 {
        throw NetworkError.invalidId
    }
    
    //１つめのWebAPIの処理....
    //２つめのWebAPIの処理....

    return [...]
}


let ids = [1,2,3,4,5] //処理対象のユーザーID群
var invalidIds: [Int] = [] //無効なIDを格納する配列

Task {
    for id in ids {
        do {
            //非同期タスクが実際に開始される前に、checkCancellationでタスクがキャンセルされていないかを確認する
            //キャンセルされていればCancellationErrorを投げタスクを即座に終了させ、エラーハンドリングのcatchブロックに処理が移る
            try Task.checkCancellation()
            //指定したユーザーIDでAPRを非同期に取得
            let apr = try await getAPR(userId: id)
            //取得したAPRを出力
            print(apr)
        } catch {
            //エラーが発生した場合はエラーを出力し、該当するユーザーIDはinvalidIds配列に追加
            print(error)
            invalidIds.append(id)
        }
    }
    //無効なIDのリストを出力
    print(invalidIds)
}


```

## Structured Task（構造化タスク）とUnstructured Task（非構造化タスク）
### Structured Task（構造化タスク）
- 非同期タスクがライフサイクルを持ち、親タスクの実行スコープ内にネストされる処理のこと。（2_APRSample_asynclet.playgroundの例でタスクグループ）
- 親タスクは、その子タスクが完了するまで終了しないため、非同期タスクの開始と終了が明確に管理され、タスク間の依存関係が容易に把握でき、リソースのリークや競合状態を防ぐことができる。
- 特徴:
    - タスクのライフサイクルが親のスコープに紐づいている。
    - 子タスクの完了が保証され、親タスクの完了前に全ての子タスクが終了する。
    - エラーハンドリングがスコープベースで行われ、エラーを効果的に捕捉・処理できる。

### Unstructured Task（非構造化タスク）
- タスク間の明確な階層関係やライフサイクル管理を行わないアプローチのこと。タスクは独立して開始され、プログラマが明示的に管理しなければならない。非同期タスクが親のライフサイクルとは無関係に終了することがあり、リソースのリークやデータの競合などの問題が発生しやすくなる。
非同期コンテキストにいないが、非同期関数を呼び出したい時時に使用する。（非同期コンテキストとはTask{}の中）
- 特徴:
    - タスク間の依存関係やライフサイクルが明確に管理されない。
    - タスクの管理がプログラマに委ねられるため、複雑なプログラムではバグの原因となりやすい。
    - リソースのリークや競合状態を防ぐために、プログラマが追加の努力を要する。

```Swift
//非構造化タスクの例
private func getData() async{
    ....
}

...

Button{
    //Task{}の中は非同期コンテキストのため、awaitを使って関数を呼び出せる
    //ButtonがタップされたときにTask.initを用いてgetData()関数を非同期に実行する新しいタスクを生成しているが、このタスクはButtonのUIイベントやその他のコードフローとは独立して存在している。そのため、getData()の実行中に親のUIコンポーネントが破棄された場合でも、getData()の処理はそのまま続行される。＝非構造化タスク
    Task.init{
        await getData()
    }
}
```

### 非構造化タスクであるDetachedTask
#### DetachedTaskとは
- Swiftの並行処理フレームワークの一部で、新しい非構造化タスクを作成し、それを現在の実行コンテキストや他のタスクから独立して実行するための関数
- 関数を使用した非同期作業は、親タスクのライフサイクルやキャンセルポリシーから「デタッチされた」（分離された）状態で実行される
#### 使用にあたっての注意
- AppleはDetachedTaskを使用して非構造化並行処理を行うことは推奨していない(async/letを使用すべきとしている)
- 理由：Task.detachedを使用すると、新しいトップレベルのタスクが作成され、現在の実行コンテキストや親タスクから独立して実行されるため。エラーハンドリングの複雑化、親タスクが完了しても非構造化タスクが生き続けることによるメモリリーク、コードの可読性と保守性の低下など
- SampleはDetachtask.playground


## async let、同時実行性のまとめ
- async letを使用すると非同期タスクを作成できる。async let構文は、基本的に非同期処理で変数を作成する
### 基本的な構造化タスク
- 親タスクはTaskで作成する。親タスクは、async let構文の子タスクをいくつか持つ。子タスクは同時に実行され、子タスクの処理が全て終了すると、親タスクが完了となる。
```
     / Child Task(async let)
Task 
     \ Child Task(async let)
```


### タスクグループ
- 動的なデータやタスクの数が事前にわからない場合には、タスクグループを使用すると良い
- １つのグループに子タスクを自由に設定できる。グループはグループ構文を使用する
- ２つの非同期処理（子タスク）を持つ2つのタスクからなる１つのタスクグループを作成。並列で子タスクを実行し、結果を集約する
```
                  / Child Task(async let)
     / Task Group 
                  \ Child Task(async let)
Task
                  / Child Task(async let)
     \ Task Group
                  \ Child Task(async let)...
```


## メモ
- iOS15からasync{}キーワードが登場したものの、XCode13より廃止となりTask{}キーワードに変更された
- asyncDetached{}も同様に廃止となり、Task.detached{}に変更された


