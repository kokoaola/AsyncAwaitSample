//
//  ContentView.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/01/15.
//

import SwiftUI

///取得したJSONをデコードするための型
struct CurrentDate: Decodable, Identifiable {
    let id = UUID()
    let date: String
    
    private enum CodingKeys: String, CodingKey {
        case date = "date"
    }
}


struct ContentView: View {
    @State private var currentDates: [CurrentDate] = []
    
    var body: some View {
        NavigationView {
            //Identifiable変数を持つため、id: \.selfは不要
            List(currentDates) { currentDate in
                Text("\(currentDate.date)")
            }.listStyle(.plain)
            
                .navigationTitle("Dates")
                .navigationBarItems(trailing: Button(action: {
                    ///更新ボタン押下時に非同期として呼び出す
                    Task{
                        await populateDates()
                    }
                }, label: {
                    Image(systemName: "arrow.clockwise.circle")
                }))
            
            ///起動時に処理を実行
                .task{
                    ///非同期関数を呼び出そうとしているため、.taskでラップする
                    ///.taskはasyncクロージャを引数としているため、asyncなしで{}で囲める
                    await populateDates()
                }
        }
    }
    
    
    private func getDate() async throws -> CurrentDate?{
        //Glitchのサーバーから日付を取得
        //URLをアンラップ
        guard let url = URL(string: "https://glorious-neat-antarctopelta.glitch.me/current-date")else{
            fatalError("URL is incorrect!")
        }
        //URLが間違っていない場合は非同期でセッション開始
        //エラーが生じる可能性がある関数を実行するためtryを使う
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try? JSONDecoder().decode(CurrentDate.self, from: data)
        //エラーが生じる可能性がああり、エラーが発生した時はnilを返す&発生しなかった時はoptional型を返しためtry?をつける
        return decoded
    }
    
    private func populateDates() async{
        do{
            guard let currentDate = try await getDate() else{
                return
            }
            
            self.currentDates.append(currentDate)
        }catch{
            print(error)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

