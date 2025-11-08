// Swift
// signUpView.swift

import SwiftUI
import UIKit

// 小的 UIViewControllerRepresentable，用來在該畫面上移除系統的 input assistant（quick bar），減少鍵盤相關約束警告
struct InputAccessoryCleaner: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .clear
        // 清空 inputAssistantItem 的按鈕群組
        vc.inputAssistantItem.leadingBarButtonGroups = []
        vc.inputAssistantItem.trailingBarButtonGroups = []
        return vc
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}

struct signUpView: View {
    @Binding var path: [PlanRoute]
    
    @State private var name: String = ""
    @State private var mail: String = ""
    @State private var password: String = ""
    @State private var errorMessage: String?
    @State private var isRegistered = false
    @State private var showEmailUsedAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                Color(.darkBackground)
                    .ignoresSafeArea(edges: .top)
                
                Text("建立帳戶")
                    .font(.largeTitle)
                    .foregroundStyle(Color(.myMint))
                    .padding(.bottom, 25)
                    .padding(.horizontal, 30)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .padding(.bottom, -10)
            
            VStack(spacing: 15) {
                HStack(spacing: 15) {
                    Image(systemName: "person.circle.fill")
                        .foregroundStyle(Color(.darkBackground).opacity(0.5))
                        .frame(width: 20)
                    TextField("姓名", text: $name)
                        .foregroundStyle(Color(.darkBackground).opacity(0.5))
                }
                .padding()
                .frame(width: 350, height: 60)
                .background(Color(.background))
                .cornerRadius(10)
                
                HStack(spacing: 15) {
                    Image(systemName: "envelope.fill")
                        .foregroundStyle(Color(.darkBackground).opacity(0.5))
                        .frame(width: 20)
                    TextField("電子信箱", text: $mail)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                .padding()
                .frame(width: 350, height: 60)
                .background(Color(.background))
                .cornerRadius(10)
                
                HStack(spacing: 15) {
                    Image(systemName: "key.fill")
                        .foregroundStyle(Color(.darkBackground).opacity(0.5))
                        .frame(width: 20)
                    SecureField("密碼", text: $password)
                }
                .padding()
                .frame(width: 350, height: 60)
                .background(Color(.background))
                .cornerRadius(10)
                
                if let error = errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                Button(action: {
                    // simple validation
                    guard !name.isEmpty, !mail.isEmpty, !password.isEmpty else {
                        errorMessage = "請填寫所有欄位"
                        return
                    }
                    
                    AuthenticationViewModel.shared.createUser(name: name, email: mail, password: password) { friendly, message in
                        DispatchQueue.main.async {
                            if let friendly = friendly {
                                switch friendly {
                                case .emailAlreadyInUse:
                                    // 顯示提示並導向登入頁（或 IntroView）
                                    showEmailUsedAlert = true
                                    errorMessage = message
                                default:
                                    errorMessage = message
                                }
                            } else {
                                // 成功
                                isRegistered = true
                                path.append(.signUp2)
                            }
                        }
                    }
                }) {
                    Text("註冊")
                        .frame(width: 340, height: 60)
                        .foregroundStyle(Color.white)
                        .background(Color(.primary))
                        .cornerRadius(20)
                        .padding(.top, 50)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                }
                
                // ✅ 加入「已有帳號？前往登入」連結
                HStack(spacing: 5) {
                    Text("已有帳號？")
                        .font(.caption)
                        .foregroundColor(Color(.darkBackground).opacity(0.7))
                    
                    Button(action: {
                        path.append(.signIn)
                    }) {
                        Text("前往登入")
                            .font(.caption)
                            .foregroundColor(Color(.primary))
                            .underline()
                    }
                }
                .padding(.top, 10)
                
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.top, 50)
            .background(Color(.myMint))
        }
        .navigationBarBackButtonHidden(true)
        .overlay(
            // 放一個不可見的 UIViewController 以清空 inputAssistantItem，減少鍵盤快捷列造成的 Auto Layout 警告
            InputAccessoryCleaner().frame(width: 0, height: 0)
        )
        .alert(isPresented: $showEmailUsedAlert) {
            Alert(
                title: Text("此電子信箱已註冊"),
                message: Text("您可以直接登入，或使用忘記密碼來重設。是否要前往登入？"),
                primaryButton: .default(Text("前往登入"), action: {
                    // 導向登入路由
                    path.append(.signIn)
                }),
                secondaryButton: .cancel(Text("稍後"))
            )
        }
    }
}

#Preview {
    signUpView(path: .constant([]))
}
