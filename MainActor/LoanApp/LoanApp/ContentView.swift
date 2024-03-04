//
//  ContentView.swift
//  LoanApp
//
//  Created by koala panda on 2024/03/01.
//

import SwiftUI


struct ContentView: View {
    
    @StateObject private var todoListVM = TodoListViewModel()
    
    var body: some View {
        List(todoListVM.todos, id: \.id) { todo in
            Text(todo.title)
        }
        
        .task {
            ///populateTodos関数は非同期関数のため、非同期クロージャにする必要があるので.onAppearではなく.taskが必要
            await todoListVM.populateTodos()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

