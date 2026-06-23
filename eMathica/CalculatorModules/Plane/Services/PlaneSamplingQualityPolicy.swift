import Foundation
import EMathicaMathCore

struct PlaneSamplingQualityPolicy {
    func qualityProfile(
        isInputEditing: Bool,
        isCanvasInteracting: Bool,
        userPreferred: SamplingQualityProfile = .balanced
    ) -> SamplingQualityProfile {
        qualityProfile(
            isInteracting: isInputEditing || isCanvasInteracting,
            userPreferred: userPreferred
        )
    }

    func qualityProfile(
        isInteracting: Bool,
        userPreferred: SamplingQualityProfile = .balanced
    ) -> SamplingQualityProfile {
        if isInteracting {
            return .preview
        }
        return userPreferred
    }
}
