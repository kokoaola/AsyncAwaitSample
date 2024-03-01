//
//  ContentView.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/01/15.
//

import SwiftUI


struct ContentView: View {
    
    ///ビューモデルへアクセス
    @StateObject private var randomImageListVM = RandomImageListViewModel()
    
    var body: some View {
        NavigationView {
            ///取得したデータをリスト表示
            ///ViewModelがIdentifiableに準拠しているので、idは不要
            List(randomImageListVM.randomImages) { randomImage in
                
                HStack {
                    ///mapメソッドでUIImageが存在する場合（nilでない場合）にのみ、クロージャ内のコードを実行
                    randomImage.image.map {
                        Image(uiImage: $0)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    Text(randomImage.quote)
                }
                
            }.task {
                await randomImageListVM.getRandomImages(ids: Array(100...120))
            }
            .navigationTitle("Random Images/Quotes")
            .navigationBarItems(trailing: Button(action: {
                ///ここの中身は非構造化タスクで実装
                Task {
                    await randomImageListVM.getRandomImages(ids: Array(100...120))
                }
                
            }, label: {
                Image(systemName: "arrow.clockwise.circle")
            }))
        }
    }
}



struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
