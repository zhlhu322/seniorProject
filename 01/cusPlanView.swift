import SwiftUI

struct cusPlanView: View {
    @Binding var path: [PlanRoute]
    @State private var searchText = ""
    @State private var allDetails: [ExerciseDetail] = []
    @State private var selectedExerciseIDs: Set<String> = []

    @Environment(\.presentationMode) var presentationMode

    var filteredExercises: [ExerciseDetail] {
        if searchText.isEmpty {
            return allDetails
        } else {
            return allDetails.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var countExercises: [ExerciseDetail] {
        filteredExercises.filter { !$0.isTimedExercise }
    }

    private var timedExercises: [ExerciseDetail] {
        filteredExercises.filter { $0.isTimedExercise }
    }

    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    private func toggleExerciseSelection(_ exercise: ExerciseDetail) {
        if selectedExerciseIDs.contains(exercise.id) {
            selectedExerciseIDs.remove(exercise.id)
        } else {
            selectedExerciseIDs.insert(exercise.id)
        }
    }
    
    private var searchBar: some View {
        TextField("輸入運動名稱", text: $searchText)
            .padding(.leading, 15)
            .frame(height: 64)
            .background(Color.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray, lineWidth: 1)
            )
            .padding(.horizontal, 15)
            .padding(.bottom, 20)
    }

    
    private func exerciseGrid(for exercises: [ExerciseDetail]) -> some View {
        LazyVGrid(columns: columns, spacing: 15) {
            ForEach(exercises, id: \.self) { detail in
                exerciseInfoButton(
                    title: detail.name,
                    onTap: {
                        path.append(.exerciseDetail(detail))
                    },
                    imageURL: detail.image_name,
                    onSelect: {
                        toggleExerciseSelection(detail)
                    },
                    isSelected: selectedExerciseIDs.contains(detail.id)
                )
            }
        }
        .padding(.horizontal)
        .padding(.top, 15)
    }

    @ViewBuilder
    private func exerciseSection(title: String, exercises: [ExerciseDetail]) -> some View {
        if !exercises.isEmpty {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 18)

            exerciseGrid(for: exercises)
        }
    }

    
    var body: some View {
        
        ZStack {
            Color("BackgroundColor").ignoresSafeArea()

            VStack(alignment: .leading) {
                Text("運動名稱")
                    .padding(.horizontal)
                    .padding(.top, 10)

                // 搜尋欄
                searchBar

                ScrollView {
                    Text("動作清單")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 15)

                    exerciseSection(title: "計次動作", exercises: countExercises)
                    exerciseSection(title: "計時動作", exercises: timedExercises)
                }
                .background(Color.white)
                
                Spacer()
                
                Button(action: {
                    path.append(.cusPlan_edit(selectedExerciseIDs: selectedExerciseIDs))
                }) {
                    Text("編輯組合")
                        .font(.system(size: 20, design: .default))
                        .fontWeight(.bold)
                        .foregroundStyle(Color.white)
                        .frame(width: 345, height: 64)
                        .background(selectedExerciseIDs.count != 0 ? Color.accentColor : Color.gray)
                        .cornerRadius(16)
                }
                .padding()
                .frame(maxWidth:UIScreen.main.bounds.width,alignment: .center)
                
            }
        }
        .navigationTitle("自訂組合")
        .navigationBarBackButtonHidden()
        .toolbarBackground(Color("BackgroundColor"), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            let details = loadAllExerciseDetails()
            allDetails = details
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                            .fontWeight(.semibold)
                            .foregroundStyle(Color("MyMint"))
                        
                        Text("返回")
                            .foregroundStyle(Color("MyMint"))
                    }
                }
            }
        }

    }
}

#Preview {
    cusPlanView(path: .constant([]))
}
