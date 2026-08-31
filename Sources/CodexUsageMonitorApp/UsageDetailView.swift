import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

struct UsageDetailView: View {
    @ObservedObject var viewModel: UsageViewModel
    @ObservedObject var presentation: OverlayPresentation

    private var metrics: OverlayMetrics {
        presentation.metrics
    }

    var body: some View {
        detailRows
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background {
                RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor))
                    .overlay {
                        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                            .fill(Color.primary.opacity(0.055))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: metrics.cornerRadius, style: .continuous)
                            .stroke(
                                Color(nsColor: .separatorColor).opacity(0.55),
                                lineWidth: 1
                            )
                    }
            }
            .contentShape(Rectangle())
            .animation(.easeInOut(duration: 0.16), value: presentation.fontSize)
    }

    private var detailRows: some View {
        Grid(
            alignment: .leading,
            horizontalSpacing: 0,
            verticalSpacing: metrics.detailSpacing
        ) {
            detailRow(label: "5 小时重置", value: dateText(windows[0].resetsAt))
            detailRow(label: "1 周重置", value: dateText(windows[1].resetsAt))

            Divider()
                .gridCellColumns(3)

            detailRow(
                label: "重置额度",
                value: viewModel.snapshot?.resetCreditsAvailable.map(String.init) ?? "--",
                valueWeight: .semibold
            )
            detailRow(label: "有效期至", value: expiryDateText)
        }
        .padding(.horizontal, metrics.detailHorizontalPadding)
        .padding(.top, metrics.detailTopPadding)
        .padding(.bottom, metrics.detailBottomPadding)
    }

    private func detailRow(
        label: String,
        value: String,
        valueWeight: Font.Weight = .medium
    ) -> some View {
        GridRow {
            Text(label)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: metrics.detailValueSpacing)
            Text(value)
                .fontWeight(valueWeight)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .font(.system(size: metrics.fontSize))
    }

    private var windows: [UsageWindow] {
        viewModel.snapshot?.windows ?? [
            UsageWindow(label: "5 小时", remainingPercent: nil, resetsAt: nil),
            UsageWindow(label: "1 周", remainingPercent: nil, resetsAt: nil)
        ]
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else {
            return "不可用"
        }
        return date.formatted(.dateTime.month().day().hour().minute())
    }

    private var expiryDateText: String {
        guard let date = viewModel.snapshot?.resetCreditExpiresAt else {
            return "未知"
        }
        return date.formatted(.dateTime.month().day().hour().minute())
    }
}
