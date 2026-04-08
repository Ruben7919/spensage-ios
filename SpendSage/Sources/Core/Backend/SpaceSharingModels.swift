import Foundation

enum SpaceRole: String, Codable, CaseIterable, Identifiable {
    case owner
    case editor
    case viewer

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .owner:
            return "Owner"
        case .editor:
            return "Editor"
        case .viewer:
            return "Viewer"
        }
    }

    var canWrite: Bool {
        switch self {
        case .owner, .editor:
            return true
        case .viewer:
            return false
        }
    }

    var canManageMembers: Bool {
        self == .owner
    }
}

struct SpaceSummary: Codable, Equatable, Identifiable {
    var id: String { spaceId }
    let spaceId: String
    let ownerUserId: String
    let displayName: String
    let role: SpaceRole

    var isPersonalSpace: Bool {
        spaceId == ownerUserId
    }

    var displayTitle: String {
        isPersonalSpace ? "Personal" : displayName
    }
}

struct SpaceInvite: Codable, Equatable, Identifiable {
    enum Status: String, Codable, CaseIterable {
        case pending = "PENDING"
        case accepted = "ACCEPTED"
        case revoked = "REVOKED"
        case expired = "EXPIRED"
    }

    var id: String { code }
    let code: String
    let spaceId: String
    let recipientEmailLower: String
    let role: SpaceRole
    let inviterUserId: String
    let inviterEmailLower: String?
    let createdAt: String
    let expiresAt: String?
    let status: Status
    let acceptedByUserId: String?
    let acceptedAt: String?
}

struct SpaceMember: Codable, Equatable, Identifiable {
    var id: String { userId }
    let spaceId: String
    let userId: String
    let userEmailLower: String?
    let role: SpaceRole
    let notificationsEnabled: Bool
    let addedAt: String
    let addedByUserId: String

    var isOwner: Bool {
        role == .owner
    }
}

struct FamilyEntitlements: Codable, Equatable {
    let enforced: Bool
    let ownerPlanId: String
    let ownerHasFamilyEntitlement: Bool
    let memberEditorUpgradeRequiresEntitlement: Bool
}

struct FamilyPermissions: Codable, Equatable {
    let callerRole: SpaceRole
    let canWrite: Bool
    let canManageMembers: Bool
    let canInvite: Bool
    let canPromoteToEditor: Bool
}

struct FamilySharingModel: Codable, Equatable {
    let spaceId: String
    let ownerUserId: String
    let mode: String
    let budgetScope: String
    let memberCount: Int
    let pendingInviteCount: Int
    let maxMembers: Int
    let remainingSlots: Int
    let entitlements: FamilyEntitlements
    let permissions: FamilyPermissions
}

struct CreateInviteInput: Encodable, Equatable {
    let spaceId: String?
    let recipientEmail: String
    let role: SpaceRole
    let expiresInDays: Int?
}

struct CreateInviteResult: Decodable, Equatable {
    let invite: SpaceInvite
    let deepLink: String
    let webLink: String?
}

struct AcceptInviteResult: Decodable, Equatable {
    let accepted: Bool
    let spaceId: String
    let role: SpaceRole
}

struct UpdateSpaceMemberPatch: Encodable, Equatable {
    let role: SpaceRole?
    let notificationsEnabled: Bool?
}
