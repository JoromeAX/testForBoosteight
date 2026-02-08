//
//  VideoGridItem.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI

struct VideoGridItem: View {
    let thumbnail: Image
    let sizeText: String
    
    var body: some View {
        thumbnail
            .resizable()
            .frame(width: 176, height: 176)
            .scaledToFit()
            .cornerRadius(10)
            .overlay {
                Text(sizeText)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .padding(6)
                    .background(.primaryButton)
                    .cornerRadius(5)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
    }
}

#Preview {
    VideoGridItem(thumbnail: Image(.mediaImage1), sizeText: "1.2 GB")
        .padding()
        .background(Color.gray.opacity(0.1))
}
