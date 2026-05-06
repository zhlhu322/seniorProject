//
//  signUpView2.swift
//  01
//
//  Created by 李恩亞 on 2025/5/1.
//

import SwiftUI

struct signUpView2: View {
    @Binding var path: [PlanRoute]
    @EnvironmentObject var tabBarManager: TabBarVisibilityManager
    @State private var isSavingSelection = false
    @State private var errorMessage: String?

    private func saveInitialChickenSelection(roleID: Int, stage: String) {
        guard !isSavingSelection else { return }
        isSavingSelection = true
        errorMessage = nil

        AuthenticationViewModel.shared.updateInitialChickenSelection(roleID: roleID, stage: stage) { error in
            isSavingSelection = false

            if let error {
                errorMessage = error
                return
            }

            path.removeAll()
            tabBarManager.update(isVisible: true)
        }
    }

    
    var body: some View {
            ZStack{
                Color(.myMint).ignoresSafeArea()
                VStack{
                    Text("選擇你的第一隻肌胸肉：")
                        .font(.title3)
                        .foregroundStyle(Color(.accent))
                        .padding(.top,50)
                        .frame(maxWidth:.infinity ,alignment: .leading)
                        .padding(.leading,30)
                    
                    HStack{
                        Button(action: {
                            saveInitialChickenSelection(roleID: 1, stage: "baby")
                        }) {
                            VStack {
                                Image("chicken_baby")
                                    .resizable()
                                    .frame(width:60,height: 80)
                                    .padding(.top,20)
                                Text("寶寶肌胸")
                                    .font(.body)
                                    .foregroundStyle(Color(.darkBackground))
                                    .padding(.top,20)
                            }
                            .frame(width:130,height:200)
                            .padding()
                            .background(Color(.primary))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay{
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.darkBackground),lineWidth: 2)
                            }
                        }
                        
                        Button(action: {
                            saveInitialChickenSelection(roleID: 2, stage: "healthy")
                        }) {
                            VStack {
                                Image("chicken_health")
                                    .resizable()
                                    .frame(width:110,height: 125)
                                    .padding(.top,20)
                                Text("健康肌胸")
                                    .font(.body)
                                    .foregroundStyle(Color(.darkBackground))

                            }
                            .frame(width:130,height:200)
                            .padding()
                            .background(Color(.primary))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay{
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.darkBackground),lineWidth: 2)
                            }
                        }
                    }
                    .padding()
                    
                    HStack{
                        
                        Button(action: {
                            saveInitialChickenSelection(roleID: 3, stage: "thin")
                        }) {
                            VStack {
                                Image("chicken_thin")
                                    .resizable()
                                    .frame(width:110,height: 140)
                                    .padding(.top,20)
                                Text("瘦瘦肌胸")
                                    .font(.body)
                                    .foregroundStyle(Color(.darkBackground))

                            }
                            .frame(width:130,height:200)
                            .padding()
                            .background(Color(.primary))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay{
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.darkBackground),lineWidth: 2)
                            }
                        }
                        
                        Button(action: {
                            saveInitialChickenSelection(roleID: 4, stage: "fat")
                        }) {
                            VStack {
                                Image("chicken_fat")
                                    .resizable()
                                    .frame(width:110,height: 140)
                                    .padding(.top,20)
                                Text("胖胖肌胸")
                                    .font(.body)
                                    .foregroundStyle(Color(.darkBackground))

                            }
                            .frame(width:130,height:200)
                            .padding()
                            .background(Color(.primary))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .overlay{
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color(.darkBackground),lineWidth: 2)
                            }
                        }
                    }
                    
                    Spacer().frame(height:10)

                    if isSavingSelection {
                        ProgressView("請稍等...")
                            .foregroundStyle(Color(.darkBackground))
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                    }
                    
                    HStack{
                        
                        Text("呱呱！我是超壯肌胸！\n如果你從今天起每個禮拜認真運動，總有一天你也會變的跟我一樣壯喔！")
                            .font(.callout)
                            .foregroundStyle(Color(.darkBackground))
                            .padding()
                            .frame(width:220)
                            .overlay{
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundStyle(Color(.darkBackground))
                                
                            }
                        
                        Image("chicken_strong")
                            .resizable()
                            .frame(width:120,height: 140)
                        
                    }
                    .padding(.top,40)
                } //VStack
            } //ZStack
            .navigationBarBackButtonHidden(true)
    }
}

//#Preview {
//    signUpView2(path: .constant([]))
//}
