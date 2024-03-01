//
//  File.swift
//  AsyncAwaitSample
//
//  Created by koala panda on 2024/02/27.
//

import Foundation

///画像と引用に関する情報を格納するカスタム構造体
struct RandomImage: Decodable {
    let image: Data
    let quote: Quote
}

///引用のカスタム構造体
struct Quote: Decodable {
    let content: String
}
