//
//  ExploreView.swift
//  Togu
//
//  Created by Whyyy on 06/11/2025.
//

import SwiftUI

struct ExploreView: View {
    @EnvironmentObject var auth: AuthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Spacer()
            
                Spacer()
                Spacer()
                
                Image(systemName: "safari")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.toguPrimary)
                
                Text("Explore")
                    .font(.title)
                    .bold()
                
                Text("Coming Soon... we're excited to continue this journey with the academy.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

            }
            .padding(.top, 100)
        }
        .ignoresSafeArea()
    }
}


#Preview {
    NavigationStack {
        ExploreView()
            .environmentObject(AuthViewModel())
    }
}
