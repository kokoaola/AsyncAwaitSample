//
//  RandomImageListViewModel.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/02/27.
//

///ランダムイメージリストで発生するすべてを直接制御するコンテナモデル
///配列とひとつひとつのデータは別のViewModelによって管理される

import UIKit

//メインアクターでメインスレッドでの実行を保証
@MainActor
///データ配列を管理するViewModel
//ObservableObjectで観測可能なオブジェクトに指定する
class RandomImageListViewModel: ObservableObject {
    //@Publishedプロパティラッパーを使用してランダム画像ViewModelの配列を宣言し、UIに変更を通知
    @Published var randomImages: [RandomImageViewModel] = []
    
    //MARK: -
    ///指定されたIDの画像を非同期に取得し、randomImagesプロパティを更新
    ///すべてのダウンロードを完了するのを待つのではなく、完了したものから順に受け取って表示していく
    func getRandomImages(ids: [Int]) async {
        do {
            ///すべてのダウンロードを完了するのを待つ版
            /*
            //WebserviceクラスのgetRandomImagesメソッドを呼び出し、画像データを非同期に取得
            let randomImages = try await Webservice().getRandomImages(ids: ids)
            //randomImages型をビューで表示するためにRandomImageViewModelに変換し、randomImages配列に格納
            //MainActorを使用しているので、配列への追加はディスパッチでラップしなくてもメインスレッドで実行される
            self.randomImages = randomImages.map(RandomImageViewModel.init)*/
            
            ///完了したものから順に受け取って表示していく版
            ///タスクグループ作成
            ///タスクを作る -> returnで結果を渡す -> 結果を非同期シーケンスで処理
            //try awaitとwithThrowingTaskGroupでラップ
            //withThrowingTaskGroup: 複数の非同期タスクをグループ化して実行し、グループ内のすべてのタスクから受け取るエラーをいっぺんにハンドリングする
            //of:で非同期タスクが返す結果の値の型を指定する（何も返さない場合はVoid.self）
            //body:内でタスクグループを作成する
            try await withThrowingTaskGroup(of: (Int, RandomImage).self, body: { group in
                
                let webservice = Webservice()
                ///配列の初期化
                randomImages = []
                
                ///IDをループさせながら、タスクを追加&実行
                //group.addTask {}のクロージャの中身がタスクの本体、ここではasync letで作成した２つの子タスク（getRandomImage）を作成して非同期で実行している
                //データの競合を防ぐため、タスクグループ内から変数を変更はできない。タスクが完了したものからreturnで値を外部に渡す
                for id in ids {
                    group.addTask {
                        return (id, try await webservice.getRandomImage(id: id))
                    }
                }
                
                
                ///非同期シーケンス部分
                ///タスクグループ内のすべての子タスクが完了したものから順に結果を取り出し、一つずつ配列に追加、その都度ビューが更新される
                //処理後は次のタスクが完了するまで待機
                //タスクグループ内の全てのタスクが完了し、それぞれの結果が処理されるまで繰り返す
                for try await (_, randomImage) in group {
                    //受け取った結果をRandomImageViewModel型に変換し、ビューモデルのrandomImages配列に追加
                    randomImages.append(RandomImageViewModel(randomImage: randomImage))
                }
            })
            
            
        } catch {
            //エラーが発生した場合、コンソールにエラーメッセージを出力
            print(error)
        }
    }
}


///ビューに表示させる用の情報を保持するViewModel
struct RandomImageViewModel: Identifiable {
    //Identifiableプロトコルに準拠するための一意識別子
    let id = UUID()
    //RandomImageインスタンスを保持
    fileprivate let randomImage: RandomImage
    
    ///Data型からUIImageデータに変換
    var image: UIImage? {
        //randomImageプロパティから画像データをUIImageに変換して返す
        UIImage(data: randomImage.image)
    }
    
    ///引用テキストを取得する
    var quote: String {
        //randomImageプロパティから引用テキストを返す
        randomImage.quote.content
    }
}
