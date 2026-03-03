// GatewayConfigInput.swift
// OpenClaw Deck Swift
//
// 公用 Gateway 配置输入组件

import SwiftUI

struct GatewayConfigInput: View {
    @Binding var gatewayUrl: String
    @Binding var token: String
    var onConnect: () -> Void
    var isConnected: Bool = false

    @FocusState private var isGatewayUrlFocused: Bool
    @FocusState private var isTokenFocused: Bool

    var body: some View {
        // Gateway URL
        TextField("gateway_url".localized, text: $gatewayUrl, prompt: Text("ws://host:port"))
            .accessibilityIdentifier("gatewayUrlInput")
            .textContentType(.URL)
            .focused($isGatewayUrlFocused)
            .submitLabel(.done)
            .onSubmit {
                isGatewayUrlFocused = false
            }
        #if os(iOS) || os(visionOS)
            .autocapitalization(.none)
            .keyboardType(.URL)
        #endif

        // Token
        TextField("token_optional".localized, text: $token)
            .accessibilityIdentifier("tokenInput")
            .textContentType(.none)
            .focused($isTokenFocused)
            .submitLabel(.done)
            .onSubmit {
                isTokenFocused = false
            }
        #if os(iOS) || os(visionOS)
            .autocapitalization(.none)
        #endif

        // Connect Button (只在初始页面显示)
        if !isConnected {
            Button {
                onConnect()
            } label: {
                HStack {
                    Image(systemName: "plug")
                    Text("connect".localized)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
        }
    }
}

#Preview {
    GatewayConfigInput(
        gatewayUrl: .constant("ws://127.0.0.1:18789"),
        token: .constant(""),
        onConnect: {},
        isConnected: false
    )
    .padding()
}
