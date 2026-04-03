import PhotosUI
import SwiftUI
import UIKit

struct FinanceReceiptScanToolView: View {
    @ObservedObject var viewModel: AppViewModel

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
    @State private var isSavingDraft = false
    @State private var errorMessage: String?
    @State private var lastSavedSummary: String?
    @State private var hasPresentedInitialGuide = false

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

    private var suggestedCategory: ExpenseCategory? {
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMerchant.isEmpty else { return nil }
        return viewModel.ledger?.inferredCategory(for: trimmedMerchant)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Local-first capture flow",
                    title: "Receipt Scan",
                    summary: "Capture a receipt, review the draft, and save the expense locally. The image is used as a visual reference while you edit.",
                    systemImage: "camera.viewfinder"
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
        .background(BrandTheme.canvas)
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
                        Text(currentStatus.title)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        Text(currentStatus.summary)
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                HStack(spacing: 12) {
                    BrandMetricTile(
                        title: "Draft",
                        value: canSave ? "Ready" : requiredFieldProgress,
                        systemImage: canSave ? "checkmark.circle.fill" : "slider.horizontal.3"
                    )
                    BrandMetricTile(
                        title: "Image",
                        value: captureSource?.metricLabel ?? "Optional",
                        systemImage: capturedImage == nil ? "photo" : "photo.on.rectangle.angled"
                    )
                    BrandMetricTile(
                        title: "Storage",
                        value: "On device",
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

                        Text("Take a clean photo or import one from Photos, then use the editor below to finish the expense before saving.")
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
                            title: capturedImage == nil ? "Capture receipt" : "Retake receipt",
                            systemImage: capturedImage == nil ? "camera.fill" : "arrow.clockwise.circle.fill",
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
                    detail: "This local-first flow does not run OCR. The editor is the final source of truth for the ledger."
                )
            }
        }
    }

    private var ocrPreviewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Extracted text preview")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    BrandBadge(text: capturedImage == nil ? "Local draft" : "Image linked", systemImage: "text.viewfinder")
                }

                Text("This keeps the receipt flow closer to an OCR job view even though capture and review stay local.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

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

                Text("Use the latest expense or a rule-based category suggestion to reduce manual typing before you save.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

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
                            Text("\(latest.title) · \(latest.category.appLocalized) · \(latest.amount.formatted(.currency(code: "USD")))")
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

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
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

                Text("Use the attached image as a reference, correct the fields, and save the final expense locally.")
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
                        title: isSavingDraft ? "Saving locally..." : "Save draft to ledger",
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

            Text(summaryAmount, format: .currency(code: "USD"))
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
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
            errorMessage = "Camera capture is not available on this device.".appLocalized
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

    private var extractedTextPreview: String {
        let lines = [
            AppLocalization.localized("Merchant: %@", arguments: merchant.isEmpty ? "..." : merchant),
            AppLocalization.localized("Amount: %@", arguments: amount.isEmpty ? "..." : amount),
            AppLocalization.localized("Category: %@", arguments: category.localizedTitle),
            AppLocalization.localized("Date: %@", arguments: date.formatted(date: .abbreviated, time: .omitted)),
            AppLocalization.localized("Notes: %@", arguments: note.isEmpty ? "..." : note),
            AppLocalization.localized("Source: %@", arguments: captureSource?.title.appLocalized ?? "Manual draft".appLocalized)
        ]
        return lines.joined(separator: "\n")
    }

    private func removeAttachedImage() {
        capturedImage = nil
        captureSource = nil
        captureDate = nil
        clearTransientState()
    }

    private func attachImage(_ image: UIImage, source: ReceiptCaptureSource) {
        capturedImage = image
        captureSource = source
        captureDate = .now
        clearTransientState()
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

        lastSavedSummary = "\(draft.merchant) · \(draft.amount.formatted(.currency(code: "USD")))"
        merchant = ""
        amount = ""
        category = .groceries
        date = .now
        note = ""
        capturedImage = nil
        captureSource = nil
        captureDate = nil
        isSavingDraft = false
    }
}

private enum ReceiptCaptureSource {
    case camera
    case photos

    var title: String {
        switch self {
        case .camera:
            return "Camera capture"
        case .photos:
            return "Imported photo"
        }
    }

    var metricLabel: String {
        switch self {
        case .camera:
            return "Camera"
        case .photos:
            return "Photos"
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
        title: "Ready to capture",
        summary: "Start with the camera or a photo from your library. You can also skip the image and build the draft manually.",
        systemImage: "camera.viewfinder",
        tint: BrandTheme.primary
    )

    static let reviewDraft = ReceiptScanStatusDescriptor(
        title: "Image attached",
        summary: "The receipt is ready as a visual reference. Fill merchant and amount before you save the expense.",
        systemImage: "photo.badge.checkmark",
        tint: BrandTheme.primary
    )

    static let readyToSave = ReceiptScanStatusDescriptor(
        title: "Ready to save",
        summary: "The draft has the core fields filled in. Review the category, date, and note, then save it to your local ledger.",
        systemImage: "checkmark.circle.fill",
        tint: BrandTheme.primary
    )

    static let saving = ReceiptScanStatusDescriptor(
        title: "Saving locally",
        summary: "The draft is being stored on this device. No cloud service or OCR pipeline is involved in this flow.",
        systemImage: "arrow.down.circle.fill",
        tint: BrandTheme.primary
    )

    static func saved(_ summary: String) -> ReceiptScanStatusDescriptor {
        ReceiptScanStatusDescriptor(
            title: "Draft saved",
            summary: "\(summary) was added to the local ledger. Capture another receipt or keep editing a new draft.",
            systemImage: "tray.and.arrow.down.fill",
            tint: BrandTheme.primary
        )
    }

    static func failed(_ message: String) -> ReceiptScanStatusDescriptor {
        ReceiptScanStatusDescriptor(
            title: "Needs attention",
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
                        ProgressView()
                            .tint(BrandTheme.primary)
                            .controlSize(.large)

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

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ReceiptCameraPicker

        init(parent: ReceiptCameraPicker) {
            self.parent = parent
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImagePicked(image)
            }
            parent.dismiss()
        }
    }
}
