//
//  LoaderView.swift
//  Apphud
//
//  Created by Alexander Selivanov on 02.10.2020.
//

import SwiftUI

struct LoaderView: View {
    var body: some View {
        ProgressView().progressViewStyle(CircularProgressViewStyle()).frame(width: 32, height: 32, alignment: .center)
    }
}

struct LoaderView_Previews: PreviewProvider {
    static var previews: some View {
        LoaderView()
    }
}
