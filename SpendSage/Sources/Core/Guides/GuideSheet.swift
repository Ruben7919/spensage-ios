import SwiftUI

struct GuideSheet: View {
    let guide: GuideDefinition
    var marksSeenOnDone: Bool = true
    var onDismiss: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var index = 0

    private var isLast: Bool {
        index >= guide.slides.count - 1
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                header

                TabView(selection: $index) {
                    ForEach(Array(guide.slides.enumerated()), id: \.element.id) { slideIndex, slide in
                        ScrollView(showsIndicators: false) {
                            VStack(alignment: .leading, spacing: 18) {
                                GuideArtworkCard(slide: slide)

                                MascotSpeechCard(
                                    character: slide.character,
                                    expression: slide.expression,
                                    title: slide.title.appLocalized,
                                    message: slide.body.appLocalized
                                )

                                Text(AppLocalization.localized("Step %d of %d", arguments: slideIndex + 1, guide.slides.count))
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 18)
                            .padding(.bottom, 10)
                        }
                        .tag(slideIndex)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                footer
            }
            .background(BrandTheme.guideCanvas.ignoresSafeArea())
            .toolbar(.hidden, for: .navigationBar)
        }
        .presentationDetents([.fraction(0.94)])
        .presentationDragIndicator(.visible)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(guide.title.appLocalized)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                GuideStepDots(total: guide.slides.count, current: index)
            }

            Spacer()

            Button("Close".appLocalized) {
                close(markSeen: false)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(BrandTheme.primary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 12)
        .background(BrandTheme.surface.opacity(0.96))
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(BrandTheme.line.opacity(0.45))
                .frame(height: 1)
        }
    }

    private var footer: some View {
        HStack(spacing: 12) {
            Button {
                index = max(0, index - 1)
            } label: {
                Text("Back".appLocalized)
            }
            .buttonStyle(SecondaryCTAStyle())
            .disabled(index == 0)
            .opacity(index == 0 ? 0.55 : 1)

            Button {
                if isLast {
                    close(markSeen: marksSeenOnDone)
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.92)) {
                        index = min(guide.slides.count - 1, index + 1)
                    }
                }
            } label: {
                Text((isLast ? "Done" : "Next").appLocalized)
            }
            .buttonStyle(PrimaryCTAStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 18)
        .background(BrandTheme.surface.opacity(0.96))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(BrandTheme.line.opacity(0.4))
                .frame(height: 1)
        }
    }

    private func close(markSeen: Bool) {
        if markSeen {
            GuideProgressStore.markSeen(guide.id)
        }
        onDismiss?()
        dismiss()
    }
}

private struct GuideArtworkCard: View {
    let slide: GuideSlide

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(BrandTheme.guideArtworkGradient)
                .overlay(
                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.7), lineWidth: 1)
                )
                .shadow(color: BrandTheme.shadow.opacity(0.12), radius: 24, x: 0, y: 16)

            BrandAssetImage(
                source: BrandAssetCatalog.shared.guide(slide.imageKey),
                fallbackSystemImage: "photo.on.rectangle.angled"
            )
            .aspectRatio(contentMode: .fit)
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .center)

            BrandBadge(text: "Guide", systemImage: "sparkles")
                .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 320)
    }
}

private struct GuideStepDots: View {
    let total: Int
    let current: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { idx in
                Capsule(style: .continuous)
                    .fill(idx == current ? BrandTheme.primary : BrandTheme.line.opacity(0.65))
                    .frame(width: idx == current ? 22 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: current)
            }
        }
    }
}
