import SwiftUI

/// Turquoise bar shown when the app is offline and is rendering cached data.
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("غير متصل بالإنترنت — تُعرض بيانات مخزّنة")
                .font(.caption.weight(.medium))
            Spacer()
        }
        .foregroundStyle(MFColors.gold)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(MFColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(MFColors.gold.opacity(0.12), lineWidth: 1)
        )
    }
}
