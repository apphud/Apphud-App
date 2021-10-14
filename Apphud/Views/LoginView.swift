//
//  LoginView.swift
//  Apphud
//
//  Created by Alexander Selivanov on 01.10.2020.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionStore
    @State var email: String = ""
    @State var password: String = ""
    @State private var formOffset: CGFloat = 0
    @State private var showInvalidCredentialsAlert = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Group {
                    Image("Logo").resizable().aspectRatio(contentMode: .fit)
                }.frame(width: 80, height: 80, alignment: .center)
                Text("Apphud").font(.title).bold().foregroundColor((Color(hex: "0085FF")))
                VStack {
                    LCTextfield(value: self.$email, placeholder: "Email", icon: Image(systemName: "at"))
                    LCTextfield(value: self.$password, placeholder: "Password", icon: Image(systemName: "lock"), isSecure: true, onEditingChanged: { flag in
                        withAnimation {
                            self.formOffset = flag ? 10 : 0
                        }
                    })
                    LCButton(text: "Sign in", action: signIn)
                }
                
            }.padding([.leading, .trailing], 15.0).offset(y: self.formOffset).padding(.top, -150)
        }.onTapGesture(count: 1, perform: {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        })
        .alert(isPresented: $showInvalidCredentialsAlert, content: {
            Alert(title: Text("Error"), message: Text("Invalid credentials. Please try again."), dismissButton: .default(Text("OK")))
        })
    }
    
    func signIn() {
        session.login(email: email.lowercased(), password: password) { user, error in
            if error != nil {notifyInvalidCreds()}
        }
    }
    
    func notifyInvalidCreds() {
        showInvalidCredentialsAlert = true
    }
}

struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView()
    }
}
