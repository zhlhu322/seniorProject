//
//  ContentView.swift
//  01
//
//  Created by 李恩亞 on 2025/4/5.
//

import SwiftUI

struct IntroView: View {
    var body: some View {
        NavigationView{
            VStack {
                Text("肌胸肉健身").foregroundColor(Color("AccentColor"))
                    .font(.system(size: 48, weight: .regular, design: .default))
                    .padding(.bottom,5)
                Text("呱呱 一起來運動！")
                    .foregroundStyle(Color("DarkBackgroundColor"))
                    .frame(width: 160, height:30)
                    //.border(Color("DarkBackgroundColor"), width: 1)

                
                Image("chicken")
                    .resizable().scaledToFit()
                    .frame(width: 250)
                NavigationLink(destination: Workout_page()){
                    Text("登入")
                        .font(.title3)
                    
                }
                .frame(width: 300, height: 60)
                .background(Color("AccentColor"))
                .cornerRadius(20)
                .foregroundColor(.white)
                .padding(.bottom,5)
                
                Text("或註冊帳號").font(.footnote).underline(true).foregroundStyle(Color("DarkBackgroundColor"))

            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color("Mint"))
        }
        
    }
    
}

#Preview {
    IntroView()
}
