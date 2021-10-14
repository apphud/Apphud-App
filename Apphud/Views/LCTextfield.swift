//
//  LCTextfield.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import SwiftUI

struct LCTextfield: View {
    @Binding var value: String
    
    var placeholder = "Placeholder"
    var icon = Image(systemName: "person.crop.circle")
    var color = Color("offColor")
    var isSecure = false
    var onEditingChanged: ((Bool)->()) = {_ in }
    
    var body: some View {
        HStack {
            if isSecure{
                SecureField(placeholder, text: self.$value, onCommit: {
                    self.onEditingChanged(false)
                }).padding()
                .autocapitalization(.none)
                .disableAutocorrection(true)
            } else {
                TextField(placeholder, text: self.$value, onEditingChanged: { flag in
                    self.onEditingChanged(flag)
                }).padding()
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .disableAutocorrection(true)
            }
            
            icon.imageScale(.large)
                .padding()
                .foregroundColor(color)
        }.background(color).cornerRadius(10.0)
    }
}

struct LCTextfield_Previews: PreviewProvider {
    static var previews: some View {
        LCTextfield(value: .constant(""))
    }
}
