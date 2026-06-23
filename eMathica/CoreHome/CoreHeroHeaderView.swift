import EMathicaWorkspaceKit
import EMathicaThemeKit
import SwiftUI

struct CoreHeroHeaderView: View {
    @Environment(\.colorScheme) private var colorScheme

    let onPrimaryAction: () -> Void
    let onSecondaryAction: () -> Void
    var titleFontSize: CGFloat = 94
    var buttonWidth: CGFloat = 348
    var primaryButtonHeight: CGFloat = 52
    var secondaryButtonHeight: CGFloat = 48
    var buttonFontSize: CGFloat = 17
    var heroTitleBottomSpacing: CGFloat = 30
    var buttonSpacing: CGFloat = 10

    var body: some View {
        VStack(spacing: buttonSpacing) {
            Text("eMathica")
                .font(.system(size: titleFontSize, weight: .bold, design: .rounded))
                .foregroundStyle(titleColor)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .padding(.bottom, heroTitleBottomSpacing)

            LiquidGlassButton("创建作品", systemImage: "plus", kind: .primary, action: onPrimaryAction)
                .font(.system(size: buttonFontSize, weight: .semibold))
                .frame(maxWidth: buttonWidth)
                .frame(height: primaryButtonHeight)

            LiquidGlassButton("公式转写与笔记", systemImage: "pencil.and.scribble", kind: .secondary, action: onSecondaryAction)
                .font(.system(size: buttonFontSize, weight: .semibold))
                .frame(maxWidth: buttonWidth)
                .frame(height: secondaryButtonHeight)
        }
        .frame(maxWidth: .infinity)
    }

    private var titleColor: Color {
        colorScheme == .dark ? Color.white : Color(red: 0.08, green: 0.12, blue: 0.22)
    }

}
