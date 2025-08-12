//
//  Workout page.swift
//  01
//
//  Created by 李恩亞 on 2025/4/6.
//

import SwiftUI


struct Workout_page: View {
    @State private var times = 1
    var body: some View {
        VStack{
            HStack{
                Image(systemName: "xmark")
                    .font(.system(size: 25, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("2/3")
                    .foregroundColor(Color(.white))
                    .frame(maxWidth: .infinity, alignment: .center)
                Image(systemName: "pause")
                    .font(.system(size: 25, weight: .black))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal,20)
            
            Spacer()
            VStack {
                Text("次數:\(times)").foregroundColor(Color(.white))
                    .font(.system(size: 20))
                Button(action:
                        {times+=1}
                ){
                    Image("Image1").resizable().frame(width:260,height:260)
                }
                Text("手臂彎舉").foregroundColor(Color(.white))
                    .font(.system(size: 32))
            }
            .padding(.bottom,80)
            
            Image("Image2").resizable().scaledToFit().frame(height:140)
            
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color("PrimaryColor"))
        .onTapGesture {
            times += 1 // 點整個畫面都可以增加
        }
    }
    
}

#Preview {
    Workout_page()
}
