import UIKit
import SwiftUI

struct AddExpenseView: View {
    private enum EntryMode: String, CaseIterable, Identifiable {
        case manual
        case email

        var id: String { rawValue }

        var title: String {
            switch self {
            case .manual:
                return "Manual"
            case .email:
                return "Correo / online"
            }
        }
    }

    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode

    @State private var entryMode: EntryMode = .manual
    @State private var merchant = ""
    @State private var amount = ""
    @State private var category = ExpenseCategory.groceries
    @State private var date = Date()
    @State private var locationLabel = ""
    @State private var note = ""
    @State private var emailImportText = ""
    @State private var isRecurringSubscription = false
    @State private var subscriptionCadence: RecurringCadence = .monthly
    @State private var renewalDate = Calendar.autoupdatingCurrent.date(byAdding: .month, value: 1, to: .now) ?? .now
    @State private var autoRecordSubscription = true
    @State private var errorMessage: String?

    private var merchantAutofillSuggestion: MerchantAutofillSuggestion? {
        viewModel.ledger?.autofillSuggestion(for: merchant)
    }

    private var exactMerchantMatch: MerchantAutofillSuggestion? {
        viewModel.ledger?.exactMerchantMatch(for: merchant)
    }

    private var merchantSuggestions: [MerchantAutofillSuggestion] {
        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedMerchant.isEmpty {
            return viewModel.ledger?.merchantSuggestions(limit: 4) ?? []
        }
        return viewModel.ledger?.merchantSuggestions(matching: trimmedMerchant, limit: 4) ?? []
    }

