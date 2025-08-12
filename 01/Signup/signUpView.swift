//
//  loginView.swift
//  01
//
//  Created by 李恩亞 on 2025/4/27.
//


import SwiftUI

struct signUpView: View {
    
    @Binding var path: [PlanRoute]
    
    @State var name:String = ""
    @State var mail:String = ""
    @State var password:String = ""
    @State private var errorMessage: String?
    @State private var isRegistered = false
    
    
    var body: some View {
        
            ZStack(alignment: .bottomLeading) {
                Color(.darkBackground).ignoresSafeArea()
                
                Text("建立帳戶")
                    .font(.largeTitle)
                    .foregroundStyle(Color(.mint))
                    .padding(.bottom,25)
                    .padding(.horizontal,30)
            }
            .frame(maxWidth: .infinity)
            .frame(height:200)
            .padding(.bottom,-10)
            
            VStack(spacing:15){
                HStack(spacing:15) {
                    Image(systemName:"person.circle.fill")
                        .foregroundStyle(Color(.darkBackground).opacity(0.5))
                        .frame(width:20)
                    TextField("姓名",text: $name)
                        .foregroundStyle(Color(.darkBackground).opacity(0.5))
                }
                .padding()
                .frame(width:350,height:60)
                .background(Color(.background))
                .cornerRadius(10)
                
                HStack(spacing:15) {
                    Image(systemName:"envelope.fill")
                        .foregroundStyle(Color(.darkBackground).opacity(0.5))
                        .frame(width:20)
                    TextField("電子信箱",text: $mail)
                }
                .padding()
                .frame(width:350,height:60)
                .background(Color(.background))
                .cornerRadius(10)
                
                HStack(spacing:15) {
                    Image(systemName:"key.fill")
                        .foregroundStyle(Color(.darkBackground).opacity(0.5))
                        .frame(width:20)
                    SecureField("密碼",text: $password)
                }
                .padding()
                .frame(width:350,height:60)
                .background(Color(.background))
                .cornerRadius(10)
                
                Button(action: {
                    AuthenticationViewModel.shared.createUser(name: name, email: mail, password: password) { error in
                        if let error = error {
                            errorMessage = error
                        } else {
                            isRegistered = true
                            path.append(.signUp2)
                        }}
                }) {
                    Text("註冊")
                        .frame(width: 340, height: 60)
                        .foregroundStyle(Color.white)
                        .background(Color(.primary))
                        .cornerRadius(20)
                        .padding(.top, 50)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
                Spacer()
            }
            .frame(maxWidth:.infinity,maxHeight:.infinity)
            .padding(.top,50)
            .background(Color(.mint))
            .ignoresSafeArea()
            .navigationBarBackButtonHidden(true)  //可討論要不要有
            }
        
}


#Preview {
    signUpView(path: .constant([]))
}
