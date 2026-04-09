import Foundation
import PhotosUI
import SwiftUI
import UIKit
import VisionKit

struct FinanceReceiptScanToolView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode
    @Environment(\.shellBottomInset) private var shellBottomInset

    @State private var merchant = ""
    @State private var amount = ""
    @State private var category = ExpenseCategory.groceries
    @State private var date = Date()
    @State private var note = ""
    @State private var capturedImage: UIImage?
    @State private var captureSource: ReceiptCaptureSource?
    @State private var captureDate: Date?
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var isPresentingCamera = false
    @State private var isPresentingGuide = false
    @State private var isLoadingPhoto = false
    @State private var isAnalyzingReceipt = false
    @State private var isSavingDraft = false
    @State private var errorMessage: String?
    @State private var lastSavedSummary: String?
    @State private var receiptAnalysis: ReceiptScanAnalysis?
    @State private var analysisToken = UUID()
    @State private var currentStep: ReceiptWizardStep = .capture
    @State private var isApplyingAutofill = false
    @State private var isCategoryLockedByUser = false
    @State private var isDateLockedByUser = false
    @State private var hasAppliedDebugState = false
    @State private var hasAttemptedAutomaticCamera = false
    @State private var didCaptureInCurrentCameraSession = false
    @State private var showCaptureFallback = false

    private var parsedAmount: Decimal? {
        FinanceToolFormatting.decimal(from: amount)
    }

    private var canSave: Bool {
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsedAmount else { return false }
        return !trimmedMerchant.isEmpty && parsedAmount > 0 && !isSavingDraft
    }

    private var recentExpenseItems: [ExpenseItem] {
        viewModel.ledger?.recentExpenseItems(limit: 3) ?? []
    }

    private var merchantSuggestions: [MerchantAutofillSuggestion] {
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedMerchant.isEmpty {
            return viewModel.ledger?.merchantSuggestions(limit: 4) ?? []
        }
        return viewModel.ledger?.merchantSuggestions(matching: trimmedMerchant, limit: 4) ?? []
    }

    private var suggestedCategory: ExpenseCategory? {
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMerchant.isEmpty else { return nil }
        return viewModel.ledger?.inferredCategory(for: trimmedMerchant)
    }

    private var merchantAutofillSuggestion: MerchantAutofillSuggestion? {
        viewModel.ledger?.autofillSuggestion(for: merchant)
    }

    private var exactMerchantMatch: MerchantAutofillSuggestion? {
        viewModel.ledger?.exactMerchantMatch(for: merchant)
    }

    private var currentStatus: ReceiptScanStatusDescriptor {
        if let errorMessage, !errorMessage.isEmpty {
            return .failed(errorMessage)
        }

        if isSavingDraft {
            return .saving
        }

        if isAnalyzingReceipt {
            return .analyzing
        }

        if let lastSavedSummary {
            return .saved(lastSavedSummary)
        }

        switch currentStep {
        case .capture:
            return .capture
        case .autofill:
            return .autofill
        case .review:
            return canSave ? .reviewReady : .reviewPending
        }
    }

    private var prefersCompactGuidance: Bool {
        GuideProgressStore.isSeen(.scan) || (viewModel.dashboardState?.transactionCount ?? 0) >= 3
    }

    private var statusSummaryText: String {
        guard prefersCompactGuidance else { return currentStatus.summary }

        if errorMessage != nil || isSavingDraft || isAnalyzingReceipt || lastSavedSummary != nil {
            return currentStatus.summary
        }

        switch currentStep {
        case .capture:
            return "Foto primero. También puedes seguir sin imagen.".appLocalized
        case .autofill:
            return "Corrige comercio, monto y fecha antes de revisar.".appLocalized
        case .review:
            return canSave
                ? "Última revisión y guardado local.".appLocalized
                : "Falta comercio o monto para guardar.".appLocalized
        }
    }

    private var shouldShowStatusCard: Bool {
        currentStep != .capture || errorMessage != nil || isSavingDraft || isAnalyzingReceipt || lastSavedSummary != nil
    }

    private var shouldAutoOpenCamera: Bool {
        ProcessInfo.processInfo.environment["SPENDSAGE_DEBUG_DISABLE_AUTO_CAMERA"] == nil
    }

    private var showsStepActionBar: Bool {
        currentStep == .autofill || currentStep == .review
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Tres pasos rápidos",
                    title: "Escaneo de recibos",
                    summary: prefersCompactGuidance
                        ? "Foto, confirma y guarda. El detalle extra queda escondido hasta que lo necesites."
                        : "Toma la foto, confirma el autollenado y revisa una vez antes de guardar localmente.",
                    systemImage: "camera.viewfinder",
                    character: .mei,
                    expression: .thinking,
                    sceneKey: "guide_05_scan_receipt_mei"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                if currentStep == .capture && showCaptureFallback {
                    captureQuickStartCard
                }

                if shouldShowStatusCard {
                    wizardStatusCard
                }
                stepContent
            }
            .padding(24)
            .padding(.bottom, (showsStepActionBar ? 110 : 24) + shellBottomInset)
        }
        .accessibilityIdentifier("scan.screen")
        .overlay(alignment: .topLeading) {
            AccessibilityProbe(identifier: "scan.screen")
        }
        .background(FinanceScreenBackground())
        .navigationTitle("Escaneo de recibos")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if showsStepActionBar {
                stepActionBar
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingGuide = true
                } label: {
                    Label("Guía", systemImage: "questionmark.circle")
                        .font(.subheadline.weight(.semibold))
                }
                .tint(BrandTheme.primary)
            }
        }
        .task {
            if viewModel.ledger == nil {
                await viewModel.refreshDashboard()
            }
        }
        .task(id: viewModel.scanFlowID) {
            applyDebugLaunchStateIfNeeded()
            await triggerAutomaticCameraIfNeeded()
        }
        .task(id: photoPickerItem) {
            await loadPhotoSelection()
        }
        .sheet(isPresented: $isPresentingCamera, onDismiss: handleCameraDismiss) {
            ReceiptCameraSheet(photoPickerItem: $photoPickerItem) { image in
                didCaptureInCurrentCameraSession = true
                attachImage(image, source: .camera)
            }
        }
        .sheet(isPresented: $isPresentingGuide) {
            GuideSheet(guide: GuideLibrary.guide(.scan))
        }
        .onChange(of: merchant) { _, _ in
            clearTransientState()
            applyMerchantAutofillIfNeeded(for: merchant)
        }
        .onChange(of: amount) { _, _ in
            clearTransientState()
        }
        .onChange(of: category) { _, _ in
            if currentStep == .autofill && !isApplyingAutofill {
                isCategoryLockedByUser = true
            }
            clearTransientState()
        }
        .onChange(of: date) { _, _ in
            if currentStep == .autofill && !isApplyingAutofill {
                isDateLockedByUser = true
            }
            clearTransientState()
        }
        .onChange(of: note) { _, _ in
            clearTransientState()
        }
        .onChange(of: photoPickerItem) { _, newValue in
            guard newValue != nil else { return }
            didCaptureInCurrentCameraSession = true
            isPresentingCamera = false
        }
    }

    private var wizardStatusCard: some View {
        SurfaceCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: currentStatus.systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(currentStatus.tint)
                    .frame(width: 48, height: 48)
                    .background(currentStatus.tint.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 8) {
                    Text(currentStatus.title)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text(statusSummaryText)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        BrandBadge(
                            text: "Paso \(currentStep.number) de \(ReceiptWizardStep.allCases.count)",
                            systemImage: currentStep.systemImage
                        )

                        if let captureSource {
                            BrandBadge(
                                text: captureSource.metricLabel,
                                systemImage: captureSource.systemImage
                            )
                        }
                    }
                }
            }
        }
    }

    private var wizardProgressCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Flujo guiado")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                HStack(spacing: 12) {
                    ForEach(ReceiptWizardStep.allCases) { step in
                        ReceiptWizardStepCard(
                            step: step,
                            state: stepState(for: step)
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .capture:
            captureStepCard
        case .autofill:
            autofillStepCard
        case .review:
            reviewStepCard
        }
    }

    private var captureStepCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            if capturedImage != nil || isLoadingPhoto {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        CompactSectionHeader(
                            title: "Recibo listo",
                            detail: "Cuando la captura termina, SpendSage llena el borrador editable para que solo confirmes y guardes."
                        )

                        ReceiptImagePreviewCard(
                            image: capturedImage,
                            source: captureSource,
                            capturedAt: captureDate,
                            isBusy: isLoadingPhoto,
                            onRemove: removeAttachedImage
                        )
                    }
                }
            }

            if showCaptureFallback {
                photoTipsCard
            }
        }
    }

    private var captureQuickStartCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                CompactSectionHeader(
                    title: "Si no usas la cámara ahora",
                    detail: "Importa una foto o pasa a registro manual. El flujo de escaneo principal ya intenta abrir la cámara apenas entras."
                )

                captureActionsStack
            }
        }
    }

    private var captureActionsStack: some View {
        let photoPickerTitle = capturedImage == nil ? "Importar desde Fotos" : "Reemplazar desde Fotos"

        return VStack(spacing: 12) {
            Button {
                openCamera()
            } label: {
                ReceiptActionLabel(
                    title: capturedImage == nil ? "Escanear recibo" : "Escanear de nuevo",
                    systemImage: capturedImage == nil ? "doc.viewfinder" : "arrow.clockwise.circle.fill",
                    style: .primary
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("scan.action.openCamera")

            PhotosPicker(selection: $photoPickerItem, matching: .images) {
                ReceiptActionLabel(
                    title: photoPickerTitle,
                    systemImage: "photo.on.rectangle",
                    style: .secondary
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("scan.action.importPhoto")

            Button {
                viewModel.startManualExpenseFlow()
            } label: {
                ReceiptActionLabel(
                    title: "Registrar manualmente",
                    systemImage: "square.and.pencil",
                    style: .secondary
                )
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("scan.action.manual")
        }
    }

    private var autofillStepCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    stepHeader(
                        for: .autofill,
                        title: "Confirma el autollenado",
                        summary: capturedImage == nil
                            ? (prefersCompactGuidance
                                ? "No hay foto, así que aquí completas lo esencial."
                                : "No hay foto adjunta, así que este paso es manual. Completa lo esencial y continúa.")
                            : (prefersCompactGuidance
                                ? "Revisa comercio, monto y fecha antes de pasar al guardado."
                                : "SpendSage ya leyó la foto y llenó una primera versión de comercio, total y fecha. Corrige lo que veas raro antes de revisar.")
                    )

                    if capturedImage != nil || isLoadingPhoto {
                        ReceiptImagePreviewCard(
                            image: capturedImage,
                            source: captureSource,
                            capturedAt: captureDate,
                            isBusy: isLoadingPhoto,
                            onRemove: removeAttachedImage
                        )
                    }

                    if isAnalyzingReceipt {
                        receiptCallout(
                            systemImage: "text.viewfinder",
                            tint: BrandTheme.primary,
                            title: "Leyendo el recibo",
                            summary: "SpendSage está leyendo la foto en el dispositivo y completará los campos con las coincidencias más seguras."
                        )
                    } else if let receiptAnalysis, receiptAnalysis.hasDetectedValues {
                        receiptCallout(
                            systemImage: "sparkles.rectangle.stack",
                            tint: BrandTheme.primary,
                            title: "Sugerencias aplicadas",
                            summary: "Los valores detectados ya llegaron al borrador. Revísalos una vez y sigue."
                        )
                    } else if capturedImage != nil {
                        receiptCallout(
                            systemImage: "square.and.pencil",
                            tint: .orange,
                            title: "Falta confirmación manual",
                            summary: "La imagen ya está adjunta, pero al borrador todavía le faltan algunos datos antes de revisarlo."
                        )
                    }

                    if let suggestedCategory {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .foregroundStyle(.orange)
                            Text(AppLocalization.localized("Sugerencia de regla: %@", arguments: suggestedCategory.localizedTitle))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.ink)
                            Spacer()
                            Button("Usar") {
                                applySuggestedCategory(suggestedCategory)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(BrandTheme.surfaceTint)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    FinanceField(
                        label: "Comercio",
                        placeholder: "Blue Bottle Coffee",
                        text: $merchant,
                        accessibilityIdentifier: "scan.field.merchant"
                    )
                    FinanceField(
                        label: "Monto",
                        placeholder: "8.75",
                        text: $amount,
                        keyboard: .decimalPad,
                        capitalization: .never,
                        accessibilityIdentifier: "scan.field.amount"
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Categoría")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)

                        Picker("Categoría", selection: $category) {
                            ForEach(ExpenseCategory.allCases) { item in
                                Label(item.localizedTitle, systemImage: item.symbolName)
                                    .tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    DatePicker("Fecha del recibo", selection: $date, displayedComponents: .date)
                        .tint(BrandTheme.primary)

                    FinanceMultilineField(
                        label: "Nota",
                        placeholder: "Añade productos, contexto de reembolso o cualquier detalle que quieras recordar después.",
                        text: $note,
                        accessibilityIdentifier: "scan.field.note"
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }

            if shouldShowSmartFillSupport {
                smartFillSupportCard
            }

        }
    }

    private var reviewStepCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    stepHeader(
                        for: .review,
                        title: "Revisa una vez y guarda",
                        summary: "Esta es la última comprobación antes de guardar el gasto en tu registro local."
                    )

                    draftPreviewRow

                    VStack(spacing: 12) {
                        reviewRow(
                            title: "Comercio",
                            value: merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Falta" : merchant,
                            systemImage: "building.2.crop.circle"
                        )
                        reviewRow(
                            title: "Monto",
                            value: parsedAmount?.formatted(.currency(code: currencyCode)) ?? "Falta",
                            systemImage: "dollarsign.circle"
                        )
                        reviewRow(
                            title: "Categoría",
                            value: category.localizedTitle,
                            systemImage: category.symbolName
                        )
                        reviewRow(
                            title: "Fecha",
                            value: date.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        reviewRow(
                            title: "Origen",
                            value: captureSource?.title ?? "Borrador manual".appLocalized,
                            systemImage: captureSource?.systemImage ?? "square.and.pencil"
                        )
                    }

                    if !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nota")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)
                            Text(note)
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(BrandTheme.surfaceTint)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    Text("Lo que guardes aquí se queda en este dispositivo. Nada se comparte ni se sincroniza todavía.")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }
            }

            if capturedImage != nil {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recibo adjunto")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        ReceiptSnapshotRow(
                            image: capturedImage,
                            source: captureSource,
                            capturedAt: captureDate
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var stepActionBar: some View {
        VStack(spacing: 0) {
            Divider()

            HStack(spacing: 12) {
                switch currentStep {
                case .capture:
                    EmptyView()

                case .autofill:
                    Button("Atrás") {
                        transitionToStep(.capture)
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .accessibilityIdentifier("scan.action.backToCapture")

                    Button("Revisar gasto") {
                        goToReview()
                    }
                    .buttonStyle(PrimaryCTAStyle())
                    .disabled(!canSave || isAnalyzingReceipt)
                    .opacity((canSave && !isAnalyzingReceipt) ? 1 : 0.7)
                    .accessibilityIdentifier("scan.action.review")

                case .review:
                    Button("Atrás") {
                        transitionToStep(.autofill)
                    }
                    .buttonStyle(SecondaryCTAStyle())
                    .accessibilityIdentifier("scan.action.backToAutofill")

                    Button {
                        Task { await saveDraft() }
                    } label: {
                        Label(
                            isSavingDraft ? "Guardando localmente..." : "Guardar gasto",
                            systemImage: isSavingDraft ? "hourglass" : "tray.and.arrow.down.fill"
                        )
                    }
                    .buttonStyle(PrimaryCTAStyle())
                    .disabled(!canSave)
                    .opacity(canSave ? 1 : 0.7)
                    .accessibilityIdentifier("scan.action.save")
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 20)
            .background(
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay(BrandTheme.canvas.opacity(0.9))
            )
        }
    }

    private var photoTipsCard: some View {
        Group {
            if prefersCompactGuidance {
                ExperienceDisclosureCard(
                    title: "Consejos para la foto",
                    summary: "Ábrelos solo si el OCR falla o si la captura sale dudosa.",
                    character: .mei,
                    expression: .thinking
                ) {
                    photoTipsContent
                }
            } else {
                SurfaceCard {
                    photoTipsContent
                }
            }
        }
    }

    private var photoTipsContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Consejos para la foto")
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)

            BrandFeatureRow(
                systemImage: "sun.max.fill",
                title: "Usa luz pareja",
                detail: "Evita reflejos y sombras duras para que el total y el comercio se lean mejor."
            )

            BrandFeatureRow(
                systemImage: "viewfinder",
                title: "Llena el encuadre",
                detail: "Mantén el recibo plano y centrado. Mucho fondo extra baja la calidad del OCR."
            )

            BrandFeatureRow(
                systemImage: "square.and.pencil",
                title: "Tú confirmas el borrador",
                detail: "SpendSage completa sugerencias en el dispositivo, pero nada se guarda hasta que tú lo confirmes."
            )
        }
    }

    private var shouldShowSmartFillSupport: Bool {
        receiptAnalysis?.hasDetectedValues == true
            || merchantAutofillSuggestion != nil
            || !recentExpenseItems.isEmpty
            || !merchantSuggestions.isEmpty
    }

    private var smartFillSupportCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Atajos útiles")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text(prefersCompactGuidance
                    ? "Usa estos atajos solo si te ahorran tiempo en este borrador."
                    : "Usa la memoria local de comercios solo cuando de verdad ayude a este borrador.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

                if let receiptAnalysis, receiptAnalysis.hasDetectedValues {
                    FlowStack(spacing: 8, rowSpacing: 8) {
                        if let merchant = receiptAnalysis.merchant {
                            BrandBadge(text: merchant, systemImage: "building.2.crop.circle")
                        }
                        if let amount = receiptAnalysis.amount {
                            BrandBadge(text: amount.formatted(.currency(code: currencyCode)), systemImage: "dollarsign.circle")
                        }
                        if let date = receiptAnalysis.date {
                            BrandBadge(text: date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        }
                    }
                }

                if let suggestion = merchantAutofillSuggestion {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: suggestion.category.symbolName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .frame(width: 40, height: 40)
                            .background(BrandTheme.accent.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Comercio recordado")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text(
                                AppLocalization.localized(
                                    "%@ · %@ · %@",
                                    arguments: suggestion.merchant,
                                    suggestion.lastAmount.formatted(.currency(code: currencyCode)),
                                    suggestion.frequencyLabel
                                )
                            )
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                        }

                        Spacer()

                        Button("Usar") {
                            applyMerchantSuggestion(suggestion, includeMerchant: false)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(BrandTheme.surfaceTint)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }

                if let latest = recentExpenseItems.first {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .frame(width: 40, height: 40)
                            .background(BrandTheme.accent.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Último gasto como plantilla")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text("\(latest.title) · \(latest.category.appLocalized) · \(latest.amount.formatted(.currency(code: currencyCode)))")
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)
                        }

                        Spacer()

                        Button("Usar") {
                            applyTemplate(from: latest)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                if !merchantSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Comercios conocidos" : "Coincidencias")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)

                        FlowStack(spacing: 8, rowSpacing: 8) {
                            ForEach(merchantSuggestions) { suggestion in
                                Button {
                                    applyMerchantSuggestion(suggestion, includeMerchant: true)
                                } label: {
                                    Text(suggestion.merchant)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(BrandTheme.primary)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(BrandTheme.primary.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private var draftPreviewRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: category.symbolName)
                .font(.headline)
                .foregroundStyle(BrandTheme.primary)
                .frame(width: 42, height: 42)
                .background(BrandTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(merchant.isEmpty ? "Vista previa del comercio" : merchant)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text("\(category.localizedTitle) · \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)

                Text(capturedImage == nil ? "Borrador manual sin imagen adjunta." : "Imagen del recibo adjunta para la verificación final.")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }

            Spacer()

            Text((parsedAmount ?? 0), format: .currency(code: currencyCode))
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
        }
        .padding(16)
        .background(BrandTheme.surfaceTint)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.75), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func stepHeader(for step: ReceiptWizardStep, title: String, summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            BrandBadge(text: "Paso \(step.number)", systemImage: step.systemImage)
            Text(title)
                .font(.headline)
                .foregroundStyle(BrandTheme.ink)
            Text(summary)
                .font(.subheadline)
                .foregroundStyle(BrandTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func receiptCallout(
        systemImage: String,
        tint: Color,
        title: String,
        summary: String
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 40, height: 40)
                .background(tint.opacity(0.14))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
                Text(summary)
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(BrandTheme.surfaceTint)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func reviewRow(title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.headline)
                .foregroundStyle(BrandTheme.primary)
                .frame(width: 36, height: 36)
                .background(BrandTheme.primary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.muted)
                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(BrandTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(BrandTheme.surfaceTint)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func stepState(for step: ReceiptWizardStep) -> ReceiptWizardStepState {
        if step == currentStep {
            return .current
        }
        if step.number < currentStep.number {
            return .complete
        }
        return .upcoming
    }

    private func transitionToStep(_ step: ReceiptWizardStep) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.84)) {
            currentStep = step
        }
    }

    private func goToReview() {
        guard !isAnalyzingReceipt else { return }
        guard canSave else {
            errorMessage = "Agrega un comercio y un monto válidos antes de revisar."
            return
        }
        transitionToStep(.review)
    }

    private func triggerAutomaticCameraIfNeeded() async {
        guard shouldAutoOpenCamera else {
            showCaptureFallback = true
            return
        }
        guard !hasAttemptedAutomaticCamera else { return }
        guard currentStep == .capture, capturedImage == nil else { return }
        hasAttemptedAutomaticCamera = true

        try? await Task.sleep(for: .milliseconds(180))
        guard currentStep == .capture, capturedImage == nil else { return }
        openCamera()
    }

    private func handleCameraDismiss() {
        if !didCaptureInCurrentCameraSession && currentStep == .capture && capturedImage == nil {
            showCaptureFallback = true
        }
        didCaptureInCurrentCameraSession = false
    }

    private func openCamera() {
        clearTransientState()
        didCaptureInCurrentCameraSession = false
        guard VNDocumentCameraViewController.isSupported else {
            errorMessage = "Document scan is not available on this device.".appLocalized
            showCaptureFallback = true
            return
        }

        showCaptureFallback = false
        isPresentingCamera = true
    }

    private func loadSampleDraft() {
        applySystemDraftMutation {
            merchant = "Blue Bottle Coffee"
            amount = "8.75"
            category = .coffee
            date = .now
            note = "Local-first receipt draft from an in-store purchase.".appLocalized
        }
        resetDraftLocks()
        clearTransientState()
        transitionToStep(.autofill)
    }

    private func applyDebugLaunchStateIfNeeded() {
        guard !hasAppliedDebugState else { return }
        hasAppliedDebugState = true

        let state = ProcessInfo.processInfo.environment["SPENDSAGE_DEBUG_SCAN_STATE"]?.lowercased()
        switch state {
        case "autofill", "edit":
            loadSampleDraft()
        case "review":
            loadSampleDraft()
            currentStep = .review
        default:
            break
        }
    }

    private func applyTemplate(from item: ExpenseItem) {
        applySystemDraftMutation {
            merchant = item.title
            amount = item.amount.formatted(.number.precision(.fractionLength(2)))
            category = ExpenseCategory.allCases.first(where: { $0.rawValue == item.category }) ?? .other
            date = item.date
            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                note = "Prefilled from recent local activity.".appLocalized
            }
        }
        resetDraftLocks()
        clearTransientState()
    }

    private func applyMerchantSuggestion(_ suggestion: MerchantAutofillSuggestion, includeMerchant: Bool) {
        applySystemDraftMutation {
            if includeMerchant {
                merchant = suggestion.merchant
            }
            amount = suggestion.lastAmount.formatted(.number.precision(.fractionLength(2)))
            category = suggestion.category
            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let lastNote = suggestion.lastNote,
               !lastNote.isEmpty {
                note = lastNote
            }
        }
        isCategoryLockedByUser = true
        clearTransientState()
    }

    private func applyMerchantAutofillIfNeeded(for value: String) {
        guard let suggestion = exactMerchantMatch else { return }

        applySystemDraftMutation {
            if amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                amount = suggestion.lastAmount.formatted(.number.precision(.fractionLength(2)))
            }

            if !isCategoryLockedByUser {
                category = suggestedCategory ?? suggestion.category
            }

            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let lastNote = suggestion.lastNote,
               !lastNote.isEmpty {
                note = lastNote
            }
        }
    }

    private func removeAttachedImage() {
        capturedImage = nil
        captureSource = nil
        captureDate = nil
        receiptAnalysis = nil
        isAnalyzingReceipt = false
        analysisToken = UUID()
        resetDraftLocks()
        clearTransientState()
        showCaptureFallback = true
        transitionToStep(.capture)
    }

    private func attachImage(_ image: UIImage, source: ReceiptCaptureSource) {
        capturedImage = image
        captureSource = source
        captureDate = .now
        receiptAnalysis = nil
        resetDraftLocks()
        clearTransientState()
        showCaptureFallback = false
        transitionToStep(.autofill)
        startReceiptAnalysis(for: image)
    }

    private func clearTransientState() {
        errorMessage = nil
        lastSavedSummary = nil
    }

    private func loadPhotoSelection() async {
        guard let photoPickerItem else { return }

        isLoadingPhoto = true
        clearTransientState()
        defer {
            isLoadingPhoto = false
            self.photoPickerItem = nil
        }

        do {
            guard
                let data = try await photoPickerItem.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else {
                errorMessage = "No se pudo cargar la foto seleccionada."
                return
            }

            attachImage(image, source: .photos)
        } catch {
            errorMessage = "No pudimos importar esa imagen desde Fotos."
        }
    }

    private func saveDraft() async {
        guard let amountValue = parsedAmount, amountValue > 0 else {
            errorMessage = "Ingresa un monto válido."
            transitionToStep(.autofill)
            return
        }

        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMerchant.isEmpty else {
            errorMessage = "Agrega un comercio antes de guardar."
            transitionToStep(.autofill)
            return
        }

        isSavingDraft = true
        errorMessage = nil
        let draft = ExpenseDraft(
            merchant: trimmedMerchant,
            amount: amountValue,
            category: category,
            date: date,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            source: .receiptScan,
            sourceText: receiptAnalysis?.recognizedText ?? ""
        )

        await viewModel.addExpense(draft)

        lastSavedSummary = "\(draft.merchant) · \(draft.amount.formatted(.currency(code: currencyCode)))"
        merchant = ""
        amount = ""
        category = .groceries
        date = .now
        note = ""
        capturedImage = nil
        captureSource = nil
        captureDate = nil
        receiptAnalysis = nil
        isAnalyzingReceipt = false
        isSavingDraft = false
        resetDraftLocks()
        showCaptureFallback = true
        transitionToStep(.capture)
    }

    private func startReceiptAnalysis(for image: UIImage) {
        let token = UUID()
        analysisToken = token
        isAnalyzingReceipt = true

        Task {
            do {
                let analysis = try await ReceiptVisionService.analyze(image: image)
                guard analysisToken == token else { return }
                applyReceiptAnalysis(analysis)
            } catch {
                guard analysisToken == token else { return }
                errorMessage = error.localizedDescription
                isAnalyzingReceipt = false
            }
        }
    }

    private func applyReceiptAnalysis(_ analysis: ReceiptScanAnalysis) {
        receiptAnalysis = analysis

        applySystemDraftMutation {
            if merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let detectedMerchant = analysis.merchant {
                merchant = detectedMerchant
            }

            if amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
               let detectedAmount = analysis.amount {
                amount = detectedAmount.formatted(.number.precision(.fractionLength(2)))
            }

            if !isDateLockedByUser, let detectedDate = analysis.date {
                date = detectedDate
            }

            if !isCategoryLockedByUser,
               let detectedMerchant = analysis.merchant,
               let matchedCategory = viewModel.ledger?.inferredCategory(for: detectedMerchant) ?? analysis.category {
                category = matchedCategory
            }

            if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, analysis.hasDetectedValues {
                note = "Prefilled on device from the receipt scan.".appLocalized
            }
        }

        errorMessage = nil
        isAnalyzingReceipt = false
    }

    private func applySuggestedCategory(_ suggestion: ExpenseCategory) {
        applySystemDraftMutation {
            category = suggestion
        }
        isCategoryLockedByUser = true
        clearTransientState()
    }

    private func applySystemDraftMutation(_ mutation: () -> Void) {
        isApplyingAutofill = true
        mutation()
        DispatchQueue.main.async {
            isApplyingAutofill = false
        }
    }

    private func resetDraftLocks() {
        isCategoryLockedByUser = false
        isDateLockedByUser = false
    }
}

private enum ReceiptWizardStep: Int, CaseIterable, Identifiable {
    case capture = 1
    case autofill = 2
    case review = 3

    var id: Int { rawValue }

    var number: Int { rawValue }

    var title: String {
        switch self {
        case .capture:
            return "Captura".appLocalized
        case .autofill:
            return "Autollenado".appLocalized
        case .review:
            return "Revisión".appLocalized
        }
    }

    var systemImage: String {
        switch self {
        case .capture:
            return "camera.viewfinder"
        case .autofill:
            return "square.and.pencil"
        case .review:
            return "checkmark.circle"
        }
    }
}

private enum ReceiptWizardStepState {
    case complete
    case current
    case upcoming
}

private enum ReceiptCaptureSource {
    case camera
    case photos

    var title: String {
        switch self {
        case .camera:
            return "Captura con cámara".appLocalized
        case .photos:
            return "Foto importada".appLocalized
        }
    }

    var metricLabel: String {
        switch self {
        case .camera:
            return "Cámara".appLocalized
        case .photos:
            return "Fotos".appLocalized
        }
    }

    var systemImage: String {
        switch self {
        case .camera:
            return "camera.fill"
        case .photos:
            return "photo.on.rectangle"
        }
    }
}

private struct ReceiptScanStatusDescriptor {
    let title: String
    let summary: String
    let systemImage: String
    let tint: Color

    static let capture = ReceiptScanStatusDescriptor(
        title: "Paso 1: Captura".appLocalized,
        summary: "Empieza con una foto clara del recibo para que el siguiente paso tenga algo útil que autollenar.".appLocalized,
        systemImage: "camera.viewfinder",
        tint: BrandTheme.primary
    )

    static let autofill = ReceiptScanStatusDescriptor(
        title: "Paso 2: Confirma el autollenado".appLocalized,
        summary: "Las sugerencias del OCR son editables. Corrige aquí el comercio, monto o fecha antes de seguir.".appLocalized,
        systemImage: "square.and.pencil",
        tint: BrandTheme.primary
    )

    static let reviewPending = ReceiptScanStatusDescriptor(
        title: "El paso 3 necesita un borrador válido".appLocalized,
        summary: "Agrega un comercio y un monto positivo en el paso 2 antes de revisar y guardar.".appLocalized,
        systemImage: "exclamationmark.circle.fill",
        tint: .orange
    )

    static let reviewReady = ReceiptScanStatusDescriptor(
        title: "Paso 3: Listo para guardar".appLocalized,
        summary: "Los campos clave ya están listos. Revisa una vez y guarda el gasto en tu registro local.".appLocalized,
        systemImage: "checkmark.circle.fill",
        tint: BrandTheme.primary
    )

    static let saving = ReceiptScanStatusDescriptor(
        title: "Guardando localmente".appLocalized,
        summary: "El borrador se está guardando en este dispositivo. Ningún servicio en la nube participa en este flujo.".appLocalized,
        systemImage: "arrow.down.circle.fill",
        tint: BrandTheme.primary
    )

    static let analyzing = ReceiptScanStatusDescriptor(
        title: "Leyendo recibo".appLocalized,
        summary: "SpendSage está leyendo la foto en el dispositivo para detectar comercio, total y fecha antes de que revises el borrador.".appLocalized,
        systemImage: "text.viewfinder",
        tint: BrandTheme.primary
    )

    static func saved(_ summary: String) -> ReceiptScanStatusDescriptor {
        ReceiptScanStatusDescriptor(
            title: "Borrador guardado".appLocalized,
            summary: AppLocalization.localized(
                "%@ se añadió a tu registro local. Empieza el siguiente recibo cuando quieras.",
                arguments: summary
            ),
            systemImage: "tray.and.arrow.down.fill",
            tint: BrandTheme.primary
        )
    }

    static func failed(_ message: String) -> ReceiptScanStatusDescriptor {
        ReceiptScanStatusDescriptor(
            title: "Necesita atención".appLocalized,
            summary: message,
            systemImage: "exclamationmark.triangle.fill",
            tint: .red
        )
    }
}

private enum ReceiptActionStyle {
    case primary
    case secondary
}

private struct ReceiptActionLabel: View {
    let title: String
    let systemImage: String
    let style: ReceiptActionStyle

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .foregroundStyle(style == .primary ? Color.white : BrandTheme.ink)
            .background(backgroundView)
            .overlay(borderView)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .shadow(color: shadowColor, radius: 14, x: 0, y: 8)
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(style == .primary ? BrandTheme.primary : BrandTheme.surfaceTint)
    }

    @ViewBuilder
    private var borderView: some View {
        if style == .secondary {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(BrandTheme.line.opacity(0.85), lineWidth: 1.2)
        }
    }

    private var shadowColor: Color {
        style == .primary ? BrandTheme.shadow.opacity(0.16) : Color.black.opacity(0.04)
    }
}

private struct ReceiptWizardStepCard: View {
    let step: ReceiptWizardStep
    let state: ReceiptWizardStepState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: iconName)
                    .font(.subheadline.weight(.bold))
                Spacer()
                Text("\(step.number)")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(iconColor)

            Text(step.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(BrandTheme.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(backgroundColor)
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(borderColor, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var iconName: String {
        switch state {
        case .complete:
            return "checkmark.circle.fill"
        case .current:
            return step.systemImage
        case .upcoming:
            return step.systemImage
        }
    }

    private var iconColor: Color {
        switch state {
        case .complete, .current:
            return BrandTheme.primary
        case .upcoming:
            return BrandTheme.muted
        }
    }

    private var backgroundColor: Color {
        switch state {
        case .complete:
            return BrandTheme.accent.opacity(0.2)
        case .current:
            return BrandTheme.surfaceTint
        case .upcoming:
            return BrandTheme.surface
        }
    }

    private var borderColor: Color {
        switch state {
        case .complete, .current:
            return BrandTheme.line.opacity(0.85)
        case .upcoming:
            return BrandTheme.line.opacity(0.55)
        }
    }
}

private struct ReceiptImagePreviewCard: View {
    let image: UIImage?
    let source: ReceiptCaptureSource?
    let capturedAt: Date?
    let isBusy: Bool
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(BrandTheme.surfaceTint)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.75), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 14) {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, minHeight: 220, maxHeight: 340)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 6) {
                            Label(source?.title ?? "Imagen del recibo", systemImage: source?.systemImage ?? "photo")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.primary)

                            Text(imageDetails(for: image))
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)

                            if let capturedAt {
                                Text(AppLocalization.localized("Updated %@", arguments: capturedAt.formatted(date: .abbreviated, time: .shortened)))
                                    .font(.footnote)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }

                        Spacer()

                        Button("Quitar") {
                            onRemove()
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                    }
                } else if isBusy {
                    VStack(spacing: 14) {
                        MascotAvatarView(character: .mei, expression: .excited, size: 64)

                        YarnLoadingIndicator(size: 22)

                        Text("Importando imagen...")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Estamos preparando la foto seleccionada para que el flujo pase al paso de autollenado.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, minHeight: 240)
                } else {
                    VStack(spacing: 14) {
                        Image(systemName: "doc.viewfinder")
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .frame(width: 70, height: 70)
                            .background(BrandTheme.accent.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                        Text("No hay imagen de recibo adjunta")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Usa la cámara para una captura nueva, importa una foto desde tu biblioteca o sigue manualmente si solo necesitas un gasto rápido.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 340)
                    }
                    .frame(maxWidth: .infinity, minHeight: 240)
                }
            }
            .padding(18)
        }
    }

    private func imageDetails(for image: UIImage) -> String {
        let width = Int(image.size.width.rounded())
        let height = Int(image.size.height.rounded())
        return "\(width) × \(height) px"
    }
}

