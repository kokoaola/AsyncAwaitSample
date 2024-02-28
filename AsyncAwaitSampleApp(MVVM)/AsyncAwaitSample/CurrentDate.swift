//
//  CurrentDate.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/02/13.
//

import Foundation

///取得したJSONをデコードするための型
struct CurrentDate: Decodable, Identifiable {
    let id = UUID()
    let date: String
    
    private enum CodingKeys: String, CodingKey {
        case date = "date"
    }
}
