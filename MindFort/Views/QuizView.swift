//
//  QuizView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-01.
//

import SwiftUI

struct QuizView: View {
    @EnvironmentObject var secretsModel: SecretsViewModel
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct QuizView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            QuizView()
        }
    }
}
