//
//  TodoLise.swift
//  LoanApp
//
//  Created by koala panda on 2024/03/04.
//

import Foundation


//MARK: - 方法２：クラス名を\@MainActorでマーク（方法４でも使用可能、その場合はawait MainActor.runは不要）
//ViewModelの関数名だけを\@MainActorでマークしても、Webserviceのクロージャに入ると、バックグラウンドスレッドに戻ってしまう
//@MainActor

class TodoListViewModel: ObservableObject {
    
    @Published var todos: [TodoViewModel] = []
    
    ///方法４の際は、関数名にasyncが必要になる
    func populateTodos() async {
    //func populateTodos() {
        do {
            //URLを取得
            guard let url = URL(string: "https://jsonplaceholder.typicode.com/todos") else {
                throw NetworkError.badUrl
            }
            
            //MARK: - 方法１：async/awaitを使用せずコールバック関数を使用する場合、DispatchQueue.main.asyncでラップし、メインスレッドで/@Publishedでマークされた変数を更新する
            //            Webservice().getAllTodos(url: url) { result in
            //                switch result{
            //                case .success(let todos):
            //                    DispatchQueue.main.async {
            //                        self.todos = todos.map(TodoViewModel.init)
            //                    }
            //                case .failure(let error):
            //                    print(error)
            //                }
            //            }
            
            
            ///iOS15以降、コールバックを使用せずasync/awaitを使用したケース
            
            //MARK: - 方法２：クラス名を\@MainActorでマークし、TodoListViewModelは自動的にメインスレッドで更新される
            //            Webservice().getAllTodos(url: url) { result in
            //                switch result{
            //                case .success(let todos):
            //                    Task{
            //                        //todo更新をメインスレッドに割り当てる
            //                        await MainActor.run {
            //                            self.todos = todos.map(TodoViewModel.init)
            //                        }
            //                    }
            //                case .failure(let error):
            //                    print(error)
            //                }
            //            }
            
            
            //MARK: - 方法３：WebService.swiftの関数を\@MainActorでマーク&非同期タスク化
            ///非推奨
//            Webservice().getAllTodos(url: url) { result in
//                switch result{
//                case .success(let todos):
//                    self.todos = todos.map(TodoViewModel.init)
//                case .failure(let error):
//                    print(error)
//                }
//            }
            
            
            //MARK: - 方法４：WebService.swiftに新しい非同期関数getAllTodosAsync()を作る
            ///推奨
                let todos = try await Webservice().getAllTodosAsync(url: url)
                ///@Publishedでマークされた変数をメインスレッドで更新(クラス名に@MainActorがあれば、await MainActor.runは不要)
                await MainActor.run {
                    ///データをTodoViewModel型に変換
                    self.todos = todos.map(TodoViewModel.init)
                }
            
            /*
             メモ
             //バックグラウンドスレッドで実行
            Task.detached {
                ///非同期でTodoデータを取得
                print(Thread.isMainThread)
                let todos = try await Webservice().getAllTodosAsync(url: url)
                ///スレッドを切り替えてメインスレッドで更新
                await MainActor.run {
                    print(Thread.isMainThread)
                    ///データをTodoViewModel型に変換
                    self.todos = todos.map(TodoViewModel.init)
                }
            }
            */
            
            
            
        } catch {
            print(error)
        }
    }
}

struct TodoViewModel {
    
    let todo: Todo
    
    var id: Int {
        todo.id
    }
    
    var title: String {
        todo.title
    }
    
    var completed: Bool {
        todo.completed
    }
}
