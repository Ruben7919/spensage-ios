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
    @State private var isPresentingCamera = false
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                FinanceToolsHeaderCard(
                    eyebrow: "Manual receipt draft",
                    title: "Receipt Scan",
                    summary: "Capture a receipt image for reference, then type the fields you want to store locally. No OCR or external service is required.",
                    systemImage: "camera.viewfinder"
                )

                if let notice = viewModel.notice {
                    FinanceNoticeCard(message: notice)
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Receipt reference")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

                        if let capturedImage {
                            Image(uiImage: capturedImage)
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        } else {
                            FinanceEmptyStateCard(
                                title: "No image attached",
                                summary: "Use the camera if available, or skip it and enter the draft manually.",
                                systemImage: "receipt"
                            )
                        }

                        HStack(spacing: 12) {
                            Button("Capture receipt") {
                                if UIImagePickerController.isSourceTypeAvailable(.camera) {
                                    isPresentingCamera = true
                                } else {
                                    errorMessage = "Camera capture is not available on this device."
                                }
                            }
                            .buttonStyle(SecondaryCTAStyle())

                            Button("Load sample draft") {
                                merchant = "Blue Bottle Coffee"
                                amount = "8.75"
                                category = .coffee
                                date = .now
                                note = "Manual receipt draft from in-store purchase"
                                errorMessage = nil
                            }
                            .buttonStyle(SecondaryCTAStyle())
                        }
                    }
                }

                SurfaceCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Draft details")
                            .font(.headline)
                            .foregroundStyle(BrandTheme.ink)

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
                                    Label(item.rawValue, systemImage: item.symbolName)
                                        .tag(item)
                                }
                            }
                            .pickerStyle(.menu)
                        }

                        DatePicker("Receipt date", selection: $date, displayedComponents: .date)
                            .tint(BrandTheme.primary)

                        FinanceMultilineField(
                            label: "Note",
                            placeholder: "Optional memo, items, or reimbursement context",
                            text: $note
                        )

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(.red)
                        }

                        Button("Save draft to ledger") {
                            Task { await saveDraft() }
                        }
                        .buttonStyle(PrimaryCTAStyle())
                    }
                }
            }
            .padding(24)
        }
        .background(BrandTheme.canvas)
        .navigationTitle("Receipt Scan")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if viewModel.ledger == nil {
                await viewModel.refreshDashboard()
            }
        }
        .sheet(isPresented: $isPresentingCamera) {
            ReceiptCameraPicker(image: $capturedImage)
        }
    }

    private func saveDraft() async {
        guard let amountValue = FinanceToolFormatting.decimal(from: amount) else {
            errorMessage = "Enter a valid amount."
            return
        }

        errorMessage = nil
        await viewModel.addExpense(
            ExpenseDraft(
                merchant: merchant,
                amount: amountValue,
                category: category,
                date: date,
                note: note
            )
        )

        merchant = ""
        amount = ""
        category = .groceries
        date = .now
        note = ""
        capturedImage = nil
    }
}

private struct ReceiptCameraPicker: UIViewControllerRepresentable {
    @Environment(\.dismiss) private var dismiss
    @Binding var image: UIImage?

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
            parent.image = info[.originalImage] as? UIImage
            parent.dismiss()
        }
    }
}
