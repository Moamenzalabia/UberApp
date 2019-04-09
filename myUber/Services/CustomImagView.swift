//  CustomImagView.swift
//  myUber
//  Created by MOAMEN on 11/20/1397 AP.
//  Copyright © 1397 MOAMEN. All rights reserved.


import UIKit

var imageCashe = [String: UIImage]()

class CustomImageView: UIImageView {
    
    var lastURLUsedToLoadImage: String?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        setupImageView()
    }
    
    func loadImage(urlString: String) {
        
        lastURLUsedToLoadImage = urlString
        self.image = nil // to remove old image before set new image
        
        // if imageurl is download before don't download image agine check if it exist in cashed array
        if let cachedImage = imageCashe[urlString] {
            self.image = cachedImage
            return
        }
        
        guard  let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            // check for the error , then construct the image using data
            if let error = error {
                print()
                CustomAlert.instance.showAlert(Status: "Failure", message: "Failed to fetch post image\(error.localizedDescription)", alertType: .failure)
                return
            }
            
            //to download image by it's creation's order
            if url.absoluteString != self.lastURLUsedToLoadImage {
                return
            }
            
            // perhaps check for response status of 200 (HTTP OK)
            guard let imageData = data else { return }
            let photoImage = UIImage(data: imageData)
            imageCashe[url.absoluteString] = photoImage
            
            // need to get back onto  the main UI thread
            DispatchQueue.main.async {
                self.image = photoImage
            }
            
            }.resume()
        
    }
    
    fileprivate func setupImageView(){
        self.layer.cornerRadius = self.frame.width / 2
        self.clipsToBounds = true
    }
    
}


