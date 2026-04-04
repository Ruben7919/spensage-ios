import Foundation
import Testing
@testable import SpendSage

struct ReceiptVisionServiceTests {
    @Test
    func parserDetectsMerchantTotalAndDate() {
        let analysis = ReceiptVisionService.parse(
            recognizedLines: [
                "BLUE BOTTLE COFFEE",
                "123 Market Street",
                "04/03/2026 08:41 AM",
                "Latte 6.50",
                "Tax 0.52",
                "Total 7.02"
            ],
            locale: Locale(identifier: "en_US")
        )

        #expect(analysis.merchant == "BLUE BOTTLE COFFEE")
        #expect(analysis.amount == Decimal(string: "7.02"))
        #expect(analysis.category == .coffee)
        #expect(analysis.date != nil)
    }

    @Test
    func parserPrefersTotalLineOverItemLine() {
        let analysis = ReceiptVisionService.parse(
            recognizedLines: [
                "MCDONALD'S",
                "Big Mac 9.99",
                "Fries 4.50",
                "Grand Total 15.38"
            ],
            locale: Locale(identifier: "en_US")
        )

        #expect(analysis.amount == Decimal(string: "15.38"))
        #expect(analysis.category == .dining)
    }

    @Test
    func parserSupportsCommaDecimals() {
        let analysis = ReceiptVisionService.parse(
            recognizedLines: [
                "SUPERMERCADO CENTRAL",
                "Fecha 03/04/2026",
                "Importe total 18,45"
            ],
            locale: Locale(identifier: "es_ES")
        )

        #expect(analysis.merchant == "SUPERMERCADO CENTRAL")
        #expect(analysis.amount == Decimal(string: "18.45"))
        #expect(analysis.date != nil)
    }
}
