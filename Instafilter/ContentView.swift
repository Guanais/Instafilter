//
//  ContentView.swift
//  Instafilter
//
//  Created by Kaio Guanais on 2020-06-04.
//  Copyright © 2020 Kaio Guanais. All rights reserved.
//

import CoreImage
import CoreImage.CIFilterBuiltins
import SwiftUI

struct ContentView: View {
    @State private var image: Image?
    @State private var filterIntenity = 0.5
    
    @State private var showingImagePicker = false
    @State private var showingFilterSheet = false
    @State private var showingSaveError = false
    @State private var showingSave = false
    @State private var inputImage: UIImage?
    @State private var processedImage: UIImage?
    
    @State var currentFilter: CIFilter = CIFilter.sepiaTone()
    let context = CIContext()

    
    var body: some View {
        let intensity = Binding<Double> (
            get: {
                self.filterIntenity
            },
            set: {
                self.filterIntenity = $0
                self.applyProcessing()
            }
        )
        
        return NavigationView {
            VStack {
                ZStack {
                    Rectangle()
                        .fill(Color.secondary)
                    
                    if image != nil {
                        image?
                            .resizable()
                            .scaledToFit()
                    } else {
                        Text("Tap to select a picture")
                            .foregroundColor(.white)
                            .font(.headline)
                    }
                }
                .onTapGesture {
                    self.showingImagePicker = true
                }
                
                HStack {
                    Text("Intensity")
                    Slider(value: intensity)
                }
                .padding(.vertical)
                
                HStack {
                    Button("Change filter") {
                        self.showingFilterSheet = true
                    }
                    
                    Spacer()
                    
                    Button("Save") {
                        if self.image != nil {
                            self.showingSave.toggle()
                            
                            guard let processedImage = self.processedImage else { return }
                            
                            let imageSaver = ImageSaver()
                            
                            imageSaver.successHandler = {
                                print("Success!")
                            }
                            
                            imageSaver.errorHandler = {
                                print("Ooops: \($0.localizedDescription)")
                            }
                            
                            imageSaver.writeToPhotoAlbum(image: processedImage)
                            
                        } else {
                            self.showingSaveError.toggle()
                        }
                    }
                }
            }
            .padding([.horizontal, .bottom])
            .navigationBarTitle("Instafilter")
            .alert(isPresented: $showingSaveError) {
                Alert(title: Text("Select First"), message: Text("Select a picture to save."), dismissButton: .cancel(Text("OK")))
            }
            .alert(isPresented: $showingSave) {
                Alert(title: Text("Saved"), dismissButton: .cancel(Text("OK")))
            }
            .sheet(isPresented: $showingImagePicker, onDismiss: loadImage) {
                ImagePicker(image: self.$inputImage)
            }
            .actionSheet(isPresented: $showingFilterSheet) {
                ActionSheet(title: Text("Select a Filter"), buttons: [
                    .default(Text("Crystallize")) {self.setFilter(CIFilter.crystallize())},
                    .default(Text("Edges")) {self.setFilter(CIFilter.edges())},
                    .default(Text("Gaussin Blur")) {self.setFilter(CIFilter.gaussianBlur())},
                    .default(Text("Pixellate")) {self.setFilter(CIFilter.pixellate())},
                    .default(Text("Sepia Tone")) {self.setFilter(CIFilter.sepiaTone())},
                    .default(Text("Unsharp Mask")) {self.setFilter(CIFilter.unsharpMask())},
                    .default(Text("Vignette")) {self.setFilter(CIFilter.vignette())},
                ])
            }
        }
    }
    func loadImage() {
        guard let inputImage = inputImage else { return }
        image = Image(uiImage: inputImage)
        
        let beginImage = CIImage(image: inputImage)
        currentFilter.setValue(beginImage, forKey: kCIInputImageKey)
        applyProcessing()
    }
    
    func applyProcessing() {
        let inputKeys = currentFilter.inputKeys
        if inputKeys.contains(kCIInputIntensityKey) { currentFilter.setValue(filterIntenity, forKey: kCIInputIntensityKey) }
        if inputKeys.contains(kCIInputRadiusKey) { currentFilter.setValue(filterIntenity * 200, forKey: kCIInputRadiusKey) }
        if inputKeys.contains(kCIInputScaleKey) { currentFilter.setValue(filterIntenity * 10, forKey: kCIInputScaleKey)}
        
        guard let outputImage = currentFilter.outputImage else { return }
        
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            let uiImage = UIImage(cgImage: cgimg)
            image = Image(uiImage: uiImage)
            processedImage = uiImage
        }
    }
    
    func setFilter(_ filter: CIFilter) {
        currentFilter = filter
        loadImage()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
