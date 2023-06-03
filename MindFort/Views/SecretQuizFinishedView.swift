//
//  SecretQuizFinishedView.swift
//  MindFort
//
//  Created by Micah R Ledbetter on 2023-06-02.
//

import SwiftUI

struct SecretQuizFinishedView: View {
    @Binding var finished: Bool
    @EnvironmentObject var secretsModel: SecretsViewModel
    
    var successText: String {
        let total = secretsModel.secrets.count
        return "Finished \(total)/\(total) secrets"
    }

    var body: some View {
        VStack {
            RoundedRectangle(cornerRadius: 10)
                .foregroundColor(.green)
                .frame(height: 175)
                .overlay(
                    VStack {
                        Text(successText)
                            .foregroundColor(.white)
                            .padding([.bottom])
                        HackerCodeRawString(rawString: .constant(placeholderString.joined(separator: "")), foregroundColor: .white)
                    }
                )
                .padding()
            Spacer()
        }
        .navigationBarTitle("Success")
    }
}

struct SecretQuizFinishedView_Previews: PreviewProvider {
    static var previews: some View {
        let exampleSecrets = [
            try! Secret(name: "Secure passphrase", value: "password"),
            try! Secret(name: "Bitcoin wallet passphrase", value: "showmethemoney"),
        ]
        let secretsModel = SecretsViewModel(dataLoader: SecretsVmDataLoaderFromArray(exampleSecrets))
        Group {
            NavigationView {
                SecretQuizFinishedView(finished: .constant(true))
                .environmentObject(secretsModel)
            }
        }
    }
}
