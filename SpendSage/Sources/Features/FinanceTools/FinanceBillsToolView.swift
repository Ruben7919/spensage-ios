import SwiftUI

struct FinanceBillsToolView: View {
    @ObservedObject var viewModel: AppViewModel

    @State private var title = ""
    @State private var amount = ""
    @State private var dueDay = 1
    @State private var category = ExpenseCategory.bills
    @State private var autopay = false
    @State private var errorMessage: String?

    private var totalMonthlyBills: Decimal {
        viewModel.bills.reduce(Decimal.zero) { $0 + $1.amount }
    }

    private var overdueCount: Int {
        guard let ledger = viewModel.ledger else { return 0 }
        return viewModel.bills.filter { ledger.billStatus(for: $0) == .overdue }.count
    }

    private var dueSoonCount: Int {
        guard let ledger = viewModel.ledger else { return 0 }
        return viewModel.bills.filter { ledger.billStatus(for: $0) == .dueSoon }.count
    }

    private var autopayCount: Int {
        viewModel.bills.filter { $0.autopay }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Recurring cash flow",
                    title: "Bills",
                    summary: "Track upcoming due dates, record payments, and keep monthly obligations in the same local ledger.",
                    systemImage: "calendar.badge.clock"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Bills overview")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        HStack(spacing: 12) {
                            BrandMetricTile(
                                title: "Tracked bills",
                                value: "\(viewModel.bills.count)",
                                systemImage: "doc.text.fill"
                            )
                            BrandMetricTile(
                                title: "Monthly total",
                                value: totalMonthlyBills.formatted(.currency(code: "USD")),
                                systemImage: "dollarsign.gauge.chart.leftthird.topthird.rightthird"
                            )
                            BrandMetricTile(
                                title: "Due soon",
                                value: "\(dueSoonCount)",
                                systemImage: "clock.badge.exclamationmark.fill"
                            )
                            BrandMetricTile(
                                title: "Overdue",
                                value: "\(overdueCount)",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                        }
                    }
                }

                if viewModel.bills.isEmpty {
                    FinanceEmptyStateCard(
                        title: "No recurring bills",
                        summary: "Add rent, subscriptions, utilities, or any repeating payment so you can mark them paid from one place.",
                        systemImage: "calendar.badge.plus"
                    )
                } else {
                    SurfaceCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Upcoming bills")
                                .font(.headline)
                                .foregroundStyle(BrandTheme.ink)

                            ForEach(viewModel.bills) { bill in
                                billRow(bill)

                                if bill.id != viewModel.bills.last?.id {
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
                                Text("Every month on day \(dueDay)")
                                    .foregroundStyle(BrandTheme.ink)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Category")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(BrandTheme.muted)

                            Picker("Category", selection: $category) {
                                ForEach(ExpenseCategory.allCases) { item in
                                    Label(item.rawValue, systemImage: item.symbolName)
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
        .background(BrandTheme.canvas)
        .navigationTitle("Bills")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.ledger == nil {
                await viewModel.refreshDashboard()
            }
        }
    }

    private func billRow(_ bill: BillRecord) -> some View {
        let status = viewModel.ledger?.billStatus(for: bill) ?? .upcoming

        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bill.title)
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text("\(FinanceToolFormatting.dueDateText(for: bill, ledger: viewModel.ledger)) · \(bill.category.rawValue)")
                        .font(.footnote)
                        .foregroundStyle(BrandTheme.muted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(bill.amount, format: .currency(code: "USD"))
                        .font(.headline)
                        .foregroundStyle(BrandTheme.ink)

                    Text(status.rawValue)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(statusColor(status))
                }
            }

            HStack(spacing: 8) {
                billChip(title: status.rawValue, systemImage: status.symbolName, color: statusColor(status))
                if bill.autopay {
                    billChip(title: "Autopay", systemImage: "repeat.circle.fill", color: BrandTheme.primary)
                }
                if let lastPaidAt = bill.lastPaidAt {
                    billChip(
                        title: "Paid \(lastPaidAt.formatted(date: .abbreviated, time: .omitted))",
                        systemImage: "checkmark.circle.fill",
                        color: BrandTheme.primary
                    )
                }
                Spacer()
            }

            HStack(spacing: 10) {
                Button(bill.lastPaidAt == nil ? "Mark paid" : "Record again") {
                    Task { await viewModel.payBill(bill.id) }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button(bill.autopay ? "Disable autopay" : "Enable autopay") {
                    Task { await viewModel.toggleBillAutopay(bill.id) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

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
        Label(title, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
    }

    private func saveBill() async {
        guard let amountValue = FinanceToolFormatting.decimal(from: amount) else {
            errorMessage = "Enter a valid amount."
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
}
