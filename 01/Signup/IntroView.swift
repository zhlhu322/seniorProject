//
//  ContentView.swift
//  01
//
//  Created by 李恩亞 on 2025/4/5.
//

import SwiftUI
import FirebaseAuth

struct IntroView: View {
    @Binding var path: [PlanRoute]
    
    var body: some View {
        VStack {
            Text("CountBuddy").foregroundColor(Color("AccentColor"))
                .font(.system(size: 48, weight: .regular, design: .default))
                .padding(.bottom,5)
            Text("嗨嗨 一起來運動！")
                .font(.callout)
                .foregroundStyle(Color("DarkBackgroundColor"))
                .frame(width: 170, height:50)
                .overlay(
                    RoundedRectangle(cornerRadius:20)
                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                        .foregroundStyle(Color(.darkBackground))
                ).padding(.leading,60)
            
            Image("chicken_strong")
                .resizable().scaledToFit()
                .frame(width: 250)
            
            // 登入按鈕 - 使用 NavigationLink
            NavigationLink(value: PlanRoute.signIn) {
                Text("登入")
                    .foregroundColor(.white)
                    .frame(width: 340, height: 60)
                    .background(Color("AccentColor"))
                    .cornerRadius(20)
            }
            .padding(.bottom, 5)
            
            // 註冊按鈕 - 使用 NavigationLink
            NavigationLink(value: PlanRoute.signUp) {
                Text("註冊")
                    .foregroundColor(Color("AccentColor"))
                    .frame(width: 340, height: 60)
                    .background(Color.white)
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color("AccentColor"), lineWidth: 2)
                    )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.myMint))
    }
}

#Preview {
    NavigationStack {
        IntroView(path: .constant([]))
    }
}
