//
//  HeaderSection.swift
//  testForBoosteight
//
//  Created by Roman on 07.02.2026.
//

import SwiftUI

struct HeaderSection: View {
    let dismiss: DismissAction
    var body: some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            dismiss()
        } label: {
            Image(.back)
                .renderingMode(.template)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
