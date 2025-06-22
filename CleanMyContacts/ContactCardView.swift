import SwiftUI
import Contacts

struct ContactCardView: View {
    let contact: CNContact
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void
    
    @State private var offset = CGSize.zero
    
    private var cardBackgroundColor: Color {
        if offset.width > 30 {
            return Color.green.opacity(0.3 + min(abs(offset.width) / 200.0, 0.4))
        } else if offset.width < -30 {
            return Color.red.opacity(0.3 + min(abs(offset.width) / 200.0, 0.4))
        } else {
            return Color(.systemBackground)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("\(contact.givenName) \(contact.familyName)")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                if !contact.phoneNumbers.isEmpty {
                    ForEach(contact.phoneNumbers, id: \.identifier) { phoneNumber in
                        Text(phoneNumber.value.stringValue)
                            .font(.title2)
                            .foregroundColor(.secondary)
                    }
                }
                
                if !contact.emailAddresses.isEmpty {
                    ForEach(contact.emailAddresses, id: \.identifier) { email in
                        Text(email.value as String)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            
            Spacer()
            
            HStack(spacing: 40) {
                VStack {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 24, weight: .medium))
                    Text("Delete")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .opacity(offset.width < -30 ? 1.0 : 0.0)
                
                Spacer()
                
                VStack {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 24, weight: .medium))
                    Text("Keep")
                        .font(.caption)
                        .fontWeight(.medium)
                }
                .foregroundColor(.white)
                .opacity(offset.width > 30 ? 1.0 : 0.0)
            }
            .padding(.horizontal, 60)
            .padding(.bottom, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBackgroundColor)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color(.systemGray4), lineWidth: 1)
                .opacity(abs(offset.width) < 30 ? 1 : 0)
        )
        .shadow(radius: 10)
        .offset(x: offset.width, y: offset.height * 0.4)
        .rotationEffect(.degrees(Double(offset.width / 10)))
        .gesture(
            DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                }
                .onEnded { gesture in
                    if abs(offset.width) > 100 {
                        if offset.width > 0 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset.width = 500
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipeRight()
                                offset = .zero
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                offset.width = -500
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                onSwipeLeft()
                                offset = .zero
                            }
                        }
                    } else {
                        withAnimation(.spring()) {
                            offset = .zero
                        }
                    }
                }
        )
    }
}