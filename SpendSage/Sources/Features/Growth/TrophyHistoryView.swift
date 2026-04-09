import SwiftUI

struct TrophyHistoryView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.shellBottomInset) private var shellBottomInset

    private let collectionColumns = [GridItem(.adaptive(minimum: 250), spacing: 14)]

    private var growthSnapshot: DashboardGrowthSnapshot {
        viewModel.growthSnapshot ?? GrowthSnapshotBuilder.build(
            session: viewModel.session,
            state: viewModel.dashboardState,
            ledger: viewModel.ledger,
            accounts: viewModel.accounts,
            bills: viewModel.bills,
            rules: viewModel.rules,
            profile: viewModel.profile,
            cloudStatus: viewModel.growthCloudStatus
        )
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                heroCard
                missionCollection
                eventCalendarCollection
                trophyCollection
                trophyTimeline
                trophyFootnotes
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, shellBottomInset + 18)
        }
        .background(
            ZStack {
                BrandTheme.canvas
                BrandBackdropView()
            }
            .ignoresSafeArea()
        )
        .accessibilityIdentifier("trophies.screen")
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "trophies.screen")
        }
        .background(alignment: .top) {
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

                Text("Aquí ves tus misiones locales, tus pasos cloud, los retos especiales y los logros que van haciendo más liviano tu presupuesto.")
                    .foregroundStyle(BrandTheme.muted)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                    spacing: 12
                ) {
                    BrandMetricTile(title: "Locales", value: "\(growthSnapshot.localMissions.filter { $0.status == .completed }.count)/\(growthSnapshot.localMissions.count)", systemImage: "house.fill")
                    BrandMetricTile(title: "Cloud", value: "\(growthSnapshot.cloudMissions.filter { $0.status == .completed }.count)/\(growthSnapshot.cloudMissions.count)", systemImage: "icloud.fill")
                    BrandMetricTile(title: "Especiales", value: "\(growthSnapshot.specialMissions.filter { $0.status == .completed }.count)/\(growthSnapshot.specialMissions.count)", systemImage: "sparkles")
                    BrandMetricTile(title: "Logros", value: "\(growthSnapshot.trophies.filter(\.unlocked).count)", systemImage: "rosette")
                }

                BrandArtworkSurface {
                    MascotSpeechCard(
                        character: .manchas,
                        expression: .proud,
                        title: "Tu progreso vive aquí",
                        message: "Cada misión completada hace más claro qué estás cuidando bien y dónde todavía puedes ahorrar un poco más."
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
                    detail: "El tablero se divide por tipo para que sepas rápido qué depende de tus hábitos, qué depende del respaldo cloud y qué misiones especiales están activas."
                )

                missionTrackSection(
                    title: "Local",
                    detail: growthSnapshot.localMissions.isEmpty
                        ? "Aún no hay hábitos locales visibles."
                        : GrowthMissionTrack.local.summary,
                    missions: growthSnapshot.localMissions
                )

                missionTrackSection(
                    title: "Cloud",
                    detail: growthSnapshot.cloudMissions.isEmpty
                        ? "Las misiones cloud aparecen cuando el respaldo y los espacios compartidos ya están disponibles."
                        : GrowthMissionTrack.cloud.summary,
                    missions: growthSnapshot.cloudMissions
                )

                missionTrackSection(
                    title: "Especiales",
                    detail: growthSnapshot.specialMissions.isEmpty
                        ? "Cuando haya un reto grande o evento de temporada, aparecerá aquí."
                        : GrowthMissionTrack.special.summary,
                    missions: growthSnapshot.specialMissions
                )
            }
        }
    }

    private var eventCalendarCollection: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                sectionHeading(
                    title: "Calendario de eventos",
                    detail: "Temporadas pensadas para ayudarte a ordenar gastos típicos del año sin perder el hilo del ahorro."
                )

                ForEach(growthSnapshot.eventCalendar) { event in
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 12) {
                            eventCalendarBadge(event)

                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    BrandBadge(
                                        text: event.isActive ? "Activo" : "Próximo",
                                        systemImage: event.isActive ? "sparkles" : "calendar"
                                    )
                                    Text(event.dateLabel)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(BrandTheme.primary)
                                }

                                Text(event.title.appLocalized)
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)

                                Text(event.detail.appLocalized)
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            Spacer(minLength: 0)
                        }

                        if !event.featuredMissionTitles.isEmpty {
                            FlowStack(spacing: 8, rowSpacing: 8) {
                                ForEach(event.featuredMissionTitles, id: \.self) { title in
                                    StoryTag(text: title.appLocalized, systemImage: "checkmark.seal.fill")
                                }
                            }
                        }
                    }
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
                    detail: "Las misiones y logros están pensados para que ahorrar se sienta claro: registrar, ordenar, anticipar y compartir cuando haga falta."
                )

                Label("Las misiones locales te ayudan a construir el hábito diario de registrar y revisar.", systemImage: "house.fill")
                Label("Las misiones cloud protegen tu respaldo y facilitan compartir el presupuesto con familia.", systemImage: "icloud.fill")
                Label("Las especiales aparecen para empujarte a ahorrar mejor en momentos importantes del año.", systemImage: "sparkles")
            }
            .foregroundStyle(BrandTheme.ink)
        }
    }

    private func missionTrackSection(title: String, detail: String, missions: [GrowthMission]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeading(title: title, detail: detail)

            if missions.isEmpty {
                FinanceEmptyStateCard(
                    title: AppLocalization.localized("Sin misiones %@", arguments: title.lowercased()),
                    summary: detail,
                    systemImage: "sparkles"
                )
            } else {
                LazyVGrid(columns: collectionColumns, spacing: 14) {
                    ForEach(missions) { mission in
                        missionCard(mission)
                    }
                }
            }
        }
    }

    private func missionCard(_ mission: GrowthMission) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                GrowthMissionBadgeView(mission: mission, size: 52)

                Spacer(minLength: 0)

                VStack(alignment: .trailing, spacing: 6) {
                    BrandBadge(text: mission.track.badgeText, systemImage: mission.track.systemImage)
                    BrandBadge(text: mission.status.localizedTitle, systemImage: mission.systemImage)
                }
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

    private func eventCalendarBadge(_ event: GrowthEventCalendarEntry) -> some View {
        ZStack {
            if event.isActive {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BrandTheme.heroGlowGradient)
            } else {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(BrandTheme.surface)
            }

            if let image = BrandAssetCatalog.shared.image(for: BrandAssetCatalog.shared.badge(named: event.badgeAsset)) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .padding(8)
            } else {
                Image(systemName: event.isActive ? "sparkles" : "calendar")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(BrandTheme.primary)
            }
        }
        .frame(width: 56, height: 56)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
        )
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
