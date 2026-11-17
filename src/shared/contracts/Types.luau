--!strict

export type CardKind = "Hero" | "Spell"
export type VerificationStatus = "UNVERIFIED_PLACEHOLDER" | "VERIFIED"
export type PackSource = "Earned" | "Receipt"

export type Outcome = {
	cardId: string,
	weight: number,
}

export type PackDefinition = {
	id: string,
	displayName: string,
	verification: VerificationStatus,
	slots: number,
	earnedCost: {
		status: VerificationStatus,
		currency: "coins",
		amount: number,
	},
	outcomes: { Outcome },
}

export type CardDefinition = {
	id: string,
	displayName: string,
	kind: CardKind,
	motif: "shield" | "chevron" | "wing" | "stone",
}

export type UnopenedPack = {
	id: string,
	packId: string,
	source: PackSource,
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

export type PaidPolicy = {
	known: boolean,
	arePaidRandomItemsRestricted: boolean,
}

export type ProductMapping = {
	developerProductId: number,
	packId: string,
	displayName: string,
	verification: VerificationStatus,
	paidPurchaseAllowed: boolean,
}

export type Placement = {
	anchorId: string,
	cardId: string,
}

export type PlayerProfile = {
	version: number,
	currencies: { coins: number, mastery: number },
	collection: { [string]: number },
	unopenedPacks: { UnopenedPack },
	receipts: { [string]: ReceiptRecord },
	nextEntitlementNonce: number,
	starterGrantApplied: boolean,
	ranks: { [string]: number },
	placement: { Placement },
	realmId: string,
	clearedWaves: { string },
	unlockedPacks: { [string]: boolean },
	relics: { [string]: boolean },
	equippedRelics: { string },
	bestiary: { [string]: boolean },
	packsOpened: number,
	damageDealt: number,
}

return {}
