import CoreGraphics

struct HomeBackgroundLayout {
    enum Profile {
        case phonePortrait
        case phoneLandscape
        case padPortrait
        case padLandscape
    }

    let profile: Profile
    let leftMathRect: CGRect   // normalized [0,1]
    let rightMathRect: CGRect  // normalized [0,1]
    let dotMatrixRect: CGRect  // normalized [0,1]

    let ribbonCount: Int
    let ribbonLineWidthScale: CGFloat
    let ribbonBlurScale: CGFloat
    let ribbonOpacityScale: CGFloat
    let ribbonAmplitudeScale: CGFloat

    let mathOpacityScale: CGFloat
    let shouldDrawLeftGraph: Bool
    let shouldDrawRightGeometry: Bool
    let shouldDrawDotMatrix: Bool

    static func resolve(size: CGSize) -> HomeBackgroundLayout {
        let isPad = size.width >= 700
        let isPortrait = size.height > size.width

        switch (isPad, isPortrait) {
        case (false, true):
            return HomeBackgroundLayout(
                profile: .phonePortrait,
                leftMathRect: CGRect(x: 0.04, y: 0.055, width: 0.58, height: 0.15),
                rightMathRect: CGRect(x: 0.74, y: 0.06, width: 0.18, height: 0.10),
                dotMatrixRect: CGRect(x: 0.80, y: 0.085, width: 0.125, height: 0.064),
                ribbonCount: 3,
                ribbonLineWidthScale: 0.86,
                ribbonBlurScale: 0.88,
                ribbonOpacityScale: 0.90,
                ribbonAmplitudeScale: 0.72,
                mathOpacityScale: 0.75,
                shouldDrawLeftGraph: true,
                shouldDrawRightGeometry: false,
                shouldDrawDotMatrix: true
            )
        case (false, false):
            return HomeBackgroundLayout(
                profile: .phoneLandscape,
                leftMathRect: CGRect(x: 0.04, y: 0.03, width: 0.28, height: 0.16),
                rightMathRect: CGRect(x: 0.76, y: 0.06, width: 0.14, height: 0.14),
                dotMatrixRect: CGRect(x: 0.90, y: 0.08, width: 0.08, height: 0.10),
                ribbonCount: 2,
                ribbonLineWidthScale: 0.92,
                ribbonBlurScale: 0.90,
                ribbonOpacityScale: 0.95,
                ribbonAmplitudeScale: 0.78,
                mathOpacityScale: 0.68,
                shouldDrawLeftGraph: true,
                shouldDrawRightGeometry: false,
                shouldDrawDotMatrix: true
            )
        case (true, true):
            return HomeBackgroundLayout(
                profile: .padPortrait,
                leftMathRect: CGRect(x: 0.03, y: 0.05, width: 0.30, height: 0.30),
                rightMathRect: CGRect(x: 0.72, y: 0.05, width: 0.24, height: 0.30),
                dotMatrixRect: CGRect(x: 0.93, y: 0.08, width: 0.04, height: 0.08),
                ribbonCount: 4,
                ribbonLineWidthScale: 1.00,
                ribbonBlurScale: 1.00,
                ribbonOpacityScale: 1.00,
                ribbonAmplitudeScale: 0.92,
                mathOpacityScale: 0.90,
                shouldDrawLeftGraph: true,
                shouldDrawRightGeometry: true,
                shouldDrawDotMatrix: true
            )
        case (true, false):
            return HomeBackgroundLayout(
                profile: .padLandscape,
                leftMathRect: CGRect(x: 0.03, y: 0.05, width: 0.30, height: 0.30),
                rightMathRect: CGRect(x: 0.72, y: 0.05, width: 0.24, height: 0.30),
                dotMatrixRect: CGRect(x: 0.93, y: 0.08, width: 0.04, height: 0.08),
                ribbonCount: 5,
                ribbonLineWidthScale: 1.06,
                ribbonBlurScale: 1.06,
                ribbonOpacityScale: 1.00,
                ribbonAmplitudeScale: 1.00,
                mathOpacityScale: 1.00,
                shouldDrawLeftGraph: true,
                shouldDrawRightGeometry: true,
                shouldDrawDotMatrix: true
            )
        }
    }
}
