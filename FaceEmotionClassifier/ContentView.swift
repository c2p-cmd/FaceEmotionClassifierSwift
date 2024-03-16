//
//  ContentView.swift
//  FaceEmotionClassifier
//
//  Created by Sharan Thakur on 16/03/24.
//

import PhotosUI
import SwiftUI

struct ContentView: View {
    @State private var vm = ViewModel()
    @State private var cameraManager = CameraManager()
    
    @State private var showCamera = false
    
    var dataTable: Array<(String, Double)>? {
        vm.predictionTable
    }
    
    var body: some View {
        Form {
            PhotosPicker(selection: $vm.photoItem, matching: .images) {
                VStack(alignment: .center, spacing: 20) {
                    vm.imageView?
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 300)
                    
                    Label(
                        vm.image == nil ? "Pick Image" : "Replace Image",
                        systemImage: "photo"
                    )
                    .labelStyle(FarLabelStyle())
                    .tint(.purple)
                    .symbolVariant(.fill)
                }
                .padding(.vertical)
            }
            .disabled(vm.isBusy)
            .alert(
                "Error!",
                isPresented: $vm.showingError,
                presenting: vm.error
            ) { e in
                Button("Okay", role: .cancel) {
                    
                }
            } message: { e in
                Text(e)
                    .bold()
                    .foregroundStyle(.red)
            }
            
            if let image = vm.image {
                Button("Predict", systemImage: "wand.and.stars") {
                    Task {
                        await vm.predict(on: image)
                    }
                }
                .labelStyle(FarLabelStyle())
                .disabled(vm.isBusy)
            }
            
            if vm.isBusy {
                ProgressView()
            }
            
            tableView
        }
        .toolbar {
            Button("Live Preview", systemImage: "camera.viewfinder") {
                self.cameraManager.setupSession()
                self.showCamera.toggle()
            }
        }
        .navigationTitle("Face Emotion Classifier")
        .onAppear {
            self.cameraManager.didOutput = {
                self.vm.predictionTable = $0
            }
        }
        .onChange(of: vm.photoItem) {
            if let item = vm.photoItem {
                Task {
                    await vm.loadPhoto(from: item)
                }
            }
        }
        .fullScreenCover(isPresented: $showCamera) {
            VStack {
                HStack {
                    Button("Close", role: .destructive) {
                        self.cameraManager.stopCapturing()
                        self.showCamera.toggle()
                    }
                    Spacer()
                    let isRunning = self.cameraManager.session.isRunning
                    Button(isRunning ? "Pause" : "Resume", systemImage: isRunning ? "pause.circle" : "play.circle") {
                        if self.cameraManager.session.isRunning {
                            self.cameraManager.stopCapturing()
                        } else {
                            self.cameraManager.setupSession()
                        }
                    }
                }
                CameraPreviewView(session: cameraManager.session)
                Spacer()
                tableView
            }
        }
    }
    
    @ViewBuilder
    var tableView: some View {
        if let dataTable {
            Section("Predictions") {
                let indices = (0..<dataTable.count)
                ForEach(indices, id: \.self) { (index: Int) in
                    let (key, value) = dataTable[index]
                    HStack {
                        Text(key.capitalized)
                        Spacer()
                        Text(value.formatted(.percent))
                            .bold()
                    }
                }
                
                Button("Clear", systemImage: "trash", role: .destructive) {
                    self.vm.predictionTable = nil
                }
                .labelStyle(FarLabelStyle())
            }
            .fontDesign(.rounded)
        }
    }
}

struct FarLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.title
            Spacer()
            configuration.icon
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
