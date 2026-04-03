import Foundation

enum PreviewFinanceData {
    static let seedLedger = LocalFinanceLedger(
        monthlyIncome: 3_200,
        monthlyBudget: 2_400,
        expenses: [
            ExpenseRecord(
                id: UUID(uuidString: "11111111-1111-1111-1111-111111111111") ?? UUID(),
                merchant: "Morning Grounds",
                category: .coffee,
                amount: 4.80,
                date: Calendar.autoupdatingCurrent.date(byAdding: .day, value: -1, to: .now) ?? .now,
                note: "Cold brew"
            ),
            ExpenseRecord(
                id: UUID(uuidString: "22222222-2222-2222-2222-222222222222") ?? UUID(),
                merchant: "Supermarket",
                category: .groceries,
                amount: 86.40,
                date: Calendar.autoupdatingCurrent.date(byAdding: .day, value: -2, to: .now) ?? .now,
                note: "Weekly refill"
            ),
            ExpenseRecord(
                id: UUID(uuidString: "33333333-3333-3333-3333-333333333333") ?? UUID(),
                merchant: "Ride Share",
                category: .transport,
                amount: 12.10,
                date: Calendar.autoupdatingCurrent.date(byAdding: .day, value: -3, to: .now) ?? .now,
                note: nil
            ),
            ExpenseRecord(
                id: UUID(uuidString: "44444444-4444-4444-4444-444444444444") ?? UUID(),
                merchant: "Utilities",
                category: .bills,
                amount: 112.90,
                date: Calendar.autoupdatingCurrent.date(byAdding: .day, value: -5, to: .now) ?? .now,
                note: "Internet and power"
            ),
            ExpenseRecord(
                id: UUID(uuidString: "55555555-5555-5555-5555-555555555555") ?? UUID(),
                merchant: "Streaming Pack",
                category: .subscriptions,
                amount: 18.99,
                date: Calendar.autoupdatingCurrent.date(byAdding: .day, value: -7, to: .now) ?? .now,
                note: nil
            )
        ],
        accounts: [
            AccountRecord(
                id: UUID(uuidString: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa") ?? UUID(),
                name: "Main Checking",
                institution: "SpendSage Bank",
                balance: 1_840.60,
                kind: .checking
            ),
            AccountRecord(
                id: UUID(uuidString: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb") ?? UUID(),
                name: "Rainy Day Savings",
                institution: "SpendSage Bank",
                balance: 4_920.15,
                kind: .savings
            )
        ],
        bills: [
            BillRecord(
                id: UUID(uuidString: "cccccccc-cccc-cccc-cccc-cccccccccccc") ?? UUID(),
                title: "Internet",
                amount: 54.99,
                dueDay: 8,
                category: .bills,
                autopay: true,
                lastPaidAt: Calendar.autoupdatingCurrent.date(byAdding: .day, value: -20, to: .now)
            ),
            BillRecord(
                id: UUID(uuidString: "dddddddd-dddd-dddd-dddd-dddddddddddd") ?? UUID(),
                title: "Rent",
                amount: 980.00,
                dueDay: 1,
                category: .home,
                autopay: false,
                lastPaidAt: Calendar.autoupdatingCurrent.date(byAdding: .day, value: -2, to: .now)
            )
        ],
        rules: [
            RuleRecord(
                id: UUID(uuidString: "eeeeeeee-eeee-eeee-eeee-eeeeeeeeeeee") ?? UUID(),
                merchantKeyword: "morning",
                category: .coffee,
                note: "Coffee stops"
            ),
            RuleRecord(
                id: UUID(uuidString: "ffffffff-ffff-ffff-ffff-ffffffffffff") ?? UUID(),
                merchantKeyword: "super",
                category: .groceries,
                note: "Grocery merchants"
            )
        ],
        profile: ProfileRecord(
            fullName: "Ruben",
            householdName: "SpendSage Home",
            email: "rubenl97m@gmail.com",
            countryCode: "US",
            marketingOptIn: true
        ),
        updatedAt: .now
    )
}
