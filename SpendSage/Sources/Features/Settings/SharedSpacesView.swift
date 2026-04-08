import SwiftUI

struct SharedSpacesView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.shellBottomInset) private var shellBottomInset

    @State private var inviteEmail = ""
    @State private var inviteRole: SpaceRole = .viewer
    @State private var inviteExpiryDays = 14
    @State private var acceptCode = ""

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerCard
                spacePickerCard
                familyStatusCard
                inviteComposerCard
                inviteInboxCard
                membersCard
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, shellBottomInset > 0 ? 12 : 40)
        }
        .background(FinanceScreenBackground())
        .navigationTitle("Spaces")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let pending = viewModel.pendingInviteCode, acceptCode.isEmpty {
                acceptCode = pending
            }
            await viewModel.refreshSharingState(force: true)
        }
    }

    private var headerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: "Cloud sharing", systemImage: "person.3.fill")

                Text("Spaces y familia")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Selecciona el espacio activo, invita miembros y controla quién puede editar o solo mirar.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if let space = viewModel.currentSpace {
                    FlowStack(spacing: 8, rowSpacing: 8) {
                        BrandBadge(text: space.displayTitle, systemImage: space.isPersonalSpace ? "person.fill" : "person.3.fill")
                        BrandBadge(text: viewModel.currentSpaceRole?.displayName ?? space.role.displayName, systemImage: "person.crop.circle.badge.checkmark")
                        if let familyModel = viewModel.familySharingModel {
                            BrandBadge(text: "\(familyModel.memberCount)/\(familyModel.maxMembers) miembros", systemImage: "person.2.fill")
                        }
                    }
                }

                if let sharingStatusError = viewModel.sharingStatusError {
                    Text(sharingStatusError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }
        }
    }

    private var spacePickerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Espacio activo")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                if viewModel.spaces.isEmpty {
                    Text("No hay espacios disponibles todavía.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                } else {
                    Picker("Espacio", selection: bindingForCurrentSpaceID()) {
                        ForEach(viewModel.spaces) { space in
                            Text(space.displayTitle).tag(Optional(space.spaceId))
                        }
                    }
                    .pickerStyle(.segmented)
                }
            }
        }
    }

    private var familyStatusCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Estado family")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                if let familyModel = viewModel.familySharingModel {
                    VStack(alignment: .leading, spacing: 10) {
                        metricRow(title: "Modo", value: familyModel.mode.capitalized)
                        metricRow(title: "Slots libres", value: "\(familyModel.remainingSlots)")
                        metricRow(title: "Owner plan", value: familyModel.entitlements.ownerPlanId.capitalized)
                        metricRow(title: "Invites pendientes", value: "\(familyModel.pendingInviteCount)")
                    }
                } else {
                    Text("Todavía no hay estado family cargado para este espacio.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
    }

    private var inviteComposerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Invitar miembro")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                TextField("email@hogar.com", text: $inviteEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(BrandTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Picker("Rol", selection: $inviteRole) {
                    Text("Viewer").tag(SpaceRole.viewer)
                    Text("Editor").tag(SpaceRole.editor)
                }
                .pickerStyle(.segmented)

                Stepper("Expira en \(inviteExpiryDays) días", value: $inviteExpiryDays, in: 1...60)

                Button("Crear invitación") {
                    Task {
                        await viewModel.createFamilyInvite(
                            recipientEmail: inviteEmail,
                            role: inviteRole,
                            expiresInDays: inviteExpiryDays
                        )
                    }
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(inviteEmail.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !(viewModel.familySharingModel?.permissions.canInvite ?? false))

                if let invite = viewModel.lastCreatedInvite {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Última invitación")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)

                        Text(invite.deepLink)
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                            .textSelection(.enabled)

                        if let url = URL(string: invite.deepLink) {
                            ShareLink(item: url) {
                                Label("Compartir deep link", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }
                    }
                }
            }
        }
    }

    private var inviteInboxCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Aceptar invitación")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                TextField("Código de invitación", text: $acceptCode)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(BrandTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Button("Aceptar") {
                    Task { await viewModel.acceptInvite(code: acceptCode) }
                }
                .buttonStyle(PrimaryCTAStyle())
                .disabled(acceptCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                if !viewModel.myInvites.isEmpty {
                    Divider()
                    Text("Mis invitaciones")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BrandTheme.ink)

                    ForEach(viewModel.myInvites) { invite in
                        inviteRow(invite)
                    }
                }
            }
        }
    }

    private var membersCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Miembros e invitaciones")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                if viewModel.spaceMembers.isEmpty {
                    Text("Todavía no hay miembros visibles para este espacio.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                } else {
                    ForEach(viewModel.spaceMembers) { member in
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(member.userEmailLower ?? member.userId)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(BrandTheme.ink)
                                    Text(member.role.displayName)
                                        .font(.footnote)
                                        .foregroundStyle(BrandTheme.muted)
                                }
                                Spacer()
                                if member.role != .owner, viewModel.canManageCurrentSpaceMembers {
                                    Button(member.role == .viewer ? "Promover" : "Pasar a viewer") {
                                        Task {
                                            await viewModel.updateSpaceMember(
                                                member.userId,
                                                role: member.role == .viewer ? .editor : .viewer
                                            )
                                        }
                                    }
                                    .buttonStyle(SecondaryCTAStyle())
                                }
                            }

                            if viewModel.canManageCurrentSpaceMembers && member.role != .owner {
                                Button("Quitar del espacio") {
                                    Task { await viewModel.removeSpaceMember(member.userId) }
                                }
                                .buttonStyle(.bordered)
                                .tint(.red)
                            }
                        }
                        if member.id != viewModel.spaceMembers.last?.id {
                            Divider()
                        }
                    }
                }

                if !viewModel.spaceInvites.isEmpty {
                    Divider()
                    Text("Invites activos")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BrandTheme.ink)

                    ForEach(viewModel.spaceInvites) { invite in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(invite.recipientEmailLower)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(BrandTheme.ink)
                                Text("\(invite.role.displayName) · \(invite.status.rawValue)")
                                    .font(.footnote)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                            Spacer()
                            if viewModel.canManageCurrentSpaceMembers {
                                Button("Revocar") {
                                    Task { await viewModel.revokeSpaceInvite(invite.code) }
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                    }
                }
            }
        }
    }

    private func metricRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrandTheme.ink)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
        }
    }

    private func inviteRow(_ invite: SpaceInvite) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(invite.recipientEmailLower)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrandTheme.ink)
            Text("\(invite.status.rawValue) · \(invite.role.displayName)")
                .font(.footnote)
                .foregroundStyle(BrandTheme.muted)
        }
    }

    private func bindingForCurrentSpaceID() -> Binding<String?> {
        Binding(
            get: { viewModel.currentSpaceID },
            set: { nextValue in
                guard let nextValue else { return }
                Task { await viewModel.selectSpace(nextValue) }
            }
        )
    }
}
