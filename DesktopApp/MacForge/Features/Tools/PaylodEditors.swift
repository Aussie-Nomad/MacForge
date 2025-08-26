//
//  PaylodEditors.swift
//  MacForge
//
//  Payload editor components for creating and modifying MDM configuration profiles.
//  Provides specialized editors for different payload types and settings.

import SwiftUI

struct WiFiSettingsView: View {
    @Binding var payload: Payload
    @State private var ssid = ""
    @State private var security = "WPA2 Personal"
    let options = ["WPA2 Personal","WPA3 Personal","WPA2 Enterprise"]
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ThemedField(title: "SSID", text: $ssid)
            VStack(alignment: .leading, spacing: 4) {
                Text("SECURITY TYPE").font(.caption2).foregroundStyle(LcarsTheme.amber.opacity(0.9))
                Picker("Security Type", selection: $security) { ForEach(options, id:\.self, content: Text.init) }
                    .pickerStyle(.menu)
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 10).fill(LcarsTheme.amber.opacity(0.15)))
            }
        }
        .onChange(of: ssid)     { payload.settings["SSID_STR"] = .init(ssid) }
        .onChange(of: security) { payload.settings["EncryptionType"] = .init(security) }
        .onAppear {
            if let s = payload.settings["SSID_STR"]?.value as? String { ssid = s }
            if let s = payload.settings["EncryptionType"]?.value as? String { security = s }
        }
    }
}

struct RestrictionsSettingsView: View {
    @Binding var payload: Payload
    @State private var allowAppInstall = true
    @State private var allowCamera = true
    @State private var allowSafari = true
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Allow App Installation", isOn: $allowAppInstall)
            Toggle("Allow Camera", isOn: $allowCamera)
            Toggle("Allow Safari", isOn: $allowSafari)
        }
        .tint(LcarsTheme.amber)
        .onChange(of: allowAppInstall) { payload.settings["allowAppInstallation"] = .init(allowAppInstall) }
        .onChange(of: allowCamera)     { payload.settings["allowCamera"]        = .init(allowCamera) }
        .onChange(of: allowSafari)     { payload.settings["allowSafari"]        = .init(allowSafari) }
    }
}

struct FileVaultSettingsView: View {
    @Binding var payload: Payload
    @State private var deferEnable = false
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { Toggle("Defer enabling until logout", isOn: $deferEnable).tint(LcarsTheme.amber) }
            .onChange(of: deferEnable) { payload.settings["Defer"] = .init(deferEnable) }
    }
}

struct FirewallSettingsView: View {
    @Binding var payload: Payload
    @State private var enabled = true
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { Toggle("Enable macOS firewall", isOn: $enabled).tint(LcarsTheme.amber) }
            .onChange(of: enabled) { payload.settings["EnableFirewall"] = .init(enabled) }
    }
}

struct NotificationsSettingsView: View {
    @Binding var payload: Payload
    @State private var allowCritical = true
    var body: some View {
        VStack(alignment: .leading, spacing: 10) { Toggle("Allow Critical Alerts", isOn: $allowCritical).tint(LcarsTheme.amber) }
            .onChange(of: allowCritical) { payload.settings["AllowCriticalAlerts"] = .init(allowCritical) }
    }
}
