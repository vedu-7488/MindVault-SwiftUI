import SwiftUI

struct StickyNotesBoardView: View {
    @EnvironmentObject private var themeManager: ThemeManager
    let notes: [StickyNoteEntity]
    let onNoteMoved: (StickyNoteEntity, CGSize) -> Void
    let onNoteTapped: (StickyNoteEntity) -> Void

    @State private var liveOffsets: [UUID: CGSize] = [:]

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(notes, id: \.id) { note in
                sticky(note)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220, alignment: .topLeading)
    }

    private func sticky(_ note: StickyNoteEntity) -> some View {
        let offset = liveOffsets[note.id] ?? CGSize(width: note.x, height: note.y)

        return Text(note.text)
            .font(themeManager.font(.callout, weight: .medium))
            .foregroundStyle(Color.black.opacity(0.78))
            .padding(18)
            .frame(width: 170, alignment: .leading)
            .background(Color(hex: note.colorHex), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .rotationEffect(.degrees(note.rotation))
            .shadow(color: themeManager.shadowColor.opacity(0.8), radius: 12, y: 8)
            .offset(offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        liveOffsets[note.id] = value.translation + CGSize(width: note.x, height: note.y)
                    }
                    .onEnded { value in
                        let finalOffset = value.translation + CGSize(width: note.x, height: note.y)
                        liveOffsets[note.id] = finalOffset
                        onNoteMoved(note, finalOffset)
                    }
            )
            .onTapGesture {
                onNoteTapped(note)
            }
            .animation(.interactiveSpring(response: 0.34, dampingFraction: 0.78), value: offset)
    }
}

private extension CGSize {
    static func + (lhs: CGSize, rhs: CGSize) -> CGSize {
        CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.replacingOccurrences(of: "#", with: "")
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (242, 237, 228)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: 1
        )
    }
}
