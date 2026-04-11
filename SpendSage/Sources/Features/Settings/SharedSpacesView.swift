import SwiftUI

struct SharedSpacesView: View {
    @ObservedObject var viewModel: AppViewModel
    @Environment(\.shellBottomInset) private var shellBottomInset

    @State private var inviteEmail = ""
    @State private var inviteRole: SpaceRole = .editor
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
            .padding(.bottom, shellBottomInset + 18)
        }
        .scrollBounceBehavior(.basedOnSize, axes: .vertical)
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "sharedSpaces.screen")
        }
        .accessibilityIdentifier("sharedSpaces.screen")
        .background(FinanceScreenBackground())
        .navigationTitle("Espacios")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if let pending = viewModel.pendingInviteCode, acceptCode.isEmpty {
                acceptCode = pending
            }
            await viewModel.refreshSharingState(force: true)
        }
    }

    static func sharedInviteURL(for invite: CreateInviteResult) -> URL? {
        if let url = canonicalInviteURL(code: invite.invite.code) {
            return url
        }
        if let url = canonicalInviteURL(from: invite.webLink) {
            return url
        }
        if let url = canonicalInviteURL(from: invite.deepLink) {
            return url
        }
        return URL(string: invite.deepLink)
    }

    private static func canonicalInviteURL(code: String) -> URL? {
        let trimmedCode = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedCode.isEmpty,
              let encodedCode = trimmedCode.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return nil
        }

        var components = URLComponents()
        components.scheme = "https"
        components.host = "michifinanzas.com"
        components.path = "/invite/\(encodedCode)"
        components.queryItems = [URLQueryItem(name: "code", value: trimmedCode)]
        return components.url
    }

    private static func canonicalInviteURL(from rawLink: String?) -> URL? {
        guard let code = inviteCode(from: rawLink) else { return nil }
        return canonicalInviteURL(code: code)
    }

    private static func inviteCode(from rawLink: String?) -> String? {
        guard let rawLink,
              let url = URL(string: rawLink),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return nil
        }

        if let queryCode = components.queryItems?
            .first(where: { $0.name.lowercased() == "code" })?
            .value?
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !queryCode.isEmpty {
            return queryCode
        }

        let pathSegments = url.pathComponents
            .filter { $0 != "/" }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        if let inviteIndex = pathSegments.firstIndex(where: { $0.lowercased() == "invite" }),
           pathSegments.indices.contains(inviteIndex + 1) {
            let pathCode = pathSegments[inviteIndex + 1]
            return pathCode.isEmpty ? nil : pathCode
        }

        if components.host?.lowercased() == "invite" {
            let trimmedPath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return trimmedPath.isEmpty ? nil : trimmedPath
        }

        return nil
    }

    private var headerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                BrandBadge(text: "Plan familiar", systemImage: "person.3.fill")

                Text("Espacios y familia")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundStyle(BrandTheme.ink)

                Text("Invita a tu hogar con un enlace inteligente y comparte el presupuesto sin pasos manuales.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if let space = viewModel.currentSpace {
                    FlowStack(spacing: 8, rowSpacing: 8) {
                        BrandBadge(text: space.displayTitle, systemImage: space.isPersonalSpace ? "person.fill" : "person.3.fill")
                        BrandBadge(text: roleLabel(viewModel.currentSpaceRole ?? space.role), systemImage: "person.crop.circle.badge.checkmark")
                        if let familyModel = viewModel.familySharingModel {
                            BrandBadge(text: familySeatProgressText(familyModel), systemImage: "person.2.fill")
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
                Text("Tu familia")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                if let familyModel = viewModel.familySharingModel {
                    VStack(alignment: .leading, spacing: 10) {
                        metricRow(title: "Plan", value: planLabel(familyModel.entitlements.ownerPlanId))
                        metricRow(title: "Miembros", value: familySeatProgressText(familyModel))
                        metricRow(title: "Invitaciones pendientes", value: "\(familyModel.pendingInviteCount)")
                    }
                } else {
                    Text("Todavía estamos cargando el estado de tu familia.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                }
            }
        }
    }

    private var inviteComposerCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Invitar a alguien")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                TextField("email@hogar.com", text: $inviteEmail)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(BrandTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                Text("Creamos un enlace inteligente: si ya tiene la app la abrirá, si no la tiene irá a instalarla, y si todavía no entra a su cuenta podrá iniciar sesión o crearla para terminar la invitación.")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)

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
                        Text(invite.emailDelivery?.status == .sent ? "Invitación enviada" : "Invitación lista")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)

                        Text(inviteDeliveryMessage(invite))
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        if let url = inviteShareURL(for: invite) {
                            ShareLink(item: url) {
                                Label("Compartir enlace familiar", systemImage: "square.and.arrow.up")
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
                Text("Invitaciones para ti")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                if !acceptCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Si esta es la cuenta invitada, intentaremos unirla automáticamente a la familia. Si no coincide, cambia de cuenta y vuelve a abrir la invitación.")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    Button("Unirme a la familia") {
                        Task { await viewModel.acceptInvite(code: acceptCode) }
                    }
                    .buttonStyle(PrimaryCTAStyle())
                }

                if !viewModel.myInvites.isEmpty {
                    ForEach(viewModel.myInvites) { invite in
                        inviteRow(invite)
                    }
                } else if acceptCode.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text("Cuando alguien te invite, aparecerá aquí automáticamente al iniciar sesión con el correo correcto.")
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func inviteShareURL(for invite: CreateInviteResult) -> URL? {
        Self.sharedInviteURL(for: invite)
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
                                    Text(roleLabel(member.role))
                                        .font(.footnote)
                                        .foregroundStyle(BrandTheme.muted)
                                }
                                Spacer()
                                if member.role != .owner, viewModel.canManageCurrentSpaceMembers {
                                    Button(member.role == .viewer ? "Permitir edición" : "Solo mirar") {
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
                    Text("Invitaciones activas")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(BrandTheme.ink)

                    ForEach(viewModel.spaceInvites) { invite in
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                            Text(invite.recipientEmailLower)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(BrandTheme.ink)
                                Text("\(roleLabel(invite.role)) · \(inviteStatusLabel(invite.status))")
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
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(invite.inviterEmailLower ?? "Tu familia")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandTheme.ink)
                Text("Te invitó como \(roleLabel(invite.role).lowercased()).")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }

            if invite.status == .pending {
                Button("Unirme a la familia") {
                    Task { await viewModel.acceptInvite(code: invite.code) }
                }
                .buttonStyle(PrimaryCTAStyle())
            } else {
                Text(inviteStatusLabel(invite.status))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)
            }
        }
    }

    private func displayMaxMembers(_ model: FamilySharingModel) -> Int {
        switch model.entitlements.ownerPlanId.lowercased() {
        case "family":
            return min(max(model.maxMembers, 1), 5)
        case "enterprise":
            return min(max(model.maxMembers, 1), 20)
        default:
            return min(max(model.maxMembers, 1), 2)
        }
    }

    private func familySeatProgressText(_ model: FamilySharingModel) -> String {
        "\(model.memberCount)/\(displayMaxMembers(model)) miembros"
    }

    private func planLabel(_ raw: String) -> String {
        switch raw.lowercased() {
        case "family":
            return "Familia"
        case "personal", "pro":
            return "Pro"
        case "enterprise":
            return "Empresa"
        default:
            return "Gratis"
        }
    }

    private func roleLabel(_ role: SpaceRole) -> String {
        switch role {
        case .owner:
            return "Administrador"
        case .editor:
            return "Puede editar"
        case .viewer:
            return "Solo mirar"
        }
    }

    private func inviteStatusLabel(_ status: SpaceInvite.Status) -> String {
        switch status {
        case .pending:
            return "Pendiente"
        case .accepted:
            return "Aceptada"
        case .revoked:
            return "Revocada"
        case .expired:
            return "Expirada"
        }
    }

    private func inviteDeliveryMessage(_ invite: CreateInviteResult) -> String {
        switch invite.emailDelivery?.status {
        case .sent:
            return "Le enviamos un correo. Si ya tiene cuenta, solo debe entrar con ese email; si no, puede crear una cuenta y quedará unido a tu familia."
        case .failed:
            return "No pudimos enviar el correo automáticamente. Comparte este enlace por Mensajes, WhatsApp o Mail."
        case .disabled, .none:
            return "Comparte este enlace por Mensajes, WhatsApp o Mail. Cuando la persona correcta entre con su cuenta, la app intentará completar la unión."
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
