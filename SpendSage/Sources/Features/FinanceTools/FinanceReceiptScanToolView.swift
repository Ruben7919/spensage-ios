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

    private var parsedAmount: Decimal? {
        FinanceToolFormatting.decimal(from: amount)
    }

    private var canSave: Bool {
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsedAmount else { return false }
        return !trimmedMerchant.isEmpty && parsedAmount > 0 && !isSavingDraft
    }

    private var requiredFieldProgress: String {
        "\(requiredFieldCount)/2"
    }

    private var requiredFieldCount: Int {
        var count = 0
        if !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            count += 1
        }
        if let parsedAmount, parsedAmount > 0 {
            count += 1
        }
        return count
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

        if capturedImage != nil {
            return canSave ? .readyToSave : .reviewDraft
        }

        return .ready
    }

    private var summaryAmount: Decimal {
        parsedAmount ?? 0
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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Smart local capture",
                    title: "Receipt Scan",
                    summary: "Scan a receipt, let on-device OCR prefill the draft, then review and save.",
                    systemImage: "camera.viewfinder",
                    character: .mei,
                    expression: .thinking,
                    sceneKey: "guide_05_scan_receipt_mei"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                statusOverviewCard
                smartFillCard
                captureFlowCard
                ocrPreviewCard
                quickTipsCard
                draftEditorCard
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
            clearTransientState()
        }
        .onChange(of: date) { _, _ in
            clearTransientState()
        }
        .onChange(of: note) { _, _ in
            clearTransientState()
        }
    }

    private var statusOverviewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 14) {
                    Image(systemName: currentStatus.systemImage)
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(currentStatus.tint)
                        .frame(width: 48, height: 48)
                        .background(currentStatus.tint.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                    VStack(alignment: .leading, spacing: 6) {
                        Text(currentStatus.title.appLocalized)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text(currentStatus.summary.appLocalized)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                LazyVGrid(columns: [GridItem(.adaptive(minimum: 120), spacing: 12)], spacing: 12) {
                    BrandMetricTile(
                        title: "Draft",
                        value: canSave ? "Ready".appLocalized : requiredFieldProgress,
                        systemImage: canSave ? "checkmark.circle.fill" : "slider.horizontal.3"
                    )
                    BrandMetricTile(
                        title: "OCR",
                        value: isAnalyzingReceipt
                            ? "Working".appLocalized
                            : (receiptAnalysis?.hasDetectedValues == true ? "Detected".appLocalized : (capturedImage == nil ? "Idle".appLocalized : "Review".appLocalized)),
                        systemImage: "text.viewfinder"
                    )
                    BrandMetricTile(
                        title: "Storage",
                        value: "On device".appLocalized,
                        systemImage: "internaldrive.fill"
                    )
                }
            }
        }
    }

    private var captureFlowCard: some View {
        let photoPickerTitle = capturedImage == nil ? "Choose from Photos" : "Replace from Photos"

        return SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Capture flow")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text("Use the document scanner or import a receipt photo. SpendSage reads the text on-device and prepares a clean draft for review.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                    }

                    Spacer(minLength: 12)

                    Button {
                        isPresentingGuide = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .frame(width: 36, height: 36)
                            .background(BrandTheme.accent.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }

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
                            title: capturedImage == nil ? "Scan receipt" : "Scan again",
                            systemImage: capturedImage == nil ? "doc.viewfinder" : "arrow.clockwise.circle.fill",
                            style: .primary
                        )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 12) {
                        PhotosPicker(selection: $photoPickerItem, matching: .images) {
                            ReceiptActionLabel(
                                title: photoPickerTitle,
                                systemImage: "photo.on.rectangle",
                                style: .secondary
                            )
                        }
                        .buttonStyle(.plain)

                        Button {
                            loadSampleDraft()
                        } label: {
                            ReceiptActionLabel(
                                title: "Use sample draft",
                                systemImage: "wand.and.stars",
                                style: .secondary
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var quickTipsCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Capture tips")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                BrandFeatureRow(
                    systemImage: "sun.max.fill",
                    title: "Use even lighting",
                    detail: "Avoid glare and hard shadows so totals, dates, and merchant names stay legible."
                )

                BrandFeatureRow(
                    systemImage: "viewfinder",
                    title: "Fill the frame",
                    detail: "Keep the receipt flat and centered. Extra background makes manual review slower."
                )

                BrandFeatureRow(
                    systemImage: "square.and.pencil",
                    title: "Review before saving",
                    detail: "On-device OCR suggests the core fields, but the final edit is always yours before anything reaches the ledger."
                )
            }
        }
    }

    private var ocrPreviewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("On-device text scan")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    BrandBadge(text: capturedImage == nil ? "Waiting" : "Vision OCR", systemImage: "text.viewfinder")
                }

                Text("The image stays on the device in this build. OCR helps prefill merchant, total, and date so you spend less time typing.")
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

                ScrollView {
                    Text(extractedTextPreview)
                        .font(.system(.footnote, design: .monospaced))
                        .foregroundStyle(BrandTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .textSelection(.enabled)
                }
                .frame(minHeight: 180)
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

    private var smartFillCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                Text("Smart fill")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text("Blend receipt OCR, remembered merchants, and local rules so most drafts need only a quick review.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

                if let receiptAnalysis {
                    if receiptAnalysis.hasDetectedValues {
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "sparkles.rectangle.stack")
                                .font(.headline.weight(.semibold))
                                .foregroundStyle(BrandTheme.primary)
                                .frame(width: 40, height: 40)
                                .background(BrandTheme.accent.opacity(0.18))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Receipt suggestions")
                                    .font(.headline)
                                    .foregroundStyle(BrandTheme.ink)
                                Text("SpendSage found values on-device and already applied the safest ones to the draft below.")
                                    .font(.footnote)
                                    .foregroundStyle(BrandTheme.muted)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(BrandTheme.surfaceTint)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }

                if let suggestedCategory {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .foregroundStyle(.orange)
                        Text(AppLocalization.localized("Rule suggestion: %@", arguments: suggestedCategory.localizedTitle))
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.ink)
                        Spacer()
                        Button("Adopt") {
                            category = suggestedCategory
                            clearTransientState()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(BrandTheme.surfaceTint)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                            Text("Remembered merchant")
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

                if !recentExpenseItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent merchants")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)

                        FlowStack(spacing: 8, rowSpacing: 8) {
                            ForEach(recentExpenseItems) { item in
                                Button {
                                    applyTemplate(from: item)
                                } label: {
                                    Text(item.title)
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

    private var draftEditorCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Scanned expense editor")
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)

                Text("Check the autofill, fix anything that looks off, and save the clean expense to your ledger.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

                draftPreviewRow

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
                    Text(errorMessage.appLocalized)
                        .font(.footnote)
                        .foregroundStyle(.red)
                }

                if let lastSavedSummary, !isSavingDraft {
                    Label(lastSavedSummary, systemImage: "checkmark.circle.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.primary)
                }

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

                Text(capturedImage == nil ? "No image attached yet. You can still save a local draft." : "Image attached for reference during review.")
                    .font(.footnote)
                    .foregroundStyle(BrandTheme.muted)
            }

            Spacer()

            Text(summaryAmount, format: .currency(code: currencyCode))
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

    private func openCamera() {
        clearTransientState()
        guard VNDocumentCameraViewController.isSupported else {
            errorMessage = "Document scan is not available on this device.".appLocalized
            return
        }

        isPresentingCamera = true
    }

    private func loadSampleDraft() {
        merchant = "Blue Bottle Coffee"
        amount = "8.75"
        category = .coffee
        date = .now
        note = "Local-first receipt draft from an in-store purchase."
        clearTransientState()
    }

    private func applyTemplate(from item: ExpenseItem) {
        merchant = item.title
        amount = item.amount.formatted(.number.precision(.fractionLength(2)))
        category = ExpenseCategory.allCases.first(where: { $0.rawValue == item.category }) ?? .other
        date = item.date
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            note = "Prefilled from recent local activity.".appLocalized
        }
        clearTransientState()
    }

    private func applyMerchantSuggestion(_ suggestion: MerchantAutofillSuggestion, includeMerchant: Bool) {
        if includeMerchant {
            merchant = suggestion.merchant
        }
        amount = suggestion.lastAmount.formatted(.number.precision(.fractionLength(2)))
        category = suggestion.category
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let lastNote = suggestion.lastNote, !lastNote.isEmpty {
            note = lastNote
        }
        clearTransientState()
    }

    private func applyMerchantAutofillIfNeeded(for value: String) {
        guard let suggestion = exactMerchantMatch else { return }

        if amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            amount = suggestion.lastAmount.formatted(.number.precision(.fractionLength(2)))
        }

        category = suggestedCategory ?? suggestion.category

        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let lastNote = suggestion.lastNote, !lastNote.isEmpty {
            note = lastNote
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

    private func removeAttachedImage() {
        capturedImage = nil
        captureSource = nil
        captureDate = nil
        receiptAnalysis = nil
        isAnalyzingReceipt = false
        analysisToken = UUID()
        clearTransientState()
    }

    private func attachImage(_ image: UIImage, source: ReceiptCaptureSource) {
        capturedImage = image
        captureSource = source
        captureDate = .now
        receiptAnalysis = nil
        clearTransientState()
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
            return
        }

        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMerchant.isEmpty else {
            errorMessage = "Add a merchant before saving."
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

        if merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let detectedMerchant = analysis.merchant {
            merchant = detectedMerchant
        }

        if amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let detectedAmount = analysis.amount {
            amount = detectedAmount.formatted(.number.precision(.fractionLength(2)))
        }

        if let detectedDate = analysis.date {
            date = detectedDate
        }

        if let detectedMerchant = analysis.merchant,
           let matchedCategory = viewModel.ledger?.inferredCategory(for: detectedMerchant) ?? analysis.category {
            category = matchedCategory
        }

        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, analysis.hasDetectedValues {
            note = "Prefilled on device from the receipt scan.".appLocalized
        }

        errorMessage = nil
        isAnalyzingReceipt = false
    }
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

    static let ready = ReceiptScanStatusDescriptor(
        title: "Ready to capture".appLocalized,
        summary: "Start with the document scanner or a photo from your library. You can also skip the image and build the draft manually.".appLocalized,
        systemImage: "camera.viewfinder",
        tint: BrandTheme.primary
    )

    static let reviewDraft = ReceiptScanStatusDescriptor(
        title: "Image attached".appLocalized,
        summary: "The receipt is attached and SpendSage can suggest the core fields. Review the draft before you save the expense.".appLocalized,
        systemImage: "photo.badge.checkmark",
        tint: BrandTheme.primary
    )

    static let readyToSave = ReceiptScanStatusDescriptor(
        title: "Ready to save".appLocalized,
        summary: "The draft has the core fields filled in. Review the category, date, and note, then save it to your local ledger.".appLocalized,
        systemImage: "checkmark.circle.fill",
        tint: BrandTheme.primary
    )

    static let saving = ReceiptScanStatusDescriptor(
        title: "Saving locally".appLocalized,
        summary: "The draft is being stored on this device. No cloud service is involved in this flow.".appLocalized,
        systemImage: "arrow.down.circle.fill",
        tint: BrandTheme.primary
    )

    static let analyzing = ReceiptScanStatusDescriptor(
        title: "Reading receipt".appLocalized,
        summary: "SpendSage is using on-device OCR to detect the merchant, total, and date before you review the draft.".appLocalized,
        systemImage: "text.viewfinder",
        tint: BrandTheme.primary
    )

    static func saved(_ summary: String) -> ReceiptScanStatusDescriptor {
        ReceiptScanStatusDescriptor(
            title: "Draft saved".appLocalized,
            summary: AppLocalization.localized(
                "%@ was added to the local ledger. Capture another receipt or keep editing a new draft.",
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

                        Text("We are preparing the selected photo so you can review the expense fields next.")
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

                        Text("Use the camera for a fresh capture, import a photo from your library, or skip the image and fill the draft manually.")
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
