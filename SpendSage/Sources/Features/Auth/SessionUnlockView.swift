import SwiftUI

struct SessionUnlockView: View {
    let biometricKind: BiometricKind
    let errorMessage: String?
    let isLoading: Bool
    let onUnlock: () -> Void
    let onUseAnotherAccount: () -> Void

    var body: some View {
        ZStack {
            BrandTheme.background.opacity(0.78)
                .ignoresSafeArea()

            VStack(spacing: 18) {
                SurfaceCard {
                    VStack(spacing: 18) {
                        MascotAvatarView(character: .mei, expression: .proud, size: 88)

                        VStack(spacing: 8) {
                            Text("Tu cuenta sigue aquí")
                                .font(.system(size: 28, weight: .black, design: .rounded))
                                .foregroundStyle(BrandTheme.ink)
                                .multilineTextAlignment(.center)

                            Text(
                                AppLocalization.localized(
                                    "Abre MichiFinanzas con %@ o el código del dispositivo y sigue donde te quedaste.",
                                    arguments: biometricKind.displayName
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .multilineTextAlignment(.center)
                        }

                        Label(biometricKind.displayName, systemImage: biometricKind.systemImage)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(BrandTheme.accent.opacity(0.18), in: Capsule())

                        if let errorMessage, !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)
                                .multilineTextAlignment(.center)
                        }

                        Button(isLoading ? "Abriendo tu cuenta…" : AppLocalization.localized("Abrir con %@", arguments: biometricKind.displayName)) {
                            onUnlock()
                        }
                        .buttonStyle(PrimaryCTAStyle())
                        .disabled(isLoading)

                        Button("Usar otra cuenta") {
                            onUseAnotherAccount()
                        }
                        .buttonStyle(SecondaryCTAStyle())
                    }
                }
                .frame(maxWidth: 420)
                .padding(.horizontal, 24)
            }
        }
    }
}

struct SessionRestoreLoadingView: View {
    var body: some View {
        ZStack {
            BrandTheme.background.opacity(0.74)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                YarnLoadingIndicator(size: 22)
                Text("Abriendo tu cuenta guardada…")
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 26)
            .padding(.vertical, 20)
            .background(BrandTheme.surface.opacity(0.94), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
            )
            .shadow(color: BrandTheme.shadow.opacity(0.18), radius: 22, x: 0, y: 12)
        }
    }
}
