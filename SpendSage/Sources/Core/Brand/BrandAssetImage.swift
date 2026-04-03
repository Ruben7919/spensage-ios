import SwiftUI

struct BrandAssetImage: View {
    let source: BrandAssetSource?
    var fallbackSystemImage: String = "sparkles"
    var fallbackTint: Color = BrandTheme.primary

    var body: some View {
        Group {
            if let image = BrandAssetCatalog.shared.image(for: source) {
                Image(uiImage: image)
                    .resizable()
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(BrandTheme.surfaceTint)
                    Image(systemName: fallbackSystemImage)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(fallbackTint)
                }
            }
        }
    }
}
