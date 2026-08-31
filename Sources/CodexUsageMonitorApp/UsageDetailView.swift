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
            // 弹出/收起时窗口高度做动画，fixedSize 让内容保持固有高度被窗口
            // 裁切「揭开」，而不是被逐帧压缩再展开（视觉上的拉伸）
            .fixedSize(horizontal: false, vertical: true)
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
        VStack(alignment: .leading, spacing: metrics.detailSpacing) {
            detailRow(
                label: presentation.localization.primaryResetLabel,
                value: dateText(windows[0].resetsAt)
            )
            detailRow(
                label: presentation.localization.secondaryResetLabel,
                value: dateText(windows[1].resetsAt)
            )

            // 分隔线挂在行 overlay 上：插入 VStack 的分隔视图（Divider 或
            // Rectangle）会改变兄弟行的布局协商，把上方行的数值压到缩放档。
            detailRow(
                label: presentation.localization.resetCreditsLabel,
                value: presentation.localization.resetCreditCount(
                    viewModel.snapshot?.resetCreditsAvailable
                ),
                valueWeight: .semibold
            )
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Color(nsColor: .separatorColor))
                    .frame(height: 1)
                    .offset(y: -metrics.detailSpacing / 2)
            }

            detailRow(
                label: presentation.localization.resetCreditExpiryLabel,
                value: expiryDateText
            )
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
        HStack(spacing: 0) {
            Text(label)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Spacer(minLength: metrics.detailValueSpacing)
            Text(value)
                .fontWeight(valueWeight)
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .layoutPriority(1)
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
            return presentation.localization.unavailableText
        }
        return date.formatted(
            .dateTime
                .month()
                .day()
                .hour()
                .minute()
                .locale(Locale(identifier: presentation.localization.localeIdentifier))
        )
    }

    private var expiryDateText: String {
        guard let date = viewModel.snapshot?.resetCreditExpiresAt else {
            return presentation.localization.unknownText
        }
        return date.formatted(
            .dateTime
                .month()
                .day()
                .hour()
                .minute()
                .locale(Locale(identifier: presentation.localization.localeIdentifier))
        )
    }
}
