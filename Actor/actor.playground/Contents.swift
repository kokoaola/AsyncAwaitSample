import UIKit

///アクターを使用する条件：同時実行と競合状態を持つ時
//MARK: - 修正前の例（データが競合している）

class CounterClass{
    var value: Int = 0
    
    func increment()->Int{
        value += 1
        return value
    }
}

let counter1 = CounterClass()//インスタンス作成

//タスクを100回同時に繰り返す
DispatchQueue.concurrentPerform(iterations: 100){_ in
    print(counter1.increment())//1加算する
}

/*期待する結果
1
2
3
4...

///実際の結果
//複数のタスクから同時にこの状態にアクセスして変更を加えているため、順番はめちゃくちゃになる
//classをstructにしても結果は同じ
3
19
100
38
47...
 */



//MARK: - アクターを使用して競合状態を解消する
actor CounteActor{
    var value: Int = 0
    
    func increment()->Int{
        value += 1
        return value
    }
}

let counter2 = CounteActor()//インスタンス作成

//タスクを100回同時に繰り返す
//前回の加算の完了をawaitで一時停止しながら非同期で実行していく
//一時停止から解放されると、他のスレッドが介入して値を変更できる
DispatchQueue.concurrentPerform(iterations: 100){_ in
    //タスクでのラップが必要
    Task{
        //メソッドへのアクセスはawaitキーワードを用いて非同期に実行
        //アクターモデルのおかげで、counter2の状態へのアクセスが制御され、競合や不整合なく値がインクリメントされる
        print(await counter2.increment())//1加算する
    }
}

/*結果
 1
 2
 3
 4...
 
 //アクターを使用することで、同時操作を可能にして競合状態をなくせる
 */


