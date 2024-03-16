//
//  ContentViewModel.swift
//  FaceEmotionClassifier
//
//  Created by Sharan Thakur on 16/03/24.
//

import Observation
import PhotosUI
import SwiftUI

extension ContentView {
    @Observable
    class ViewModel {
        var photoItem: PhotosPickerItem?
        var image: UIImage?
        var error: String?
        var predictionTable: Array<(String, Double)>?
        
        var isBusy = false
        var showingError = false
        
        @ObservationIgnored
        private let classifier = try! Face_Emotion_Classifier(configuration: .init())
        
        var imageView: Image? {
            guard let image else {
                return nil
            }
            return Image(uiImage: image)
        }
        
        func loadPhoto(from item: PhotosPickerItem) async {
            do {
                isBusy = true
                guard let data = try await item.loadTransferable(type: Data.self),
                      let uiImage = UIImage(data: data)
                else {
                    throw AppError("Image Could not be loaded!")
                }
                withAnimation(.snappy) {
                    self.image = uiImage
                    self.predictionTable = nil
                    isBusy = false
                }
            } catch {
                isBusy = false
                print(error)
                withAnimation(.bouncy) {
                    self.error = error.localizedDescription
                    self.showingError = true
                }
            }
        }
        
        func predict(on image: UIImage) async {
            guard let buffer = image.colorPixelBuffer() else {
                return
            }
            if isBusy {
                return
            }
            isBusy = true
            do {
                let input = Face_Emotion_ClassifierInput(image: buffer)
                let output = try await classifier.prediction(input: input)
                withAnimation(.snappy) {
                    let probabilities = output.targetProbability.map { $0 }.sorted {
                        $0.value > $1.value
                    }
                    self.predictionTable = probabilities
                }
                isBusy = false
//                print(output.targetProbability)
            } catch {
                isBusy = false
                print(error)
                withAnimation(.bouncy) {
                    self.error = error.localizedDescription
                    self.showingError = true
                }
            }
        }
    }
}

struct AppError: LocalizedError, Error, CustomStringConvertible {
    init(_ message: String) {
        self.message = message
    }
    
    var message: String
    
    var description: String {
        message
    }
}
