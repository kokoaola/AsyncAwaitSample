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
        //URLが間違っていない場合は非同期でセッション開始
        //エラーが生じる可能性があるでthrowsとtryをつけている
        //URLSessionはすでにasyncとawaitが備わっている
        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try? JSONDecoder().decode(CurrentDate.self, from: data)
        //nilとなる可能性があるためtry?をつける
        return decoded
    }
}
