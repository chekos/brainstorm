//
//  AISettingsView.swift
//  brainstorm
//
//  Created by Sergio Sanchez on 7/8/25.
//

import SwiftUI

struct AISettingsView: View {
    @State private var openAIApiKey: String = ""
    @State private var isShowingHelp = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                Text("AI Services Configuration")
                    .font(.title2)
                    .fontWeight(.medium)
                
                Text("Configure AI services to enable intelligent document analysis and study task generation.")
                    .foregroundColor(.secondary)
                
                Divider()
                
                // OpenAI Configuration
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("OpenAI API Key")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("Get API Key") {
                            isShowingHelp = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    SecureField("sk-...", text: $openAIApiKey)
                        .textFieldStyle(.roundedBorder)
                        .onAppear {
                            loadSavedApiKey()
                        }
                    
                    Text("Required for intelligent document analysis. Your API key is stored securely on your device.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if !openAIApiKey.isEmpty {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("OpenAI service will be used for PDF analysis")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Mock AI service will be used (limited functionality)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // Future AI Services
                VStack(alignment: .leading, spacing: 12) {
                    Text("Future AI Services")
                        .font(.headline)
                    
                    HStack {
                        Image(systemName: "brain")
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Apple Intelligence")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Coming soon - On-device processing with complete privacy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Coming Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                    }
                    
                    HStack {
                        Image(systemName: "doc.text.magnifyingglass")
                            .foregroundColor(.purple)
                        VStack(alignment: .leading) {
                            Text("Anthropic Claude")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("Advanced document analysis and reasoning")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("Coming Soon")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(8)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                Spacer()
                
                HStack {
                    Button("Cancel") {
                        dismiss()
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Save") {
                        saveApiKey()
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .navigationTitle("AI Settings")
        }
        .sheet(isPresented: $isShowingHelp) {
            AIHelpView()
        }
    }
    
    private func loadSavedApiKey() {
        if let savedKey = UserDefaults.standard.string(forKey: "openai_api_key") {
            openAIApiKey = savedKey
        }
    }
    
    private func saveApiKey() {
        if openAIApiKey.isEmpty {
            UserDefaults.standard.removeObject(forKey: "openai_api_key")
        } else {
            UserDefaults.standard.set(openAIApiKey, forKey: "openai_api_key")
        }
    }
}

struct AIHelpView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Getting Your OpenAI API Key")
                        .font(.title2)
                        .fontWeight(.medium)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("1. Visit OpenAI's website")
                            .font(.headline)
                        
                        Text("Go to platform.openai.com and sign up for an account if you don't have one.")
                        
                        Text("2. Navigate to API Keys")
                            .font(.headline)
                        
                        Text("Once logged in, go to your account settings and find the \"API Keys\" section.")
                        
                        Text("3. Create a new API key")
                            .font(.headline)
                        
                        Text("Click \"Create new secret key\" and give it a name like \"brainstorm-app\".")
                        
                        Text("4. Copy the key")
                            .font(.headline)
                        
                        Text("Copy the generated key (it starts with 'sk-') and paste it into the API key field in brainstorm.")
                        
                        Text("5. Add billing information")
                            .font(.headline)
                        
                        Text("You'll need to add a payment method to your OpenAI account. The cost for document analysis is typically $0.01-0.05 per document.")
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Privacy & Security")
                            .font(.headline)
                        
                        Text("• Your API key is stored securely on your device only")
                        Text("• Document content is sent to OpenAI for analysis")
                        Text("• OpenAI does not store your data for training")
                        Text("• You can remove your API key at any time")
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("API Key Help")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    AISettingsView()
}