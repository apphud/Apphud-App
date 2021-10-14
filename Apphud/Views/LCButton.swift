//
//  LCButton.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import SwiftUI

struct LCButton: View {
    var text = "Next"
    var action: (()->()) = {}
    
    var body: some View {
      Button(action: {
        self.action()
      }) {
        HStack {
            Text(text)
                .bold()
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding(.vertical)
                .accentColor(Color.white)
                .background(Color("accentColor"))
                .cornerRadius(10)
            }
        }
    }
}

struct LCButton_Previews: PreviewProvider {
    static var previews: some View {
        LCButton()
    }
}
