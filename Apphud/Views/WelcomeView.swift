//
//  WelcomeView.swift
//  Apphud
//
//  Created by Валерий Левшин on 21.06.2021.
//

import SwiftUI

struct WelcomeView: View {
    
    @State private var formOffset: CGFloat = 0
    @State var pushActive = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Group {
                    Image("welcome-logo").resizable().aspectRatio(contentMode: .fill)
                }.frame(width: UIScreen.screenWidth/1.3, height: UIScreen.screenWidth/1.3, alignment: .center)
                
                VStack(alignment: .trailing, spacing: 0) {
                  Text("In-app subscriptions infrastructure you can rely on").font(.title).bold()
                    .lineLimit(4).minimumScaleFactor(0.1)
                }.frame(width: UIScreen.screenWidth - 40, alignment: .leading)
    
                VStack(alignment: .trailing, spacing: 0) {
                  Text("Apphud provides real-time data and tools to increase revenue.")
                    .lineLimit(4).minimumScaleFactor(0.1)
                }.frame(width: UIScreen.screenWidth - 40, alignment: .leading)
                
                Spacer()
                VStack(alignment: .center, spacing: 5) {
                    LCButton(text: "Let’s go", action: showLogin)
                }.frame(width: UIScreen.screenWidth - 40, alignment: .bottom)
                
                NavigationLink(destination:
                   LoginView().navigationBarBackButtonHidden(true),
                   isActive: self.$pushActive) {
                     EmptyView()
                }.hidden()
            
            }.padding().offset(y: self.formOffset)
        }
    }
    
    func showLogin() {
        self.pushActive = true
    }
}

extension UIScreen{
   static let screenWidth = UIScreen.main.bounds.size.width
   static let screenHeight = UIScreen.main.bounds.size.height
   static let screenSize = UIScreen.main.bounds.size
}

struct WelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        WelcomeView()
            .previewDevice("iPhone 11")
            
    }
}
