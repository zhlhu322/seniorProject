//
//  cusPlan_edit.swift
//  01
//
//  Created by 李恩亞 on 2025/8/3.
//

import SwiftUI

struct SelectedExerciseItem: Identifiable {
    let id: String
    let detail: ExerciseDetail
    var setsText: String = ""
    var repsText: String = ""     // 計次用
    var secondsText: String = ""  // 計時用
}

struct cusPlan_edit: View {

    @Binding var path: [PlanRoute]
    let selectedExerciseIDs: Set<String>

    @State private var allDetails: [ExerciseDetail] = []
    @State private var selectedExercise: [SelectedExerciseItem] = []
    @FocusState private var focusedField: ExerciseInputField?

    private enum ExerciseInputField: Hashable {
        case sets(String)
        case reps(String)
        case seconds(String)
    }

    private var equipmentList: [String] {
        let equipments: [String] = selectedExercise.map { $0.detail.equipment }
        let parts: [String] = equipments.flatMap { $0.components(separatedBy: "/") }
        let filtered: [String] = parts.filter { $0 != "X" }
        return Array(Set(filtered)).sorted()
    }

    private var customWorkoutPlan: WorkoutPlan {
        WorkoutPlan(
            name: "自訂組合",
            details: selectedExercise.flatMap { item in
                let setCount = max(Int(item.setsText) ?? 1, 1)
                let detail = makePlanDetail(from: item, setCount: setCount)
                return Array(repeating: detail, count: setCount)
            }
        )
    }

    private func makePlanDetail(from item: SelectedExerciseItem, setCount: Int) -> PlanDetails {
        PlanDetails(
            id: item.detail.id,
            name: item.detail.name,
            sets: setCount,
            targetCount: item.detail.isTimedExercise ? nil : (Int(item.repsText) ?? 5),
            targetTime: item.detail.isTimedExercise ? (Int(item.secondsText) ?? 30) : nil,
            rest_seconds: 10,
            lottie_url: item.detail.lottie_url,
            image_name: item.detail.image_name
        )
    }

    var body: some View {

        VStack(spacing: 0) {

            Text("已選動作組合")
                .padding(.horizontal)
                .padding(.top, 15)
                .frame(maxWidth: .infinity, alignment: .leading)

            List($selectedExercise, editActions: .move) { $item in
                HStack(spacing: 8) {
                    Text(item.detail.name)
                        .foregroundStyle(Color(.background))
                    Spacer()
                    TextField("組數", text: $item.setsText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.center)
                        .focused($focusedField, equals: .sets(item.id))
                        .frame(width: 52, height: 36)
                        .background(Color(.background))
                        .cornerRadius(10)
                        .foregroundStyle(Color(.accent))
                    Text("X")
                        .foregroundStyle(Color(.background))
                        .fontWeight(.semibold)
                    TextField(
                        item.detail.isTimedExercise ? "秒數" : "次數",
                        text: item.detail.isTimedExercise ? $item.secondsText : $item.repsText
                    )
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .focused($focusedField, equals: item.detail.isTimedExercise ? .seconds(item.id) : .reps(item.id))
                    .frame(width: 52, height: 36)
                    .background(Color(.background))
                    .cornerRadius(10)
                    .foregroundStyle(Color(.accent))
                    Button {
                        selectedExercise.removeAll { $0.id == item.id }
                    } label: {
                        Image(systemName: "minus.circle.fill")
                            .frame(width: 36, height: 36)
                            .foregroundStyle(Color(.background))
                            .opacity(0.8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal)
                .frame(width: UIScreen.main.bounds.width * 0.9, height: 64)
                .background(Color(.accent))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(lineWidth: 1)
                        .foregroundColor(.accent)
                )
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
                .listRowSeparator(.hidden)
            }
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .onAppear {
                guard selectedExercise.isEmpty else { return }
                allDetails = loadAllExerciseDetails()
                selectedExercise = allDetails
                    .filter { selectedExerciseIDs.contains($0.id) }
                    .map { SelectedExerciseItem(id: $0.id, detail: $0) }
            }
            .scrollDismissesKeyboard(.immediately)

            if !equipmentList.isEmpty {
                VStack(alignment: .leading, spacing: 15) {
                    Text("使用器材（擇一）")
                        .padding(.horizontal, 30)
                    HStack(spacing: 12) {
                        ForEach(equipmentList, id: \.self) { equipment in
                            Text(equipment)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(style: StrokeStyle(lineWidth: 1.5, dash: [6]))
                                        .foregroundColor(Color(.darkBackground)))
                        }
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 10)
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.background))
            }

            Button(action: {
                path.append(.blePairing(plan: customWorkoutPlan))
            }) {
                Text("開始運動")
                    .font(.system(size: 20, design: .default))
                    .fontWeight(.bold)
                    .foregroundStyle(Color.white)
                    .frame(width: 345, height: 64)
                    .background(selectedExercise.isEmpty ? Color.gray : Color.accentColor)
                    .cornerRadius(16)
            }
            .disabled(selectedExercise.isEmpty)
            .padding(.bottom, 10)
            .frame(maxWidth: .infinity, alignment: .center)
            .background(Color(.background))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            focusedField = nil
        }
        .navigationTitle("編輯組合")
        .navigationBarBackButtonHidden()
        .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    path.removeLast()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                        Text("返回")
                    }
                    .foregroundStyle(Color("MyMint"))
                }
            }
        }
    }
}




#Preview {
    NavigationStack {
        cusPlan_edit(path: .constant([]), selectedExerciseIDs: ["1", "3", "5"])
    }
}
