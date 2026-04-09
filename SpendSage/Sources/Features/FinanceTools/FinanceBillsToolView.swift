import SwiftUI

struct FinanceBillsToolView: View {
    @ObservedObject var viewModel: AppViewModel
    @AppStorage(AppCurrencyFormat.defaultsKey) private var currencyCode = AppCurrencyFormat.defaultCode

    @State private var title = ""
    @State private var amount = ""
    @State private var dueDay = 1
    @State private var category = ExpenseCategory.bills
    @State private var autopay = false
    @State private var errorMessage: String?
    @AppStorage("native.bills.pausedIDs") private var pausedBillIDsJSON = "[]"

    private var totalMonthlyBills: Decimal {
        activeBills.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var overdueCount: Int {
        guard let ledger = viewModel.ledger else { return 0 }
        return activeBills.filter { ledger.billStatus(for: $0) == .overdue }.count
    }

    private var dueSoonCount: Int {
        guard let ledger = viewModel.ledger else { return 0 }
        return activeBills.filter { ledger.billStatus(for: $0) == .dueSoon }.count
    }

    private var autopayCount: Int {
        activeBills.filter { $0.autopay }.count
    }

    private var pausedBillIDs: Set<String> {
        decodePausedBillIDs(pausedBillIDsJSON)
    }

    private var activeBills: [BillRecord] {
        viewModel.bills.filter { !isPaused($0.id) }
    }

    private var pausedBills: [BillRecord] {
        viewModel.bills.filter { isPaused($0.id) }
    }

    private struct BillSuggestion: Identifiable {
        let id = UUID()
        let merchant: String
        let category: ExpenseCategory
        let averageAmount: Decimal
        let cadenceDays: Int
        let nextExpectedAt: Date
        let sampleCount: Int
    }

    private var billSuggestions: [BillSuggestion] {
        guard let ledger = viewModel.ledger else { return [] }
        let recurringCategories: Set<String> = [
            ExpenseCategory.bills.rawValue,
            ExpenseCategory.subscriptions.rawValue,
            ExpenseCategory.home.rawValue
        ]
        let recentExpenses = ledger.recentExpenseItems(limit: 24).filter { recurringCategories.contains(normalizedKey($0.category)) }
        let grouped = Dictionary(grouping: recentExpenses, by: { normalizedKey($0.title) })
        let calendar = Calendar.autoupdatingCurrent

        return grouped.compactMap { _, items -> BillSuggestion? in
            guard items.count >= 2 else { return nil }
            let sorted = items.sorted { $0.date > $1.date }
            let latest = sorted[0]
            let gaps: [Int] = zip(sorted, sorted.dropFirst()).compactMap { newer, older in
                calendar.dateComponents([.day], from: older.date, to: newer.date).day
            }.filter { $0 > 0 }
            let cadence = max(7, min(45, gaps.isEmpty ? 30 : gaps.reduce(0, +) / gaps.count))
            let nextExpectedAt = calendar.date(byAdding: .day, value: cadence, to: latest.date) ?? latest.date
            let averageAmount = items.reduce(Decimal.zero) { $0 + $1.amount } / Decimal(items.count)
            let inferredCategory = ExpenseCategory(rawValue: latest.category) ?? .other

            return BillSuggestion(
                merchant: latest.title,
                category: inferredCategory,
                averageAmount: averageAmount,
                cadenceDays: cadence,
                nextExpectedAt: nextExpectedAt,
                sampleCount: items.count
            )
        }
        .sorted { $0.nextExpectedAt < $1.nextExpectedAt }
        .prefix(3)
        .map { $0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Flujo recurrente",
                    title: "Facturas",
                    summary: "Sigue próximos vencimientos, registra pagos y mantén obligaciones mensuales en el mismo libro local. Haz visibles las facturas próximas o atrasadas antes de que sorprendan.",
                    systemImage: "calendar.badge.clock",
                    character: .tikki,
                    expression: .warning,
                    sceneKey: "guide_14_bill_radar_tikki"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Resumen de facturas")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            BrandMetricTile(
                                title: "Facturas seguidas",
                                value: "\(viewModel.bills.count)",
                                systemImage: "doc.text.fill"
                            )
                            BrandMetricTile(
                                title: "Total mensual",
                                value: totalMonthlyBills.formatted(.currency(code: currencyCode)),
                                systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird"
                            )
                            BrandMetricTile(
                                title: "Por vencer",
                                value: "\(dueSoonCount)",
                                systemImage: "clock.badge.exclamationmark.fill"
                            )
                            BrandMetricTile(
                                title: "Atrasadas",
                                value: "\(overdueCount)",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            BrandMetricTile(
                                title: "Autopago",
                                value: "\(autopayCount)",
                                systemImage: "repeat.circle.fill"
                            )
                        }

                        if overdueCount > 0 || dueSoonCount > 0 {
                            BrandFeatureRow(
                                systemImage: "bell.badge.fill",
                                title: "Necesita atención",
                                detail: overdueCount > 0
                                    ? AppLocalization.localized("%d factura está atrasada y debe resolverse primero.", arguments: overdueCount)
                                    : AppLocalization.localized("%d factura vence pronto, así que el próximo pago debería verse fácil.", arguments: dueSoonCount)
                            )
                        } else {
                            BrandFeatureRow(
                                systemImage: "checkmark.circle.fill",
                                title: "Estable por ahora",
                                detail: "No hay facturas atrasadas ni por vencer, así que la cola recurrente está tranquila."
                            )
                        }
                    }
                }