    private var subscriptionHelperText: String {
        autoRecordSubscription
            ? "La suscripción quedará lista para registrarse sola en cada renovación."
            : "La suscripción quedará rastreada para que no tengas que volver a configurar la renovación."
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    quickCaptureCard

                    entrySourceCard
                    expenseFormCard

                    if shouldShowSmartAssist {
                        smartAssistCard
                    }

                    if shouldShowPreview {
                        previewCard
                    }

                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)
            .accessibilityIdentifier("addExpense.screen")
            .background(FinanceScreenBackground())
            .navigationTitle("Agregar gasto")
            .navigationBarTitleDisplayMode(.inline)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                saveActionBar
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        viewModel.dismissAddExpense()
                    }
                    .accessibilityIdentifier("addExpense.action.cancel")
                }
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        dismissKeyboard()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .overlay(alignment: .topLeading) {
            ZStack(alignment: .topLeading) {
                AccessibilityProbe(identifier: "addExpense.screen")
                AccessibilityProbe(identifier: "addExpense.presented")
            }
        }
        .onAppear {
            errorMessage = nil
        }
        .onChange(of: merchant) { _, newValue in
            applyMerchantAutofillIfNeeded(for: newValue)
        }
        .onChange(of: category) { _, newValue in
            if newValue != .subscriptions {
                isRecurringSubscription = false
            }
        }
    }

    private var quickCaptureCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(BrandTheme.accent.opacity(0.2))
                        Image(systemName: "plus.circle.fill")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(BrandTheme.primary)
                    }
                    .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Agregar gasto")
                            .font(.title3.weight(.bold))
                            .foregroundStyle(BrandTheme.ink)

                        Text("Captura rápido una compra manual, pega un correo o deja una suscripción lista en la misma pantalla.")
                            .font(.subheadline)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Spacer(minLength: 0)
                }

                BrandFeatureRow(
                    systemImage: "sparkles",
                    title: "Entrada directa",
                    detail: "Los campos principales quedan arriba para registrar el gasto sin vueltas."
                )
            }
        }
    }

    private var saveActionBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.red)
            }

            Button("Guardar gasto") {
                Task { await saveExpense() }
            }
            .buttonStyle(PrimaryCTAStyle())
            .disabled(!canSave)
            .opacity(canSave ? 1 : 0.6)
            .accessibilityIdentifier("addExpense.action.save")
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 12)
        .background(BrandTheme.background.opacity(0.96))
        .overlay(alignment: .top) {
            Divider()
        }
    }

    private var entrySourceCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                CompactSectionHeader(
                    title: "Cómo quieres registrarlo",
                    detail: "Manual para captura rápida o correo/online si vas a pegar un resumen de compra."
                )

                Picker("Modo de captura", selection: $entryMode) {
                    ForEach(EntryMode.allCases) { mode in
                        Text(mode.title.appLocalized).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .accessibilityIdentifier("addExpense.field.entryMode")

                if entryMode == .email {
                    FinanceMultilineField(
                        label: "Correo o resumen de compra",
                        placeholder: "Pega aquí el correo de confirmación, la factura online o el resumen del consumo.",
                        text: $emailImportText,
                        accessibilityIdentifier: "addExpense.field.emailImport"
                    )

                    Button {
                        applyEmailImport()
                    } label: {
                        Label("Autollenar desde correo", systemImage: "wand.and.stars")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Text("MichiFinanzas intenta detectar comercio, monto, fecha y categoría desde el texto pegado. Tú siempre puedes corregirlo antes de guardar.")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private var expenseFormCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                FinanceField(
                    label: "Comercio o título",
                    placeholder: "Supermercado",
                    text: $merchant,
                    accessibilityIdentifier: "addExpense.field.merchant"
                )
                FinanceField(
                    label: "Monto",
                    placeholder: "24.50",
                    text: $amount,
                    keyboard: .decimalPad,
                    capitalization: .never,
                    accessibilityIdentifier: "addExpense.field.amount"
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

                DatePicker(selection: $date, displayedComponents: .date) {
                    Text("Fecha")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                }
                .tint(BrandTheme.primary)

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Lugar")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)
                        Spacer()
                        Button("Usar ubicación actual") {
                            Task {
                                if let label = await viewModel.captureCurrentExpenseLocation() {
                                    locationLabel = label
                                }
                            }
                        }
                        .font(.footnote.weight(.semibold))
                    }

                    FinanceField(
                        label: "Etiqueta de lugar",
                        placeholder: "Opcional",
                        text: $locationLabel,
                        capitalization: .words,
                        accessibilityIdentifier: "addExpense.field.location"
                    )
                }

                FinanceField(
                    label: "Nota",
                    placeholder: "Nota opcional",
                    text: $note,
                    capitalization: .sentences,
                    accessibilityIdentifier: "addExpense.field.note"
                )

                if category == .subscriptions {
                    subscriptionAutomationCard
                }
            }
        }
    }

    private var subscriptionAutomationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Divider()

            Toggle(isOn: $isRecurringSubscription) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Es una suscripción recurrente")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Text("Actívalo para guardar también la renovación y no volver a configurarla.")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .tint(BrandTheme.primary)

            if isRecurringSubscription {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Frecuencia")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)

                    Picker("Frecuencia", selection: $subscriptionCadence) {
                        ForEach(RecurringCadence.allCases) { cadence in
                            Text(cadence.localizedTitle).tag(cadence)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                DatePicker(selection: $renewalDate, displayedComponents: .date) {
                    Text(subscriptionCadence == .monthly ? "Próxima renovación" : "Próxima renovación anual")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(BrandTheme.muted)
                }
                .tint(BrandTheme.primary)

                Toggle(isOn: $autoRecordSubscription) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Registrar automáticamente")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(subscriptionHelperText)
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .tint(BrandTheme.primary)
            }
        }
    }

    private var canSave: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (FinanceToolFormatting.decimal(from: amount) ?? 0) > 0
    }

    private var shouldShowPreview: Bool {
        !merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            || (FinanceToolFormatting.decimal(from: amount) ?? 0) > 0
    }

    private var shouldShowSmartAssist: Bool {
        merchantAutofillSuggestion != nil || !merchantSuggestions.isEmpty
    }

    private var previewCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Vista previa del borrador")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    BrandBadge(text: sourceBadgeText, systemImage: sourceBadgeIcon)
                }

                Text("Revisa comercio, categoría y monto antes de guardar.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)

                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(BrandTheme.accent.opacity(0.18))
                        Image(systemName: category.symbolName)
                            .foregroundStyle(BrandTheme.primary)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(merchant.isEmpty ? "Comercio" : merchant)
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)
                        Text(category.localizedTitle)
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                    }

                    Spacer()

                    Text(previewAmount, format: .currency(code: currencyCode))
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                }

                if category == .subscriptions, isRecurringSubscription {
                    FlowStack(spacing: 8, rowSpacing: 8) {
                        BrandBadge(text: subscriptionCadence.localizedTitle, systemImage: "repeat")
                        BrandBadge(text: renewalDate.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                        if autoRecordSubscription {
                            BrandBadge(text: "Auto", systemImage: "sparkles")
                        }
                    }
                }
            }
        }
    }

    private var smartAssistCard: some View {
        SurfaceCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Llenado inteligente")
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)
                    Spacer()
                    BrandBadge(text: "1 toque", systemImage: "sparkles")
                }

                Text("Reutiliza categoría, monto y nota de un comercio conocido para registrar más rápido.")
                    .font(.subheadline)
                    .foregroundStyle(BrandTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                if let suggestion = merchantAutofillSuggestion {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: suggestion.category.symbolName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(BrandTheme.primary)
                            .frame(width: 40, height: 40)
                            .background(BrandTheme.accent.opacity(0.18))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                        VStack(alignment: .leading, spacing: 4) {
                            Text(suggestion.merchant)
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)
                            Text(
                                AppLocalization.localized(
                                    "%@ · %@ · %@",
                                    arguments: suggestion.category.localizedTitle,
                                    suggestion.lastAmount.formatted(.currency(code: currencyCode)),
                                    suggestion.frequencyLabel
                                )
                            )
                            .font(.footnote)
                            .foregroundStyle(BrandTheme.muted)
                        }

                        Spacer()

                        Button("Usar") {
                            applySuggestion(suggestion, includeMerchant: false)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(14)
                    .background(BrandTheme.surfaceTint)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(BrandTheme.line.opacity(0.75), lineWidth: 1)
                    )
                }

                if !merchantSuggestions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Comercios recientes" : "Comercios relacionados")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)

                        FlowStack(spacing: 8, rowSpacing: 8) {
                            ForEach(merchantSuggestions) { suggestion in
                                Button {
                                    applySuggestion(suggestion, includeMerchant: true)
                                } label: {
                                    Text(suggestion.merchant)
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(BrandTheme.primary)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
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

    private var previewAmount: Decimal {
        FinanceToolFormatting.decimal(from: amount) ?? 0
    }

    private var sourceBadgeText: String {
        switch entryMode {
        case .manual:
            return "Entrada manual"
        case .email:
            return "Correo"
        }
    }

    private var sourceBadgeIcon: String {
        switch entryMode {
        case .manual:
            return "keyboard"
        case .email:
            return "envelope.fill"
        }
    }

    private func applyEmailImport() {
        let trimmed = emailImportText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Pega primero el correo o el resumen de compra."
            return
        }

        let analysis = ExpenseEmailImportService.analyze(trimmed)
        guard analysis.hasDetectedValues else {
            errorMessage = "No pudimos detectar datos claros en ese correo. Puedes completar el gasto manualmente."
            return
        }

        if let merchantValue = analysis.merchant, merchant.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            merchant = merchantValue
        }
        if let amountValue = analysis.amount, amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            amount = formatAmount(amountValue)
        }
        if let categoryValue = analysis.category {
            category = categoryValue
        }
        if let detectedDate = analysis.date {
            date = detectedDate
        }
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            note = "Importado desde correo o compra online.".appLocalized
        }
        errorMessage = nil
    }

    private func applySuggestion(_ suggestion: MerchantAutofillSuggestion, includeMerchant: Bool) {
        if includeMerchant {
            merchant = suggestion.merchant
        }
        amount = formatAmount(suggestion.lastAmount)
        category = suggestion.category
        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let lastNote = suggestion.lastNote, !lastNote.isEmpty {
            note = lastNote
        }
        errorMessage = nil
    }

    private func applyMerchantAutofillIfNeeded(for value: String) {
        guard let suggestion = exactMerchantMatch else { return }

        if amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            amount = formatAmount(suggestion.lastAmount)
        }

        category = suggestion.category

        if note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let lastNote = suggestion.lastNote, !lastNote.isEmpty {
            note = lastNote
        }
    }

    private func formatAmount(_ value: Decimal) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private func saveExpense() async {
        guard let amountValue = FinanceToolFormatting.decimal(from: amount) else {
            errorMessage = "Ingresa un monto válido.".appLocalized
            return
        }

        let trimmedMerchant = merchant.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMerchant.isEmpty else {
            errorMessage = "Agrega un comercio antes de guardar.".appLocalized
            return
        }

        errorMessage = nil
        let recurringPlan: RecurringExpensePlan? = category == .subscriptions && isRecurringSubscription
            ? RecurringExpensePlan(
                cadence: subscriptionCadence,
                renewalDate: renewalDate,
                autoRecord: autoRecordSubscription
            )
            : nil

        let draft = ExpenseDraft(
            merchant: trimmedMerchant,
            amount: amountValue,
            category: category,
            date: date,
            locationLabel: locationLabel,
            note: note,
            source: entryMode == .email ? .email : .manual,
            sourceText: entryMode == .email ? emailImportText : "",
            recurringPlan: recurringPlan
        )
        await viewModel.addExpense(draft)
    }

    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
