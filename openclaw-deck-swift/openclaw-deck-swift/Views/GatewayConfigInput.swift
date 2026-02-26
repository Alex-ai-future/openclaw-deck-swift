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

  @State private var showingToken = false

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      // Gateway URL
      VStack(alignment: .leading, spacing: 6) {
        Text("Gateway URL")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.secondary)

        TextField("ws://host:port", text: $gatewayUrl)
          .textContentType(.URL)
          .textFieldStyle(.roundedBorder)
      }

      // Token
      VStack(alignment: .leading, spacing: 6) {
        Text("Token (optional)")
          .font(.subheadline)
          .fontWeight(.medium)
          .foregroundColor(.secondary)

        HStack(spacing: 8) {
          if showingToken {
            TextField("Token", text: $token)
              .textContentType(.password)
          } else {
            SecureField("Token", text: $token)
              .textContentType(.password)
          }

          Button {
            showingToken.toggle()
          } label: {
            Image(systemName: showingToken ? "eye.slash" : "eye")
              .foregroundColor(.secondary)
          }
          .buttonStyle(.plain)
          .frame(width: 30, height: 30)
        }
        .textFieldStyle(.roundedBorder)
        #if os(iOS)
        .autocapitalization(.none)
        .keyboardType(.URL)
        #endif
      }

      // Connect Button (只在初始页面显示)
      if !isConnected {
        Button {
          onConnect()
        } label: {
          HStack {
            Image(systemName: "plug")
            Text("Connect")
          }
          .frame(maxWidth: .infinity)
        }
        .buttonStyle(.borderedProminent)
        .tint(.green)
      }
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
