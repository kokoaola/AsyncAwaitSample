//
//  Webservice.swift
//  LoanApp
//
//  Created by koala panda on 2024/03/04.
//

import Foundation


enum NetworkError: Error {
    case badUrl
    case decodingError
    case badRequest
}

class Webservice {

    func getAllTodos(url: URL, completion: @escaping (Result<[Todo], NetworkError>) -> Void) {

        URLSession.shared.dataTask(with: url) { data, _, error in
            guard let data = data, error == nil else {
                completion(.failure(.badRequest))
                return
            }

            guard let todos = try? JSONDecoder().decode([Todo].self, from: data) else {
                completion(.failure(.decodingError))
                return
            }
            completion(.success(todos))
        }.resume()
    }
    
    //MARK: - 方法３：WebService.swiftの関数だけを変更（\@MainActorでマーク&非同期タスク化）
    //非推奨
//    func getAllTodos(url: URL, completion: @MainActor @escaping (Result<[Todo], NetworkError>) -> Void) {
//
//        URLSession.shared.dataTask(with: url) { data, _, error in
//
//            guard let data = data, error == nil else {
//                Task{
//                    await completion(.failure(.badRequest))
//                }
//                return
//            }
//
//            guard let todos = try? JSONDecoder().decode([Todo].self, from: data) else {
//                Task{
//                await completion(.failure(.decodingError))
//                }
//                return
//            }
//
//            Task{
//                await completion(.success(todos))
//            }
//        }.resume()
//    }
    
    //MARK: - 方法４：WebService.swiftに新しい非同期関数getAllTodosAsync()を作る
    //実際に追加する時は、関数名にAsyncは不要（わかりやすく入れているだけ）
    func getAllTodosAsync(url: URL) async throws -> [Todo] {
        ///URLSessionはasync関数のため、awaitが必要
        let (data, _) = try await URLSession.shared.data(from: url)
        
        let todos = try? JSONDecoder().decode([Todo].self, from: data)
        return todos ?? []
        
    }
}
