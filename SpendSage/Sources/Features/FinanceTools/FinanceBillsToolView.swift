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
        VStack(alignment: .leading, spacing: 12) {
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

                Text(bill.amount, format: .currency(code: "USD"))
                    .font(.headline)
                    .foregroundStyle(BrandTheme.ink)
            }

            HStack {
                Text(FinanceToolFormatting.paymentStatusText(for: bill))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(bill.lastPaidAt == nil ? BrandTheme.muted : BrandTheme.primary)

                Spacer()

                Button(bill.lastPaidAt == nil ? "Mark paid" : "Record again") {
                    Task { await viewModel.payBill(bill.id) }
                }
                .buttonStyle(SecondaryCTAStyle())
                .frame(maxWidth: 164)
            }
        }
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
