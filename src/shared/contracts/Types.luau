--!strict
-- Shared contracts. No Roblox services and no authoritative mutation.

export type VerificationStatus = "UNVERIFIED_PLACEHOLDER" | "VERIFIED"

export type CardId = string
export type PackId = string

export type CardKind = "Hero" | "Spell"

export type CardDefinition = {
	id: CardId,
	kind: CardKind,
	displayName: string,
}

export type OutcomeWeight = {
	cardId: CardId,
	weight: number,
}

export type EarnedCost = {
	status: VerificationStatus,
	currency: "coins",
	amount: number,
}

export type PackDefinition = {
	id: PackId,
	displayName: string,
	verification: VerificationStatus,
	slots: number,
	earnedCost: EarnedCost,
	outcomes: { OutcomeWeight },
}

export type ProductMapping = {
	developerProductId: number,
	packId: PackId,
	displayName: string,
	verification: VerificationStatus,
	paidPurchaseAllowed: boolean,
}

export type PaidPolicy = {
	known: boolean,
	arePaidRandomItemsRestricted: boolean,
}

export type ReceiptDecision = "PurchaseGranted" | "NotProcessedYet"

export type Placement = {
	anchorId: string,
	cardId: CardId,
}

export type PlayerProfile = {
	version: number,
	currencies: {
		coins: number,
		mastery: number,
	},
	collection: { [CardId]: number },
	unopenedPacks: { UnopenedPack },
	receipts: { [string]: ReceiptRecord },
	nextEntitlementNonce: number,
	starterGrantApplied: boolean,
	ranks: { [CardId]: number },
	placement: { Placement },
	realmId: string,
	clearedWaves: { string },
	unlockedPacks: { [PackId]: boolean },
}

export type UnopenedPack = {
	id: string,
	packId: PackId,
	source: "Earned" | "Receipt",
	state: "Unopened",
}

export type ReceiptRecord = {
	purchaseId: string,
	productId: number,
	playerKey: string,
	entitlementId: string,
}

export type Receipt = {
	purchaseId: string,
	productId: number,
	playerKey: string,
}

return {}
