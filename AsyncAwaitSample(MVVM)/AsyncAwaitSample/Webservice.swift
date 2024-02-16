//
//  Webservice.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/02/13.
//

import Foundation


///Web通信を行うクラス
class Webservice{
    
    func getDate() async throws -> CurrentDate?{
        //Glitchのサーバーから日付を取得
        //URLをアンラップ
        guard let url = URL(string: "https://glorious-neat-antarctopelta.glitch.me/current-date")else{
            fatalError("URL is incorrect!")
        }
        //URLが正しい場合は非同期でセッション開始
        //エラーが生じる可能性がある関数を実行するためtryを使う
        //URLSessionはすでにasyncとawaitが備わっている
        let (data, _) = try await URLSession.shared.data(from: url)
        //エラーが生じる可能性がああり、エラーが発生した時はnilを返す&発生しなかった時はoptional型を返しためtry?をつける
        let decoded = try? JSONDecoder().decode(CurrentDate.self, from: data)
        return decoded
    }
}
