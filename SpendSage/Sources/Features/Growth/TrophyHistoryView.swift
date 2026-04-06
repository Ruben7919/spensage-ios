import SwiftUI

struct TrophyHistoryView: View {
    @ObservedObject var viewModel: AppViewModel

    private let collectionColumns = [GridItem(.adaptive(minimum: 250), spacing: 14)]

    private var growthSnapshot: DashboardGrowthSnapshot {
        viewModel.growthSnapshot ?? GrowthSnapshotBuilder.build(
            session: viewModel.session,
            state: viewModel.dashboardState,
            ledger: viewModel.ledger,
            accounts: viewModel.accounts,
            bills: viewModel.bills,
            rules: viewModel.rules,
            profile: viewModel.profile
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                missionCollection
                trophyCollection
                trophyTimeline
                trophyFootnotes
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 40)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .overlay(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Historial de logros")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: AppLocalization.localized("%d desbloqueados", arguments: growthSnapshot.trophies.filter(\.unlocked).count), systemImage: "trophy.fill")

                Text("Colección de logros")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Sigue los logros que hacen que el loop financiero se sienta vivo: rachas, presupuesto sano, categorías limpias y hábitos más fuertes.")
                    .foregroundStyle(BrandTheme.muted)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Nivel", value: "\(growthSnapshot.level)", systemImage: "bolt.fill")
                    BrandMetricTile(title: "XP", value: "\(growthSnapshot.totalXP)", systemImage: "sparkles")
                    BrandMetricTile(title: "Desbloqueados", value: "\(growthSnapshot.trophies.filter(\.unlocked).count)", systemImage: "rosette")
                    BrandMetricTile(title: "Siguiente nivel", value: "\(growthSnapshot.xpToNextLevel) XP", systemImage: "arrow.up.forward")
                }

                BrandArtworkSurface {
                    MascotSpeechCard(
                        character: .manchas,
                        expression: .proud,
                        title: "El progreso vive aquí",
                        message: "Los logros y las rachas reflejan los hábitos que ya se ven en tu libro local."
                    )
                }
            }
        }
    }

    private var trophyCollection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Colección",
                    detail: "Los logros desbloqueados se quedan brillantes; el resto muestra el progreso hacia la siguiente meta visible."
                )

                LazyVGrid(columns: collectionColumns, spacing: 14) {
                    ForEach(growthSnapshot.trophies) { trophy in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                GrowthTrophyPlate(trophy: trophy, size: 52)

                                Spacer(minLength: 0)

                                Text(trophy.unlocked ? "Desbloqueado" : trophy.progressText.appLocalized)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(trophy.unlocked ? BrandTheme.primary : BrandTheme.muted)
                                    .multilineTextAlignment(.trailing)
                                    .lineLimit(2)
                            }

                            Text(trophy.title.appLocalized)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text(trophy.detail.appLocalized)
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)

                            ProgressView(value: trophy.progressRatio)
                                .tint(trophy.unlocked ? BrandTheme.primary : BrandTheme.muted.opacity(0.8))

                            if let unlockedAt = trophy.unlockedAt {
                                Text(unlockedAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.primary)
                            } else {
                                Text(AppLocalization.localized("Siguiente desbloqueo en %@", arguments: trophy.progressText.appLocalized))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(BrandTheme.surfaceTint)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var missionCollection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Misiones",
                    detail: "Aquí ves el tablero completo: lo que ya cerraste, lo que está listo y lo que todavía empuja tu progreso."
                )

                LazyVGrid(columns: collectionColumns, spacing: 14) {
                    ForEach(growthSnapshot.allMissions) { mission in
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(alignment: .top) {
                                GrowthMissionBadgeView(mission: mission, size: 52)

                                Spacer(minLength: 0)

                                BrandBadge(text: mission.status.localizedTitle, systemImage: mission.systemImage)
                            }

                            Text(mission.title.appLocalized)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            Text(mission.detail.appLocalized)
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)

                            ProgressView(value: mission.progressRatio)
                                .tint(mission.status == .completed ? BrandTheme.primary : BrandTheme.muted.opacity(0.8))

                            HStack {
                                Text("\(mission.progressText) · \(mission.rewardXP) XP")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(BrandTheme.primary)

                                Spacer()

                                if mission.isSeasonal {
                                    BrandBadge(text: "Evento", systemImage: "wand.and.stars")
                                } else {
                                    Text(mission.cadenceLabel.appLocalized)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(BrandTheme.muted)
                                }
                            }

                            Text(mission.coachNote.appLocalized)
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(BrandTheme.surfaceTint)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    private var trophyTimeline: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Línea de tiempo",
                    detail: "Una secuencia simple de eventos construida con logros, momentum de categorías y señales del coach."
                )

                if growthSnapshot.events.isEmpty {
                    emptyTimeline
                } else {
                    ForEach(growthSnapshot.events) { event in
                        DashboardTimelineRow(event: event)
                    }
                }
            }
        }
    }

    private var trophyFootnotes: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                sectionHeading(
                    title: "Cómo se consiguen",
                    detail: "Los logros reaccionan a los hábitos visibles en tu libro actual y convierten la rutina financiera en un loop repetible."
                )

                Label("Registrar gastos con constancia acelera los badges basados en rachas.", systemImage: "flame.fill")
                Label("Cuentas, facturas y reglas desbloquean logros más profundos porque el dashboard ve mejor el mes.", systemImage: "square.stack.3d.up")
                Label("Un presupuesto limpio y una revisión frecuente suelen abrir primero las victorias más visibles.", systemImage: "checkmark.seal.fill")
            }
            .foregroundStyle(BrandTheme.ink)
        }
    }

    private var emptyTimeline: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Todavía no hay eventos")
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text("El primer gasto suele desbloquear el primer evento visible en esta línea de tiempo.")
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
    }

    private func sectionHeading(title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.appLocalized)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text(detail.appLocalized)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
        }
    }
}

private struct DashboardTimelineRow: View {
    let event: GrowthEvent

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(BrandTheme.accent.opacity(0.18))
                Image(systemName: event.systemImage)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }
            .frame(width: 42, height: 42)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(event.detail.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                Text(event.occurredAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(BrandTheme.surfaceTint)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
        )
    }
}

struct GrowthTrophyPlate: View {
    let trophy: GrowthTrophy
    var size: CGFloat = 56

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    trophy.unlocked
                        ? BrandTheme.heroGlowGradient
                        : LinearGradient(
                            colors: [BrandTheme.surfaceTint, BrandTheme.surface],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )

            if let image = BrandAssetCatalog.shared.image(for: BrandAssetCatalog.shared.badge(named: trophy.hybridBadgeAsset)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(10)
            } else {
                Image(systemName: trophy.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(trophy.unlocked ? BrandTheme.primary : BrandTheme.muted)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
        )
    }
}

struct GrowthMissionBadgeView: View {
    let mission: GrowthMission
    var size: CGFloat = 52

    var body: some View {
        ZStack {
            if mission.status == .completed {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BrandTheme.heroGlowGradient)
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BrandTheme.surfaceTint)
            }

            if let image = BrandAssetCatalog.shared.image(for: BrandAssetCatalog.shared.badge(named: mission.hybridBadgeAsset)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Image(systemName: mission.systemImage)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(BrandTheme.primary)
            }
        }
        .frame(width: size, height: size)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.82), lineWidth: 1)
        )
    }
}
