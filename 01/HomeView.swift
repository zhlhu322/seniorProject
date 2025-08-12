//
//  HomeView.swift
//  01
//
//  Created by 李恩亞 on 2025/4/29.
//

import SwiftUI



struct HomeView: View {
    @Binding var path: [PlanRoute]
    let week = ["週一","週二","週三","週四","週五","週六","週日"]
    @StateObject var viewModel = WorkoutWeekViewModel()
    
    func getDateForWeekdayOffset(_ offset: Int) -> Date {
            let calendar = Calendar.current
            let today = Date()
            let weekday = calendar.component(.weekday, from: today) // 1: Sunday ~ 7: Saturday
            let startOfWeek = calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: today)!
            return calendar.date(byAdding: .day, value: offset, to: startOfWeek)!
    }
    
    var body: some View {
            ZStack{
                Color(.background).ignoresSafeArea()
                VStack{
                    Text("本週運動")
                        .padding(.bottom,10)
                        .padding(.leading,25)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        ForEach(0..<7) { item in
                            let date = getDateForWeekdayOffset(item)
                            let dateString = viewModel.formattedDate(date)
                            let didWorkout = viewModel.workoutDays.contains(dateString)

                            VStack {
                                Text("\(week[item])").padding(.bottom,15)
                                Image(systemName: "flame.fill")
                                    .font(.system(size:28))
                                    .foregroundStyle(didWorkout ? .red : Color(.lightGray))
                            }
                            .padding(.horizontal,3)
                        }
                    }
                    .frame(maxWidth:.infinity)
                    .padding()
                    .background(Color(.white).opacity(0.5))
                    .overlay{RoundedRectangle(cornerRadius:10)
                        .stroke(lineWidth: 1)}
                    .padding(.bottom,20)
                    .padding(.horizontal,15)
                
                    VStack {
                        Text("近期紀錄")
                            .padding(.bottom,10)
                            .padding(.leading,25)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        HStack(spacing:15){
                            ForEach(0..<3, id: \.self){ item in
                                VStack{
                                    Image("elbow_extension")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width:60,height:60)
                                    Text("手臂彎舉")
                                }
                                .frame(width:110,height:120)
                                .background(Color(.primary).opacity(0.9))
                                .cornerRadius(10)
                                .overlay{RoundedRectangle(cornerRadius:10)
                                    .stroke(lineWidth: 1)}
                            }
                        }
                        .padding(.horizontal,15)
                    }
                    .frame(height:210)
                    .background(Color(.white))
                    
                   
                    Button(action: {
                        path.append(.choosePlan)
                    }) {
                        Text("選擇運動計劃")
                            .font(.title3)
                            .fontWeight(.semibold)
                            
                    }
                    .frame(width:360,height:70)
                    .background(Color(.accent))
                    .foregroundStyle(Color(.white))
                    .cornerRadius(20)
                    .overlay{RoundedRectangle(cornerRadius:20)
                            .stroke(lineWidth: 1)}
                    .padding(.top,30)
                    .padding(.bottom,30)
                    
                    HStack{
                        Image("chicken_health")
                            .resizable().scaledToFit()
                            .frame(width:200)
                            .scaleEffect(x: -1, y: 1)
                        
                        Text("呱呱 今天做什麼呢？")
                            .font(.callout)
                            .foregroundStyle(Color("DarkBackgroundColor"))
                            .frame(width: 170, height:50)
                            .overlay(
                                RoundedRectangle(cornerRadius:20)
                                    .stroke(style: StrokeStyle(lineWidth: 2, dash: [5]))
                                    .foregroundStyle(Color(.darkBackground))
                            )
                            .padding(.leading,-30)
                            .padding(.bottom,70)
                    }
                    Spacer()
                    
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("CountBuddy")
                        .font(.system(size: 24 , weight:.semibold))
                        .foregroundColor(.black) }}

        }
    }
    
    
//    #Preview {
//        HomeView(path: .constant([]))
//    }

