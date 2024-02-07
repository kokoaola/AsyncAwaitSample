//
//  ContentView.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/01/15.
//

import SwiftUI


struct ContentView: View {
    @StateObject private var currentDateListVM = CurrentDateListViewModel()
    
    var body: some View {
        NavigationView {
            List(currentDateListVM.currentDates, id: \.id) { currentDate in
                Text("\(currentDate.date)")
            }.listStyle(.plain)
            
                .navigationTitle("Dates")
                .navigationBarItems(trailing: Button(action: {
                    ///更新ボタン押下時に非同期として呼び出す
                    Task{
                        await currentDateListVM.populateDates()
                    }
                }, label: {
                    Image(systemName: "arrow.clockwise.circle")
                }))
            
            ///起動時に処理を実行
                .task{
                    ///非同期関数を呼び出そうとしているため、.taskでラップする
                    ///.taskはasyncクロージャを引数としているため、asyncなしで{}で囲める
                    await currentDateListVM.populateDates()
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

