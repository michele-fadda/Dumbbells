//
//  RestPickerPillView.swift
//  DumbBells
//
//  Created by Michele Fadda on 02/08/2025.
//

import SwiftUI

struct DismissIconButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "xmark")
                .foregroundColor(.black)
                .frame(width: 44, height: 44)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
}

#Preview {
    DismissIconButton(action: {})
}


struct RestPickerPillView: View {
    var onPick: (Int) -> Void
    var onDismiss: () -> Void

    let options = [30, 60, 120, 180]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { seconds in
                Button(action: { onPick(seconds) }) {
                    Text("\(seconds / 60 > 0 ? "\(seconds / 60) min" : "\(seconds) sec")")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white, lineWidth: 1)
                        )
                }
            }

            Spacer(minLength: 8)

            DismissIconButton(action: onDismiss)
        }
        .padding()
        .background(Color.black)
        .cornerRadius(32)
        .padding(.horizontal)
    }
}

#Preview {
    RestPickerPillView(onPick: { _ in }, onDismiss: {})
}
