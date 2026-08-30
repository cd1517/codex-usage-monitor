import AppKit
import SwiftUI

#if SWIFT_PACKAGE
import CodexUsageMonitorCore
#endif

struct UsageView: View {
    @ObservedObject var viewModel: UsageViewModel
    let onHoverChange: (Bool) -> Void

    @State private var isExpanded = false

    var body: some View {
        VStack(spacing: 0) {
            compactStrip
                .frame(height: 30)

            if isExpanded {
                Divider()
                    .padding(.horizontal, 10)
                detailRows
            }
        }
        .frame(
            width: isExpanded ? 300 : 220,
            height: isExpanded ? 132 : 30,
            alignment: .top
        )
        .background(Color(nsColor: .windowBackgroundColor))
        .contentShape(Rectangle())
        .onHover { isHovering in
            withAnimation(.easeInOut(duration: 0.14)) {
                isExpanded = isHovering
            }
            onHoverChange(isHovering)
        }
    }

    private var compactStrip: some View {
        HStack(spacing: 5) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 11, weight: .regular))
                .foregroundStyle(.secondary)
                .frame(width: 15, height: 17)

            compactValue(label: "5小时", value: windows[0].remainingPercent)

            Rectangle()
                .fill(.secondary.opacity(0.22))
                .frame(width: 1, height: 12)

            compactValue(label: "7天", value: windows[1].remainingPercent)

            Spacer(minLength: 2)

            Rectangle()
                .fill(.secondary.opacity(0.45))
                .frame(width: 1, height: 17)
        }
        .padding(.leading, 7)
        .padding(.trailing, 5)
    }

    private func compactValue(label: String, value: Int?) -> some View {
        HStack(spacing: 3) {
            Text(label)
                .foregroundStyle(.secondary)
            Text(value.map { "\($0)%" } ?? "--")
                .fontWeight(.semibold)
                .monospacedDigit()
        }
        .font(.system(size: 12.5, weight: .regular))
        .fixedSize()
    }

    private var detailRows: some View {
        VStack(spacing: 7) {
            detailRow(label: "5 小时重置", value: dateText(windows[0].resetsAt))
            detailRow(label: "7 天重置", value: dateText(windows[1].resetsAt))

            Divider()

            HStack(spacing: 5) {
                Text("重置额度")
                    .foregroundStyle(.secondary)
                Text(viewModel.snapshot?.resetCreditsAvailable.map(String.init) ?? "--")
                    .fontWeight(.semibold)
                    .monospacedDigit()
                Spacer()
                Text(expiryText)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .font(.system(size: 12))
        }
        .padding(.horizontal, 12)
        .padding(.top, 8)
        .padding(.bottom, 9)
    }

    private func detailRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .font(.system(size: 12))
    }

    private var windows: [UsageWindow] {
        viewModel.snapshot?.windows ?? [
            UsageWindow(label: "5 小时", remainingPercent: nil, resetsAt: nil),
            UsageWindow(label: "7 天", remainingPercent: nil, resetsAt: nil)
        ]
    }

    private func dateText(_ date: Date?) -> String {
        guard let date else {
            return "不可用"
        }
        return date.formatted(.dateTime.month().day().hour().minute())
    }

    private var expiryText: String {
        guard let date = viewModel.snapshot?.resetCreditExpiresAt else {
            return "有效期未知"
        }
        return "有效期至 \(date.formatted(.dateTime.month().day().hour().minute()))"
    }
}
