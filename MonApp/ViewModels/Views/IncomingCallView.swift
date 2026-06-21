//
//  IncomingCallView.swift
//  MonApp
//
//  Created by Thierno Moustapha BARRY  on 21/06/2026.
//

import SwiftUI

struct IncomingCallView: View {

    let callerName: String
    let callType: String
    let onAccept: () -> Void
    let onDecline: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 130))
                    .foregroundColor(.white.opacity(0.9))

                Text(callerName)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)

                Text(callType == "video" ? "🎥 Appel vidéo entrant..." : "📞 Appel audio entrant...")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.7))

                Spacer()

                HStack(spacing: 70) {
                    Button {
                        onDecline()
                    } label: {
                        Image(systemName: "phone.down.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.white)
                            .frame(width: 82, height: 82)
                            .background(Color.red)
                            .clipShape(Circle())
                    }

                    Button {
                        onAccept()
                    } label: {
                        Image(systemName: "phone.fill")
                            .font(.system(size: 34))
                            .foregroundColor(.white)
                            .frame(width: 82, height: 82)
                            .background(Color.green)
                            .clipShape(Circle())
                    }
                }
                .padding(.bottom, 60)
            }
        }
    }
}
