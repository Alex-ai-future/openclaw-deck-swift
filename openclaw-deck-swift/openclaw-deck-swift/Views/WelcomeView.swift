// WelcomeView.swift
// OpenClaw Deck Swift
//
// Welcome view for first-time users

import SwiftUI

struct WelcomeView: View {
    @Binding var gatewayUrl: String
    @Binding var token: String
    var connectionError: String?
    var isConnecting: Bool
    var onClearError: () -> Void
    var onShowSettings: () -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // Logo
                Image(systemName: "message.badge.filled.fill")
                    .font(.system(size: 72))
                    .foregroundColor(.blue)

                Text("openclaw_deck".localized)
                    .font(.title)
                    .fontWeight(.bold)

                // Error message
                if let error = connectionError {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("connection_failed".localized)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                            Spacer()
                            Button("dismiss".localized, action: onClearError)
                                .font(.caption)
                        }

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }

                Spacer()

                // Settings button
                Button(action: onShowSettings) {
                    HStack {
                        Image(systemName: "gear")
                        Text("open_settings".localized)
                    }
                    .fontWeight(.medium)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.clear)
            .navigationTitle("")
            #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button(action: onShowSettings) {
                            Image(systemName: "gear")
                                .font(.title2)
                        }
                    }
                }
            #else
                .toolbar {
                        ToolbarItem(placement: .automatic) {
                            Button(action: onShowSettings) {
                                Image(systemName: "gear")
                                    .font(.title2)
                            }
                        }
                    }
            #endif
        }
    }
}

#Preview {
    WelcomeView(
        gatewayUrl: .constant("ws://127.0.0.1:18789"),
        token: .constant(""),
        connectionError: nil,
        isConnecting: false,
        onClearError: {},
        onShowSettings: {}
    )
}