private struct ReceiptSnapshotRow: View {
    let image: UIImage?
    let source: ReceiptCaptureSource?
    let capturedAt: Date?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            VStack(alignment: .leading, spacing: 6) {
                Label(source?.title ?? "Imagen del recibo", systemImage: source?.systemImage ?? "photo")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)

                if let capturedAt {
                    Text(capturedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Text("Se conserva solo como contexto de este flujo. El gasto guardado sigue siendo local-first.")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(14)
        .background(BrandTheme.surfaceTint)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct ReceiptCameraSheet: View {
    @Binding var photoPickerItem: PhotosPickerItem?
    let onImagePicked: (UIImage) -> Void

    var body: some View {
        ZStack(alignment: .bottom) {
            ReceiptCameraPicker(onImagePicked: onImagePicked)
                .ignoresSafeArea()

            HStack {
                PhotosPicker(selection: $photoPickerItem, matching: .images) {
                    ZStack {
                        Circle()
                            .fill(Color.black.opacity(0.74))
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                        Image(systemName: "photo.on.rectangle.angled")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    .frame(width: 54, height: 54)
                    .shadow(color: Color.black.opacity(0.16), radius: 12, x: 0, y: 6)
                }
                .accessibilityIdentifier("scan.action.importPhoto")

                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 22)
        }
    }
}

private struct ReceiptCameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    let onImagePicked: (UIImage) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let picker = VNDocumentCameraViewController()
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    @preconcurrency
    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let dismissAction: @MainActor () -> Void
        private let imagePickedAction: @MainActor (UIImage) -> Void

        @MainActor
        init(parent: ReceiptCameraPicker) {
            dismissAction = { parent.dismiss() }
            imagePickedAction = { image in
                parent.onImagePicked(image)
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            dismissOnMain()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0 else {
                dismissOnMain()
                return
            }

            let image = scan.imageOfPage(at: 0)
            imagePickedOnMain(image)
            dismissOnMain()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            dismissOnMain()
        }

        private func dismissOnMain() {
            let dismissAction = self.dismissAction
            DispatchQueue.main.async {
                dismissAction()
            }
        }

        private func imagePickedOnMain(_ image: UIImage) {
            let imagePickedAction = self.imagePickedAction
            DispatchQueue.main.async {
                imagePickedAction(image)
            }
        }
    }
}
