//
//  workoutPlanTypeView.swift
//  01
//
//  Created by 李恩亞 on 2025/5/18.
//

import SwiftUI


struct workoutPlanTypeView: View {
    @Binding var path: [PlanRoute]
    var body: some View {
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()
            VStack {
                Spacer().frame(height:100)
                VStack(spacing:30){
                    Text("請選擇今天的運動計劃：").font(.title2)
                    
                    Button(action: {
                        path.append(.cusPlan)
                    }) {
                        Text("自訂組合")
                            .font(.title2)
                            .foregroundStyle(Color(.black))
                            .frame(width:300,height:120)
                            .background(Color(.primary))
                            .cornerRadius(20)
                            .overlay{
                                RoundedRectangle(cornerRadius:20)
                                    .stroke(lineWidth: 1)
                                    .foregroundStyle(Color(.black))
                            }
                    }
                    
                    Button(action: {
                        path.append(.recPlan)
                    }) {
                        Text("推薦組合")
                            .font(.title2)
                            .foregroundStyle(Color(.black))
                            .frame(width:300,height:120)
                            .background(Color(.primary))
                            .cornerRadius(20)
                            .overlay{
                                RoundedRectangle(cornerRadius:20)
                                    .stroke(lineWidth: 1)
                                    .foregroundStyle(Color(.black))
                            }
                    }
                }
                
                HStack{
                    Image("chicken_health")
                        .resizable().scaledToFit()
                        .frame(width:150)
                        .scaleEffect(x: -1, y: 1)
                        .frame(width:UIScreen.main.bounds.width*0.3)
                        .padding(.leading,-10)
                        .padding(.top,50)
                    
                    Text("你可以選擇自己喜歡的動作，\n或按照我們推薦的動作做喔！")
                        .padding()
                        .font(.callout)
                        .foregroundStyle(Color("DarkBackgroundColor"))
                        .frame(width: 260, height:80)
                        .overlay(
                            RoundedRectangle(cornerRadius:20)
                                .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                .foregroundStyle(Color(.darkBackground))
                        )
                        .padding(.leading,-30)
                        .padding(.bottom,70)
                }
                .padding(.top,50)
                
            }
        }
        .navigationTitle("選擇運動計劃")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    workoutPlanTypeView(path: .constant([]))
}
