import SwiftUI

private struct HelpTopic: Identifiable {
    let id: String
    let title: String
    let detail: String
    let systemImage: String
}

private struct HelpFlowStep: Identifiable {
    let id: Int
    let title: String
    let detail: String
}

struct HelpCenterView: View {
    let viewModel: AppViewModel?

    @State private var expandedTopics: Set<String> = ["budgets"]

    private let topics: [HelpTopic] = [
        HelpTopic(
            id: "setupFamily",
            title: "¿Cómo debería empezar con mi cuenta?",
            detail: "Crea o inicia sesión en tu cuenta de SpendSage primero, luego define tu presupuesto y tu primera meta para que la app pueda personalizar el siguiente paso.",
            systemImage: "iphone.gen3"
        ),
        HelpTopic(
            id: "budgets",
            title: "¿Qué cambia realmente el asistente de presupuesto?",
            detail: "Guarda localmente tu ingreso mensual y tu presupuesto mensual. Inicio y Análisis usan esos valores para calcular margen restante, utilización y ritmo.",
            systemImage: "wand.and.stars"
        ),
        HelpTopic(
            id: "scanAutosave",
            title: "¿Por qué algunas herramientas avanzadas no están disponibles aquí?",
            detail: "Algunas herramientas dependen de acceso de cuenta o servicios conectados. Hasta que eso esté activo, la app mantiene el camino freemium enfocado en flujos privados dentro del dispositivo.",
            systemImage: "lock.shield.fill"
        ),
        HelpTopic(
            id: "insightsLanguage",
            title: "¿Dónde ajusto la experiencia?",
            detail: "Usa Ajustes para idioma, moneda, tema y recordatorios. Ajustes avanzados es donde revisas exportaciones, diagnósticos y paquetes listos para soporte.",
            systemImage: "slider.horizontal.3"
        ),
        HelpTopic(
            id: "security",
            title: "¿Cómo funciona el paso a soporte y legal?",
            detail: "Los paquetes de soporte se generan localmente y solo se comparten cuando tú decides hacerlo. El Centro legal abre los documentos de privacidad, términos y soporte de esta build.",
            systemImage: "lifepreserver.fill"
        )
    ]

    private let flow: [HelpFlowStep] = [
        HelpFlowStep(id: 1, title: "Empieza por el presupuesto", detail: "Abre el asistente, define ingreso y presupuesto y luego revisa tu margen restante."),
        HelpFlowStep(id: 2, title: "Construye tu libro local", detail: "Agrega gastos, cuentas, facturas y reglas para que los resúmenes y exportaciones sean más útiles."),
        HelpFlowStep(id: 3, title: "Usa el soporte cuando haga falta", detail: "Si algo se siente raro, abre el Centro de soporte y genera un paquete antes de escribir."),
    ]

    init(viewModel: AppViewModel? = nil) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        BrandCardHeader(
                            badgeText: "Ayuda rápida",
                            badgeSystemImage: "questionmark.circle.fill",
                            title: "Centro de ayuda",
                            summary: "Encuentra la respuesta rápida, abre soporte si hace falta y revisa lo legal solo cuando realmente lo necesites.",
                            titleSize: 32
                        ) {
                            MascotAvatarView(character: .mei, expression: .happy, size: 76)
                        }

                        BrandScenePanel(
                            sceneKey: "guide_22_help_center_ludo",
                            fallbackSystemImage: "questionmark.circle.fill",
                            height: 184
                        )
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Preguntas frecuentes")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        ForEach(topics) { topic in
                            DisclosureGroup(isExpanded: expansionBinding(for: topic.id)) {
                                Text(topic.detail.appLocalized)
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                                    .padding(.top, 8)
                            } label: {
                                FinanceToolRowLabel(
                                    title: topic.title,
                                    summary: "Toca para abrir la respuesta.",
                                    systemImage: topic.systemImage
                                )
                            }

                            if topic.id != topics.last?.id {
                                Divider()
                            }
                        }
                    }
                }

                ExperienceDisclosureCard(
                    title: "Ruta recomendada",
                    summary: "Déjala cerrada si ya conoces la app. Ábrela solo si quieres el orden sugerido para empezar.",
                    character: .tikki,
                    expression: .thinking
                ) {
                    ForEach(flow) { step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(step.id)")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(BrandTheme.primary)
                                .clipShape(Circle())

                            VStack(alignment: .leading, spacing: 4) {
                                Text(step.title.appLocalized)
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text(step.detail.appLocalized)
                                    .font(.subheadline)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Más ayuda")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Pasa de la respuesta rápida a la acción con rutas claras hacia soporte y documentos legales.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)

                        if let viewModel {
                            NavigationLink {
                                SupportCenterView(viewModel: viewModel)
                            } label: {
                                helpRouteLabel(
                                    title: "Abrir Centro de soporte",
                                    summary: "Crea un paquete, copia el diagnóstico y abre un borrador de correo.",
                                    systemImage: "lifepreserver.fill"
                                )
                            }
                            .buttonStyle(.plain)
                        }

                        NavigationLink {
                            LegalCenterView()
                        } label: {
                            helpRouteLabel(
                                title: "Abrir Centro legal",
                                summary: "Revisa privacidad, términos y los enlaces públicos de soporte.",
                                systemImage: "doc.text.fill"
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(24)
        }
        .accessibilityIdentifier("help.screen")
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "help.screen")
        }
        .background(BrandTheme.canvas)
        .background(alignment: .top) {
            BrandBackdropView()
        }
        .navigationTitle("Centro de ayuda")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func expansionBinding(for topicID: String) -> Binding<Bool> {
        Binding(
            get: { expandedTopics.contains(topicID) },
            set: { isExpanded in
                if isExpanded {
                    expandedTopics.insert(topicID)
                } else {
                    expandedTopics.remove(topicID)
                }
            }
        )
    }

    private func helpRouteLabel(title: String, summary: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(BrandTheme.primary)
                .frame(width: 42, height: 42)
                .background(BrandTheme.accent.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title.appLocalized)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary.appLocalized)
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(BrandTheme.muted)
                .padding(.top, 6)
        }
    }
}
