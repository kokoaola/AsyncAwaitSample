//MARK: - 銀行口座を使用した例
///ほぼ同時に引き出す処理が発生すると、ディスパッチキューの同時実行により残高がマイナスになってしまう
import UIKit

///銀行口座クラス
class BankAccount {
    
        //口座の残高を格納する変数
        var balance: Double
        
        //初期化メソッドで渡した残高をプロパティに割り当てる
        init(balance: Double) {
            self.balance = balance
        }
        
    
    //指定された金額を口座から引き出すメソッド
    func withdraw(_ amount: Double) {
        //残高が引き出し額以上の場合のみ引き出しを実行
        if balance >= amount {
            //引き出し処理の模擬的な時間をランダムに設定
            let processingTime = UInt32.random(in: 0...3)
            
            //引き出し処理中のメッセージを表示
            print("[Withdraw] Processing for \(amount) \(processingTime) seconds")
            
            //指定された秒数処理を待機
            sleep(processingTime)
            
            //口座から指定額を引き出し
            print("Withdrawing \(amount) from account(Balance is \(balance))")
            balance -= amount
            
            //新しい残高を表示
            print("Balance is \(balance)")
        }
    }
}

///普通に引き出す挙動
/*
//銀行口座インスタンスを作成し、初期残高を500として設定
let bankAccount1 = BankAccount(balance: 500)
//300引き出す
bankAccount1.withdraw(300)
//残高は200
print(bankAccount1.balance)
 */


////同時に2つ引き出す挙動（ディスパッチキューを作成）
////銀行口座インスタンスを作成し、初期残高を500として設定
//let bankAccount2 = BankAccount(balance: 500)
////並行処理を行うためのキューを作成
//let queue = DispatchQueue(label: "ConcurrentQueue", attributes: .concurrent)
//
////非同期に300を引き出す処理をキューに追加
//queue.async {
//    bankAccount2.withdraw(300)
//}
//
////非同期にさらに500を引き出す処理をキューに追加
//queue.async {
//    bankAccount2.withdraw(500)
//}

///結果
/*
 //if balance >= amount は両方ともクリア
 [Withdraw] Processing for 300.0 3 seconds
 [Withdraw] Processing for 500.0 0 seconds
 
 //処理時間の経過が早く終わった方から引き出し
 Withdrawing 500.0 from account
 //残高が０になる
 Balance is 0.0
 
 //最初に観測した残高で引き出し処理を行っている
 Withdrawing 300.0 from account
 //残高がマイナスになっている
 Balance is -300.0
 
 ///残高確認後に待機をしているため、残高がマイナスになってしまう
 */


////MARK: - 解決策１：シングルキューを作成
////銀行口座インスタンスを作成し、初期残高を500として設定
//let bankAccount3 = BankAccount(balance: 500)
////シリアルキューを作成（シリアルキューはデフォルトなので、指定は不要）
//let queue3 = DispatchQueue(label: "SerialQueue")
//
////非同期に300を引き出す処理をキューに追加
////最初に実行されるトランザクション
//queue3.async {
//    bankAccount3.withdraw(300)
//}
//
////非同期にさらに500を引き出す処理をキューに追加
////２番目に実行されるトランザクション
//queue3.async {
//    bankAccount3.withdraw(500)
//}

///結果
/*
 //１つめのトランザクションはif balance >= amount をクリア
 [Withdraw] Processing for 300.0 2 seconds
 //引き出される
 Withdrawing 300.0 from account(Balance is 500.0)
 Balance is 200.0
 
 //２つめのトランザクションはif balance >= amount を満たさないため、実行されない
 */


//MARK: - 解決策２：コードをロックして他のスレッドがアクセスできないようにする
///銀行口座クラス
class BankAccount2 {
    ///ロックを作成
    var lock = NSLock()
    var balance: Double
    
    init(balance: Double) {
        self.balance = balance
    }
    
    //指定された金額を口座から引き出すメソッド
    func withdraw(_ amount: Double) {
        ///ロックを実行して他のスレッドがアクセスできないようにする
        lock.lock()
        if balance >= amount {
            ///このスコープ内に入ることができるスレッドは1つだけ
            let processingTime = UInt32.random(in: 0...3)
            print("[Withdraw] Processing for \(amount) \(processingTime) seconds")
            sleep(processingTime)
            print("Withdrawing \(amount) from account(Balance is \(balance))")
            balance -= amount
            print("Balance is \(balance)")
        }
        ///解除を忘れると、誰もアクセスできなくなるので注意
        ///長時間ロックするのもNG
        lock.unlock()
    }
}


//銀行口座インスタンスを作成し、初期残高を500として設定
let bankAccount4 = BankAccount2(balance: 500)
//並行処理を行うためのキューを作成
let queue = DispatchQueue(label: "ConcurrentQueue", attributes: .concurrent)

//非同期に300を引き出す処理をキューに追加
queue.async {
    bankAccount4.withdraw(300)
}

//非同期にさらに500を引き出す処理をキューに追加
queue.async {
    bankAccount4.withdraw(500)
}

///結果
/*
 //１つめのトランザクションはif balance >= amount をクリア
 //ロックがかかっているので、２つめのトランザクションはアクセスできない
 [Withdraw] Processing for 300.0 0 seconds
 Withdrawing 300.0 from account(Balance is 500.0)
 Balance is 200.0
 
 //２つめのトランザクションがアクセス
 //if balance >= amount を満たさないため、実行されない
 */



//MARK: - 解決策３:アクター使用した例
///銀行口座クラスをアクターに変更
///アクターを使用する条件：同時実行と競合状態を持つ時
actor BankAccountActor {
    
    //口座の残高を格納する変数
    var balance: Double
    
    //初期化メソッドで渡した残高をプロパティに割り当てる
    init(balance: Double) {
        self.balance = balance
    }
    
    
    //指定された金額を口座から引き出すメソッド
    func withdraw(_ amount: Double) {
        //残高が引き出し額以上の場合のみ引き出しを実行
        if balance >= amount {
            //引き出し処理の模擬的な時間をランダムに設定
            let processingTime = UInt32.random(in: 0...3)
            
            //引き出し処理中のメッセージを表示
            print("[Withdraw] Processing for \(amount) \(processingTime) seconds")
            
            //指定された秒数処理を待機
            sleep(processingTime)
            
            //口座から指定額を引き出し
            print("Withdrawing \(amount) from account(Balance is \(balance))")
            balance -= amount
            
            //新しい残高を表示
            print("Balance is \(balance)")
        }
    }
}



//銀行口座インスタンスを作成し、初期残高を500として設定
let bankAccount5 = BankAccountActor(balance: 500)
//並行処理を行うためのキューを作成
let queue = DispatchQueue(label: "ConcurrentQueue", attributes: .concurrent)

//非同期に300を引き出す処理をキューに追加
queue.async {
    Task{
        //awaitを使用することで、関数の呼び出し中は一時停止し、このコードに他のスレッドはアクセスできない
        await bankAccount5.withdraw(300)
    }
}

//非同期にさらに500を引き出す処理をキューに追加
queue.async {
    Task{
        await bankAccount5.withdraw(500)
    }
}


/////結果
///*
// //１つめのトランザクションはif balance >= amount をクリア
// //ロックがかかっているので、２つめのトランザクションはアクセスできない
// [Withdraw] Processing for 300.0 0 seconds
// Withdrawing 300.0 from account(Balance is 500.0)
// Balance is 200.0
//
// //２つめのトランザクションがアクセス
// //if balance >= amount を満たさないため、実行されない
// */
