//
//  TimerIconButton.swift
//  DumbBells
//
//  Created by Michele Fadda on 02/08/2025.
//

import SwiftUI

struct TimerIconButton: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "timer")
                .foregroundColor(.black)
                .frame(width: 40, height: 40)
                .background(Color.white)
                .clipShape(Circle())
        }
    }
}

#Preview {
    TimerIconButton(action: {})
}
