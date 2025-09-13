//
//  SSHConnectionSheet.swift
//  Joy Pose
//
//  Created by Bin Wang on 9/13/25.
//

import SwiftUI

struct SSHConnectionSheet: View {
    let hostManager: RemoteHostManager
    @Binding var savedHosts: [HostConfiguration]
    @Binding var isPresented: Bool
    let editingHost: HostConfiguration?

    @State private var hostname = ""
    @State private var username = ""
    @State private var password = ""
    @State private var port = "22"
    @State private var hostName = ""

    var body: some View {
        NavigationView {
            Form {
                Section("Connection Details") {
                    TextField("Host Name", text: $hostName)
                    TextField("Hostname", text: $hostname)
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle("SSH Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Connect") {
                        Task {
                            let config = HostConfiguration(
                                name: hostName.isEmpty ? hostname : hostName,
                                hostname: hostname,
                                port: Int(port) ?? 22,
                                username: username,
                                password: password
                            )
                            savedHosts.append(config)
                            await hostManager.connect(to: config)
                            isPresented = false
                        }
                    }
                    .disabled(hostname.isEmpty || username.isEmpty)
                }
            }
        }
        .onAppear {
            if let host = editingHost {
                hostName = host.name
                hostname = host.hostname
                username = host.username
                password = host.password
                port = String(host.port)
            }
        }
    }
}
