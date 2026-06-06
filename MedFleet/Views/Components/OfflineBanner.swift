import SwiftUI

/// Amber bar shown when the app is offline and is rendering cached data.
struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "wifi.slash")
            Text("غير متصل بالإنترنت — تُعرض بيانات مخزّنة")
                .font(.caption.weight(.medium))
            Spacer()
        }
        .foregroundStyle(Color(red: 0.55, green: 0.40, blue: 0.05))
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(red: 1.0, green: 0.93, blue: 0.70))
    }
}
