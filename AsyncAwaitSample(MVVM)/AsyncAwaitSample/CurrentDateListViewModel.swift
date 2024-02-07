//
//  CurrentDateListViewModel.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/02/13.
//

import Foundation

///コンテンツビュー画面で発生するすべてのことを表すビューモデル
class CurrentDateListViewModel: ObservableObject {
    // 現在の日付のリストを保持するプロパティ
    @Published var currentDates: [CurrentDateViewModel] = []
    
    // すべての日付を取得する関数
    func populateDates() async {
        do {
            // Webserviceを使って現在の日付を非同期に取得
            let currentDate = try await Webservice().getDate()
            //この日付をビューに送信ために、CurrentDateViewModelに変換する
            if let currentDate = currentDate{
                let currentDateViewModel = CurrentDateViewModel(currentDate: currentDate)
                
                ///currentDatesはPublishedでラップされているので、変更を加える時はメインキューで
                DispatchQueue.main.async {
                    //クロージャ内なのでselfを付ける
                    self.currentDates.append(currentDateViewModel)
                    print(self.currentDates)
                }
            }
            
        } catch {
            // エラーが発生した場合はコンソールに出力
            print(error)
        }
    }
}

///画面に表示される各現在の日付
struct CurrentDateViewModel{
    let currentDate: CurrentDate
    
    var id: UUID{
        currentDate.id
    }
    
    var date: String{
        currentDate.date
    }
}
