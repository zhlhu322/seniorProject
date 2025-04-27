//
//  loginView.swift
//  01
//
//  Created by 李恩亞 on 2025/4/27.
//


import SwiftUI

struct loginView: View {
    
    @State var name:String = ""
    @State var mail:String = ""
    @State var password:String = ""
    
    var body: some View {
        Text("建立帳戶")
            .font(.title)
            .foregroundStyle(Color(.mint))
            .frame(width:500,height:250)
            .background(Color(.darkBackground))
            .padding(.bottom,30)
        
        VStack(spacing:15){
            TextField("姓名",text: $name)
                .padding()
                .frame(width:350,height:60)
                .background(Color(.black.opacity(0.05)))
                .cornerRadius(10)
                
                        
            TextField("姓名",text: $name)
                .padding()
                .frame(width:350,height:60)
                .background(Color(.black.opacity(0.05)))
                .cornerRadius(10)
                    
            TextField("姓名",text: $name)
                .padding()
                .frame(width:350,height:60)
                .background(Color(.black.opacity(0.05)))
                .cornerRadius(10)
        }
        
        
        
        Spacer()
    }
}


#Preview {
    loginView()
}
