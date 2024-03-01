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
    
    ///指定されたIDの画像を非同期に取得し、randomImagesプロパティを更新
    func getRandomImages(ids: [Int]) async {
        do {
            //WebserviceクラスのgetRandomImagesメソッドを呼び出し、画像データを非同期に取得
            let randomImages = try await Webservice().getRandomImages(ids: ids)
            //randomImages型をビューで表示するためにRandomImageViewModelに変換し、randomImages配列に格納
            //MainActorを使用しているので、配列への追加はディスパッチでラップしなくてもメインスレッドで実行される
            self.randomImages = randomImages.map(RandomImageViewModel.init)
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
