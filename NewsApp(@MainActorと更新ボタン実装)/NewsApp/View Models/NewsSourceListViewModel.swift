//
//  NewsSourceListViewModel.swift
//  NewsApp
//
//  Created by Mohammad Azam on 6/30/21.
//

import Foundation
// MARK: -
///@MainActorを使用するとクラスのすべてのプロパティとすべての関数は、メインスレッドを使用する
/// DispatchQueue.main.async {に関するコードを削減できる

@MainActor
class NewsSourceListViewModel: ObservableObject {
    
    @Published var newsSources: [NewsSourceViewModel] = []
    
    func getSources() async {
        ///コールバック関数は削除
        /*
         Webservice().fetchSources(url: Constants.Urls.sources) { result in
         switch result {
         case .success(let newsSources):
         DispatchQueue.main.async {
         self.newsSources = newsSources.map(NewsSourceViewModel.init)
         }
         case .failure(let error):
         print(error)
         }
         }*/
        
        ///awaitに書き換え
        //do-catchとtryでエラーをキャッチする
        do{
            //awaitキーワードをつけて結果を待つ
            let newsSources = try await Webservice().fetchSources(url: Constants.Urls.sources)
            
            ///@MainActorを使用することでディスパッチに関するコードが不要になる
            self.newsSources = newsSources.map(NewsSourceViewModel.init)
            /*DispatchQueue.main.async {
             self.newsSources = newsSources.map(NewsSourceViewModel.init)
             }*/
        }catch{
            print(error)
        }
    }
    
}

struct NewsSourceViewModel {
    
    fileprivate var newsSource: NewsSource
    
    var id: String {
        newsSource.id
    }
    
    var name: String {
        newsSource.name
    }
    
    var description: String {
        newsSource.description
    }
    
    static var `default`: NewsSourceViewModel {
        let newsSource = NewsSource(id: "abc-news", name: "ABC News", description: "This is ABC news")
        return NewsSourceViewModel(newsSource: newsSource)
    }
}
