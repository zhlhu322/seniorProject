// filepath: /Users/0322e/Documents/senior project/01/01/Signup/signInView.swift

import SwiftUI
import UIKit

struct signInView: View {
    @Binding var path: [PlanRoute]
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String? = nil
    @State private var isSigningIn: Bool = false

    var body: some View {
        VStack(spacing: 20) {
            Text("登入")
                .font(.largeTitle)
                .foregroundStyle(Color(.darkBackground))
                .padding(.top, 40)

            TextField("電子信箱", text: $email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()
                .background(Color(.background))
                .cornerRadius(8)
                .frame(maxWidth: 350)

            SecureField("密碼", text: $password)
                .padding()
                .background(Color(.background))
                .cornerRadius(8)
                .frame(maxWidth: 350)

            if let error = errorMessage {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 350)
            }

            Button(action: {
                guard !email.isEmpty, !password.isEmpty else {
                    errorMessage = "請填寫電子信箱與密碼"
                    return
                }
                isSigningIn = true
                AuthenticationViewModel.shared.signIn(email: email, password: password) { friendly, message in
                    DispatchQueue.main.async {
                        isSigningIn = false
                        if let friendly = friendly {
                            // 顯示友善錯誤
                            errorMessage = message
                        } else {
                            // 成功登入 -> 導向首頁
                            path.append(.home)
                        }
                    }
                }
            }) {
                Text(isSigningIn ? "登入中..." : "登入")
                    .frame(width: 340, height: 50)
                    .foregroundStyle(Color.white)
                    .background(Color(.primary))
                    .cornerRadius(10)
            }
            .disabled(isSigningIn)

            Button(action: {
                // 回到註冊頁
                path.append(.signUp)
            }) {
                Text("沒有帳號？前往註冊")
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.myMint))
        .overlay(
            // 輕量的 inputAssistant removal
            InputAccessoryCleaner().frame(width: 0, height: 0)
        )
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    signInView(path: .constant([]))
}
