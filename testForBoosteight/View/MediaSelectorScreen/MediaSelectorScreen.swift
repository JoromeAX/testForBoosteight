//
//  MediaSelectorScreen.swift
//  testForBoosteight
//
//  Created by Roman on 06.02.2026.
//

import SwiftUI

struct MediaSelectorScreen: View {
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var vm: MediaSelectorViewModel

    let title: String
    let style: MediaSelectorStyle
    
    init(title: String, style: MediaSelectorStyle, mode: MediaSelectorViewModel.Mode) {
        self.title = title
        self.style = style
        _vm = StateObject(wrappedValue: MediaSelectorViewModel(title: title, style: style, mode: mode))
    }
    
    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        dismiss()
                    } label: {
                        Image(.back)
                            .renderingMode(.template)
                    }
                    
                    Spacer()
                    
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        vm.toggleTopSelectAll()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                            
                            Text(vm.topActionTitle)
                        }
                        .font(.system(size: 14, weight: .medium))
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(.white)
                        .cornerRadius(5)
                        .shadow(color: Color.black.opacity(0.2), radius: 4)
                    }
                    
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 24, weight: .semibold))
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(.video)
                            
                            Text(vm.headerCountText)
                                .font(.system(size: 14))
                                .opacity(0.5)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.white)
                        .cornerRadius(5)
                        .shadow(color: .black.opacity(0.2), radius: 2)
                        
                        HStack(spacing: 8) {
                            Image(.mediaSize)
                            
                            Text(vm.headerSizeText)
                                .font(.system(size: 14))
                                .opacity(0.5)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(.white)
                        .cornerRadius(5)
                        .shadow(color: .black.opacity(0.2), radius: 2)
                    }
                }
                
                if style == .comparison {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(vm.comparisonGroups) { group in
                                VStack(spacing: 12) {
                                    HStack {
                                        Text("\(group.titleCount) \(title.split(separator: " ").first ?? "")")
                                            .fontWeight(.semibold)

                                        Spacer()

                                        Button {
                                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                            vm.toggleGroupSelectAll(groupId: group.id)
                                        } label: {
                                            Text(vm.groupActionTitle(groupId: group.id))
                                                .fontWeight(.medium)
                                                .opacity(0.5)
                                        }
                                    }

                                    ScrollView(.horizontal, showsIndicators: false) {
                                        LazyHStack(spacing: 8) {
                                            ForEach(group.items) { item in
                                                Button {
                                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                                    vm.toggleItemSelection(itemId: item.id)
                                                } label: {
                                                    MediaThumbnailView(asset: item.asset)
                                                        .scaledToFill()
                                                        .frame(width: 176, height: 176)
                                                        .clipped()
                                                        .overlay {
                                                            if item.id == group.bestItemId {
                                                                HStack {
                                                                    HStack(spacing: 2) {
                                                                        Image(.bestStars)
                                                                        Text("Best")
                                                                    }
                                                                    .font(.system(size: 14, weight: .semibold))
                                                                    .padding(.vertical, 4)
                                                                    .padding(.horizontal, 8)
                                                                    .background(.white)
                                                                    .foregroundStyle(.accentBlue)
                                                                    .cornerRadius(5)

                                                                    Spacer()

                                                                    Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                                                                        .resizable()
                                                                        .background{
                                                                            Color(item.isSelected ? .white : .clear)
                                                                                .padding(5)
                                                                        }
                                                                        .frame(width: 20, height: 20)
                                                                        .foregroundStyle(.primaryButton)
                                                                }
                                                                .frame(maxHeight: .infinity, alignment: .bottom)
                                                                .padding(8)
                                                            } else {
                                                                Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                                                                    .resizable()
                                                                    .background{
                                                                        Color(item.isSelected ? .white : .clear)
                                                                            .padding(5)
                                                                    }
                                                                    .frame(width: 20, height: 20)
                                                                    .foregroundStyle(.primaryButton)
                                                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                                                    .padding(8)
                                                            }
                                                        }
                                                        .cornerRadius(10)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(vm.simpleItems) { item in
                                Button {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    vm.toggleItemSelection(itemId: item.id)
                                } label: {
                                    MediaThumbnailView(asset: item.asset)
                                        .scaledToFill()
                                        .clipped()
                                        .frame(maxHeight: 216)
                                        .cornerRadius(10)
                                        .overlay {
                                            Image(systemName: item.isSelected ? "checkmark.square.fill" : "square")
                                                .resizable()
                                                .background{
                                                    Color(item.isSelected ? .white : .clear)
                                                        .padding(5)
                                                }
                                                .frame(width: 20, height: 20)
                                                .foregroundStyle(.primaryButton)
                                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                                                .padding(8)
                                        }
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, 16)
            .overlay {
                LinearGradient(stops: [
                    Gradient.Stop(color: Color.white, location: 0.0),
                    Gradient.Stop(color: Color.clear, location: 1)
                ], startPoint: .bottom, endPoint: .top)
                .ignoresSafeArea()
                .frame(height: 60)
                .frame(maxHeight: .infinity, alignment: .bottom)
            }
            
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                vm.deleteSelected()
            } label: {
                Text(vm.bottomActionTitle)
                    .fontWeight(.medium)
                    .foregroundStyle(.textWhite)
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(.primaryButton)
                    .cornerRadius(10)
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
            
        }
        .foregroundStyle(.textBlack)
        .onDisappear {
            vm.cancelWork()
        }
    }
}
