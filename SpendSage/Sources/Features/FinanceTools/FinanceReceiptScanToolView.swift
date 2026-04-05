import Foundation
import PhotosUI
import SwiftUI
import UIKit
import VisionKit

struct FinanceReceiptScanToolView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode

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
    @State private var hasPresentedInitialGuide = false
    @State private var receiptAnalysis: ReceiptScanAnalysis?
    @State private var analysisToken = UUID()
    @State private var currentStep: ReceiptWizardStep = .capture
    @State private var isApplyingAutofill = false
    @State private var isCategoryLockedByUser = false
    @State private var isDateLockedByUser = false

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

    private var extractedTextPreview: String {
        let lines = [
            receiptAnalysis?.recognizedText,
            AppLocalization.localized("Merchant: %@", arguments: merchant.isEmpty ? "..." : merchant),
            AppLocalization.localized("Amount: %@", arguments: amount.isEmpty ? "..." : amount),
            AppLocalization.localized("Category: %@", arguments: category.localizedTitle),
            AppLocalization.localized("Date: %@", arguments: date.formatted(date: .abbreviated, time: .omitted)),
            AppLocalization.localized("Notes: %@", arguments: note.isEmpty ? "..." : note),
            AppLocalization.localized("Source: %@", arguments: captureSource?.title.appLocalized ?? "Manual draft".appLocalized)
        ]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
        return lines.joined(separator: "\n")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Tres pasos rápidos",
                    title: "Escaneo de recibos",
                    summary: "Toma la foto, confirma el autollenado y revisa una vez antes de guardar localmente.",
                    systemImage: "camera.viewfinder",
                    character: .mei,
                    expression: .thinking,
                    sceneKey: "guide_05_scan_receipt_mei"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                wizardStatusCard
                wizardProgressCard
                stepContent
            }
            .padding(24)
        }
        .background(FinanceScreenBackground())
        .navigationTitle("Receipt Scan")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isPresentingGuide = true
                } label: {
                    Label("Guide", systemImage: "questionmark.circle")
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
        .task(id: photoPickerItem) {
            await loadPhotoSelection()
        }
        .sheet(isPresented: $isPresentingCamera) {
            ReceiptCameraPicker { image in
                attachImage(image, source: .camera)
            }
        }
        .sheet(isPresented: $isPresentingGuide) {
            GuideSheet(guide: GuideLibrary.guide(.scan))
        }
        .onAppear {
            guard !hasPresentedInitialGuide else { return }
            hasPresentedInitialGuide = true
            if !GuideProgressStore.isSeen(.scan) {
                isPresentingGuide = true
            }
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

                    Text(currentStatus.summary)
                        .font(.subheadline)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 8) {
                        BrandBadge(
                            text: "Step \(currentStep.number) of \(ReceiptWizardStep.allCases.count)",
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
        let photoPickerTitle = capturedImage == nil ? "Importar desde Fotos" : "Reemplazar desde Fotos"

        return VStack(alignment: .leading, spacing: 20) {
            SurfaceCard {
                VStack(alignment: .leading, spacing: 16) {
                    stepHeader(
                        for: .capture,
                        title: "Empieza con el recibo",
                        summary: "Toma una foto clara o importa una desde Fotos. Si necesitas rapidez antes que OCR, puedes continuar sin imagen."
                    )

                    ReceiptImagePreviewCard(
                        image: capturedImage,
                        source: captureSource,
                        capturedAt: captureDate,
                        isBusy: isLoadingPhoto,
                        onRemove: removeAttachedImage
                    )

                    VStack(spacing: 12) {
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

                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            ReceiptActionLabel(
                                title: photoPickerTitle,
                                systemImage: "photo.on.rectangle",
                                style: .secondary
                            )
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 12) {
                            Button("Continuar sin foto") {
                                transitionToStep(.autofill)
                            }
                            .buttonStyle(SecondaryCTAStyle())

                            Button("Usar borrador de ejemplo") {
                                loadSampleDraft()
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }
                    }
                }
            }

            SurfaceCard {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Consejos para la foto")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    BrandFeatureRow(
                        systemImage: "sun.max.fill",
                        title: "Use even lighting",
                        detail: "Avoid glare and hard shadows so totals and merchant names stay easy to read."
                    )

                    BrandFeatureRow(
                        systemImage: "viewfinder",
                        title: "Fill the frame",
                        detail: "Keep the receipt flat and centered. Extra background lowers OCR quality."
                    )

                    BrandFeatureRow(
                        systemImage: "square.and.pencil",
                        title: "You still review the draft",
                        detail: "SpendSage prefills locally, but nothing is saved until you confirm it."
                    )
                }
            }
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
                            ? "No hay foto adjunta, así que este paso es manual. Completa lo esencial y continúa."
                            : "El OCR ya hizo un primer pase sobre comercio, total y fecha. Corrige lo que veas raro antes de revisar."
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
                            summary: "SpendSage está ejecutando OCR en el dispositivo y mantendrá sincronizados los campos editables con las coincidencias más seguras."
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
                            Text(AppLocalization.localized("Rule suggestion: %@", arguments: suggestedCategory.localizedTitle))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.ink)
                            Spacer()
                            Button("Use") {
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

                    FinanceField(label: "Merchant", placeholder: "Blue Bottle Coffee", text: $merchant)
                    FinanceField(
                        label: "Amount",
                        placeholder: "8.75",
                        text: $amount,
                        keyboard: .decimalPad,
                        capitalization: .never
                    )

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)

                        Picker("Category", selection: $category) {
                            ForEach(ExpenseCategory.allCases) { item in
                                Label(item.localizedTitle, systemImage: item.symbolName)
                                    .tag(item)
                            }
                        }
                        .pickerStyle(.menu)
                    }

                    DatePicker("Receipt date", selection: $date, displayedComponents: .date)
                        .tint(BrandTheme.primary)

                    FinanceMultilineField(
                        label: "Note",
                        placeholder: "Add line items, reimbursement context, or anything you want to remember later.",
                        text: $note
                    )

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }

                    HStack(spacing: 12) {
                        Button("Back") {
                            transitionToStep(.capture)
                        }
                        .buttonStyle(SecondaryCTAStyle())

                        Button("Revisar gasto") {
                            goToReview()
                        }
                        .buttonStyle(PrimaryCTAStyle())
                        .disabled(!canSave || isAnalyzingReceipt)
                        .opacity((canSave && !isAnalyzingReceipt) ? 1 : 0.7)
                    }
                }
            }

            if shouldShowSmartFillSupport {
                smartFillSupportCard
            }

            if shouldShowOCRPreview {
                ocrPreviewCard
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
                        summary: "Esta es la última comprobación antes de escribir el gasto en tu ledger local."
                    )

                    draftPreviewRow

                    VStack(spacing: 12) {
                        reviewRow(
                            title: "Merchant",
                            value: merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Missing" : merchant,
                            systemImage: "building.2.crop.circle"
                        )
                        reviewRow(
                            title: "Amount",
                            value: parsedAmount?.formatted(.currency(code: currencyCode)) ?? "Missing",
                            systemImage: "dollarsign.circle"
                        )
                        reviewRow(
                            title: "Category",
                            value: category.localizedTitle,
                            systemImage: category.symbolName
                        )
                        reviewRow(
                            title: "Date",
                            value: date.formatted(date: .abbreviated, time: .omitted),
                            systemImage: "calendar"
                        )
                        reviewRow(
                            title: "Source",
                            value: captureSource?.title ?? "Manual draft".appLocalized,
                            systemImage: captureSource?.systemImage ?? "square.and.pencil"
                        )
                    }

                    if !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
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

                    Text("Saved receipts stay on this device in this build. Nothing syncs until you choose a different product path.")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)

                    HStack(spacing: 12) {
                        Button("Back") {
                            transitionToStep(.autofill)
                        }
                        .buttonStyle(SecondaryCTAStyle())

                        Button {
                            Task { await saveDraft() }
                        } label: {
                            ReceiptActionLabel(
                                title: isSavingDraft ? "Saving locally..." : "Save expense",
                                systemImage: isSavingDraft ? "hourglass" : "tray.and.arrow.down.fill",
                                style: .primary
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave)
                        .opacity(canSave ? 1 : 0.7)
                    }
                }
            }

            if capturedImage != nil {
                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Attached receipt")
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

                Text("Reuse local merchant memory only when it actually helps the current draft.")
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

                        Button("Use") {
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
                            Text("Latest expense template")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text("\(latest.title) · \(latest.category.appLocalized) · \(latest.amount.formatted(.currency(code: currencyCode)))")
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)
                        }

                        Spacer()

                        Button("Use") {
                            applyTemplate(from: latest)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }

                if !merchantSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Known merchants" : "Matching merchants")
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

    private var shouldShowOCRPreview: Bool {
        capturedImage != nil || !(receiptAnalysis?.recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    private var ocrPreviewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("OCR preview")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    BrandBadge(text: capturedImage == nil ? "Manual" : "On device", systemImage: "text.viewfinder")
                }

                Text("Read this only when something looks off. Most receipts should need just a quick field check above.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

                ScrollView {
                    Text(extractedTextPreview)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(BrandTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 150)
                .padding(14)
                .background(BrandTheme.surfaceTint)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(BrandTheme.line.opacity(0.8), lineWidth: 1)
                )
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
                Text(merchant.isEmpty ? "Merchant preview" : merchant)
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text("\(category.localizedTitle) · \(date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)

                Text(capturedImage == nil ? "Manual draft with no receipt image attached." : "Receipt image attached for final verification.")
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
            BrandBadge(text: "Step \(step.number)", systemImage: step.systemImage)
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
            errorMessage = "Add a merchant and a valid amount before reviewing."
            return
        }
        transitionToStep(.review)
    }

    private func openCamera() {
        clearTransientState()
        guard VNDocumentCameraViewController.isSupported else {
            errorMessage = "Document scan is not available on this device.".appLocalized
            return
        }

        isPresentingCamera = true
    }

    private func loadSampleDraft() {
        applySystemDraftMutation {
            merchant = "Blue Bottle Coffee"
            amount = "8.75"
            category = .coffee
            date = .now
            note = "Local-first receipt draft from an in-store purchase."
        }
        resetDraftLocks()
        clearTransientState()
        transitionToStep(.autofill)
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
        transitionToStep(.capture)
    }

    private func attachImage(_ image: UIImage, source: ReceiptCaptureSource) {
        capturedImage = image
        captureSource = source
        captureDate = .now
        receiptAnalysis = nil
        resetDraftLocks()
        clearTransientState()
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
                errorMessage = "The selected photo could not be loaded."
                return
            }

            attachImage(image, source: .photos)
        } catch {
            errorMessage = "We could not import that image from Photos."
        }
    }

    private func saveDraft() async {
        guard let amountValue = parsedAmount, amountValue > 0 else {
            errorMessage = "Enter a valid amount."
            transitionToStep(.autofill)
            return
        }

        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMerchant.isEmpty else {
            errorMessage = "Add a merchant before saving."
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
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
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
            return "Capture".appLocalized
        case .autofill:
            return "Autofill".appLocalized
        case .review:
            return "Review".appLocalized
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
            return "Camera capture".appLocalized
        case .photos:
            return "Imported photo".appLocalized
        }
    }

    var metricLabel: String {
        switch self {
        case .camera:
            return "Camera".appLocalized
        case .photos:
            return "Photos".appLocalized
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
        summary: "Los campos clave ya están listos. Revisa una vez y guarda el gasto en tu ledger local.".appLocalized,
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
        summary: "SpendSage está usando OCR en el dispositivo para detectar comercio, total y fecha antes de que revises el borrador.".appLocalized,
        systemImage: "text.viewfinder",
        tint: BrandTheme.primary
    )

    static func saved(_ summary: String) -> ReceiptScanStatusDescriptor {
        ReceiptScanStatusDescriptor(
            title: "Borrador guardado".appLocalized,
            summary: AppLocalization.localized(
                "%@ se añadió al ledger local. Empieza el siguiente recibo cuando quieras.",
                arguments: summary
            ),
            systemImage: "tray.and.arrow.down.fill",
            tint: BrandTheme.primary
        )
    }

    static func failed(_ message: String) -> ReceiptScanStatusDescriptor {
        ReceiptScanStatusDescriptor(
            title: "Needs attention".appLocalized,
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
                            Label(source?.title ?? "Receipt image", systemImage: source?.systemImage ?? "photo")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.primary)

                            Text(imageDetails(for: image))
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)

                            if let capturedAt {
                                Text("Updated \(capturedAt.formatted(date: .abbreviated, time: .shortened))")
                                    .font(.footnote)
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }

                        Spacer()

                        Button("Remove") {
                            onRemove()
                        }
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.red)
                    }
                } else if isBusy {
                    VStack(spacing: 14) {
                        MascotAvatarView(character: .mei, expression: .excited, size: 64)

                        YarnLoadingIndicator(size: 22)

                        Text("Importing image...")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("We are preparing the selected photo so the wizard can move into the autofill step.")
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

                        Text("No receipt image attached")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Use the camera for a fresh capture, import a photo from your library, or continue manually if you only need a quick expense entry.")
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
                Label(source?.title ?? "Receipt image", systemImage: source?.systemImage ?? "photo")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(BrandTheme.primary)

                if let capturedAt {
                    Text(capturedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Text("Kept only as context for this wizard. The saved expense still stays local-first.")
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