                if !billSuggestions.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Detectadas en tu historial")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            Text("Los comercios recurrentes de tus gastos recientes pueden convertirse en facturas seguidas con un toque.")
                                .font(.subheadline)
                                .foregroundStyle(BrandTheme.muted)

                            ForEach(billSuggestions) { suggestion in
                                HStack(alignment: .top, spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.merchant)
                                            .font(.headline)
                                            .foregroundStyle(BrandTheme.ink)
                                        Text(
                                            AppLocalization.localized(
                                                "%d coincidencias · cada ~%d días",
                                                arguments: suggestion.sampleCount,
                                                suggestion.cadenceDays
                                            )
                                        )
                                            .font(.footnote)
                                            .foregroundStyle(BrandTheme.muted)
                                        Text(
                                            AppLocalization.localized(
                                                "Próximo vencimiento %@",
                                                arguments: suggestion.nextExpectedAt.formatted(date: .abbreviated, time: .omitted)
                                            )
                                        )
                                            .font(.footnote)
                                            .foregroundStyle(BrandTheme.muted)
                                    }

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 8) {
                                        Text(suggestion.averageAmount.formatted(.currency(code: currencyCode)))
                                            .font(.headline)
                                            .foregroundStyle(BrandTheme.ink)
                                        Button("Seguir") {
                                            Task { await trackSuggestion(suggestion) }
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                            }
                        }
                    }
                }

                if viewModel.bills.isEmpty {
                    FinanceEmptyStateCard(
                        title: "No hay facturas recurrentes",
                        summary: "Agrega renta, suscripciones, servicios o cualquier pago repetido para poder marcarlos pagados desde un solo lugar.",
                        systemImage: "calendar.badge.plus"
                    )
                } else {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Facturas activas")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            if activeBills.isEmpty {
                                Text("No hay facturas activas ahora mismo. Las pausadas siguen abajo y pueden retomarse en cualquier momento.")
                                    .font(.footnote)
                                    .foregroundStyle(BrandTheme.muted)
                            }

                            ForEach(activeBills) { bill in
                                billRow(bill, isPaused: false)

                                if bill.id != activeBills.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                if !pausedBills.isEmpty {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Paused bills")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            Text("Paused bills stay saved locally and can be brought back with one tap.")
                                .font(.footnote)
                                .foregroundStyle(BrandTheme.muted)

                            ForEach(pausedBills) { bill in
                                billRow(bill, isPaused: true)

                                if bill.id != pausedBills.last?.id {
                                    Divider()
                                }
                            }
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Add recurring bill")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        FinanceField(label: "Bill title", placeholder: "Rent", text: $title)
                        FinanceField(
                            label: "Amount",
                            placeholder: "1250.00",
                            text: $amount,
                            keyboard: .decimalPad,
                            capitalization: .never
                        )

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Due day")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Stepper(value: $dueDay, in: 1...31) {
                                Text(AppLocalization.localized("Every month on day %d", arguments: dueDay))
                                    .foregroundStyle(BrandTheme.ink)
                            }
                        }

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

                        Toggle("Autopay enabled", isOn: $autopay)
                            .tint(BrandTheme.primary)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button("Save bill") {
                            Task { await saveBill() }
                        }
                        .buttonStyle(PrimaryCTAStyle())
                    }
                }
            }
            .padding(24)
        }
        .background(FinanceScreenBackground())
        .accessibilityIdentifier("bills.screen")
        .navigationTitle("Bills")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.ledger == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private func billRow(_ bill: BillRecord, isPaused: Bool) -> some View {
        let status = viewModel.ledger?.billStatus(for: bill) ?? .upcoming

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.title)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text("\(FinanceToolFormatting.dueDateText(for: bill, ledger: viewModel.ledger)) · \(bill.category.localizedTitle)")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(bill.amount, format: .currency(code: currencyCode))
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text(status.localizedTitle)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor(status))
                }
            }

            FlowStack(spacing: 8, rowSpacing: 8) {
                billChip(title: status.localizedTitle, systemImage: status.symbolName, color: statusColor(status))
                billChip(
                    title: isPaused ? "Paused" : "Active",
                    systemImage: isPaused ? "pause.circle.fill" : "play.circle.fill",
                    color: isPaused ? .orange : BrandTheme.primary
                )
                if bill.autopay {
                    billChip(title: "Autopay", systemImage: "repeat.circle.fill", color: BrandTheme.primary)
                }
                if status == .overdue {
                    billChip(title: "Pay now", systemImage: "exclamationmark.circle.fill", color: .red)
                } else if status == .dueSoon {
                    billChip(title: "Schedule", systemImage: "clock.badge.exclamationmark.fill", color: .orange)
                }

                if let lastPaidAt = bill.lastPaidAt {
                    billChip(
                        title: AppLocalization.localized(
                            "Paid %@",
                            arguments: lastPaidAt.formatted(date: .abbreviated, time: .omitted)
                        ),
                        systemImage: "checkmark.circle.fill",
                        color: BrandTheme.primary
                    )
                }
            }

            FlowStack(spacing: 10, rowSpacing: 10) {
                Button("Log payment") {
                    Task { await viewModel.payBill(bill.id) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(isPaused ? "Resume" : "Pause") {
                    togglePause(bill.id)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(bill.autopay ? "Disable autopay" : "Enable autopay") {
                    Task { await viewModel.toggleBillAutopay(bill.id) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button(role: .destructive) {
                    Task { await viewModel.deleteBill(bill.id) }
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }

    private func isPaused(_ billID: UUID) -> Bool {
        pausedBillIDs.contains(billID.uuidString)
    }

    private func togglePause(_ billID: UUID) {
        var updated = pausedBillIDs
        let key = billID.uuidString
        if updated.contains(key) {
            updated.remove(key)
        } else {
            updated.insert(key)
        }
        pausedBillIDsJSON = encodePausedBillIDs(updated)
    }

    private func decodePausedBillIDs(_ raw: String) -> Set<String> {
        guard let data = raw.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(decoded)
    }

    private func encodePausedBillIDs(_ ids: Set<String>) -> String {
        guard let data = try? JSONEncoder().encode(Array(ids)),
              let string = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        return string
    }

    private func statusColor(_ status: BillPaymentState) -> Color {
        switch status {
        case .paid:
            return BrandTheme.primary
        case .dueSoon:
            return .orange
        case .upcoming:
            return BrandTheme.muted
        case .overdue:
            return .red
        }
    }

    private func billChip(title: String, systemImage: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption.weight(.semibold))
            Text(title.appLocalized)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(color.opacity(0.12))
        .clipShape(Capsule())
    }

    private func saveBill() async {
        guard let amountValue = FinanceToolFormatting.decimal(from: amount) else {
            errorMessage = "Enter a valid amount.".appLocalized
            return
        }

        errorMessage = nil
        await viewModel.addBill(
            BillDraft(
                title: title,
                amount: amountValue,
                dueDay: dueDay,
                category: category,
                autopay: autopay
            )
        )

        title = ""
        amount = ""
        dueDay = 1
        category = .bills
        autopay = false
    }

    private func trackSuggestion(_ suggestion: BillSuggestion) async {
        let dueDay = Calendar.autoupdatingCurrent.component(.day, from: suggestion.nextExpectedAt)
        await viewModel.addBill(
            BillDraft(
                title: suggestion.merchant,
                amount: suggestion.averageAmount,
                dueDay: dueDay,
                category: suggestion.category,
                autopay: false
            )
        )
    }

    private func normalizedKey(_ value: String) -> String {
        value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
    }
}
