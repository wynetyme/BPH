--!strict
-- Pure contracts. Run from the repo root: lune run tests/run.luau

local process = require("@lune/process")

local PackDefinitions = require("../src/shared/data/PackDefinitions")
local CardOdds = require("../src/shared/data/CardOdds")
local PaidGate = require("../src/shared/data/PaidGate")
local RemoteContract = require("../src/shared/net/RemoteContract")
local PackUI = require("../src/shared/ui/PackUI")
local PlayerData = require("../src/shared/server/PlayerData")
local Economy = require("../src/shared/server/Economy")
local PackRoller = require("../src/shared/server/PackRoller")
local PurchaseEntitlements = require("../src/shared/server/PurchaseEntitlements")
local HeroCollection = require("../src/shared/server/HeroCollection")
local RunCombat = require("../src/shared/server/RunCombat")
local CombatTables = require("../src/shared/data/CombatTables")
local CombatSim = require("../src/shared/server/CombatSim")
local Progression = require("../src/shared/server/Progression")
local CombatUI = require("../src/shared/ui/CombatUI")
local Presentation = require("../src/shared/ui/Presentation")

local failed = 0
local passed = 0

local function check(name: string, condition: boolean, detail: string?)
	if condition then
		passed += 1
		print("PASS", name)
	else
		failed += 1
		print("FAIL", name, detail or "")
	end
end

local shipping = PackDefinitions.get("placeholder.starter")
check("shipping pack exists", shipping ~= nil)
if shipping == nil then
	process.exit(1)
end

local shippingCheck = PackDefinitions.validateShipping()
check("shipping catalog stays unverified", shippingCheck.ok)

local listed = CardOdds.listFinalOutcomes(shipping)
check("shipping odds list", listed.ok)
if listed.ok then
	check("basis points sum to 10000", CardOdds.sumBasisPoints(listed.value) == 10000)
	check("placeholder is not demo 60/30/9", listed.value[1].weight == 1 and listed.value[2].weight == 1)
	check("each row shares total weight", listed.value[1].totalWeight == 2 and listed.value[2].basisPoints == 5000)
end

local paidRows = CardOdds.listPaidEligibleOutcomes(shipping, false)
check("placeholder paid outcomes blocked", paidRows.status == "Blocked" and paidRows.reason == "UnverifiedPaidBlocked")

local products = PurchaseEntitlements.shippingProducts()
check(
	"legendary product is configured and not live",
	#products == 1
		and products[1].developerProductId == 3732907303
		and products[1].displayName == "Legendary Booster Pack"
		and products[1].paidPurchaseAllowed == false
		and products[1].packId == "legendary.booster"
		and products[1].packId ~= shipping.id
)

local profile = PlayerData.createDefault()
local blocked = PurchaseEntitlements.evaluatePaidPurchase("placeholder.starter", {
	known = true,
	arePaidRandomItemsRestricted = false,
}, products)
check("live paid prompt blocked", not blocked.ok and blocked.ok == false and blocked.code == "UnverifiedPaidBlocked")

local quote = PackUI.quote(shipping, 10, { known = false, arePaidRandomItemsRestricted = false }, nil)
check("odds button is explicit", quote.oddsButtonLabel == "Odds / Details")
check("robux button off", quote.robuxPurchaseEnabled == false and quote.paidBlockReason == "UnverifiedPaidBlocked")
check("earned quote labelled unverified", quote.earnedLabel == "UNVERIFIED_PLACEHOLDER" and quote.earnedPurchaseEnabled)

local poor = Economy.buyEarnedPack(profile, "placeholder.starter")
check("cannot buy without coins", not poor.ok and poor.ok == false and poor.code == "InsufficientCurrency")
check("failed buy does not grant", #profile.unopenedPacks == 0 and profile.currencies.coins == 0)

Economy.grantCoins(profile, 10)
local bought = Economy.buyEarnedPack(profile, "placeholder.starter")
check("earned buy creates unopened pack", bought.ok and profile.currencies.coins == 0 and #profile.unopenedPacks == 1)
check("earned buy does not roll", HeroCollection.count(profile, "placeholder.frontline") == 0)

local entitlementId = if bought.ok then bought.value.id else ""
local opened = PurchaseEntitlements.openEntitlement(profile, entitlementId, function(_total: number)
	return 1
end)
check("open consumes entitlement", opened.ok and #profile.unopenedPacks == 0)
check("open uses weight table", opened.ok and opened.value[1].cardId == "placeholder.frontline")
check("duplicate open rejected", not PurchaseEntitlements.openEntitlement(profile, entitlementId, function()
	return 1
end).ok)

local fixture = {
	id = "fixture.verified",
	displayName = "Fixture Verified Pack",
	verification = "VERIFIED" :: "VERIFIED",
	slots = 2,
	earnedCost = { status = "VERIFIED" :: "VERIFIED", currency = "coins" :: "coins", amount = 10 },
	outcomes = {
		{ cardId = "placeholder.frontline", weight = 1 },
		{ cardId = "placeholder.bolt", weight = 3 },
	},
}
local fixtureRows = CardOdds.listFinalOutcomes(fixture)
check("fixture odds", fixtureRows.ok and fixtureRows.value[1].basisPoints == 2500 and fixtureRows.value[2].basisPoints == 7500)
check("pickIndex matches weights", CardOdds.pickIndex(fixture, 1) == 1 and CardOdds.pickIndex(fixture, 2) == 2 and CardOdds.pickIndex(fixture, 4) == 2)

local seenTotal = 0
local rolls = PackRoller.rollPack(fixture, function(total: number)
	seenTotal = total
	return 4
end)
check("roller total is canonical", seenTotal == 4)
check("roller and odds share the 1/3 split", rolls.ok and rolls.value[1].cardId == "placeholder.bolt" and rolls.value[2].cardId == "placeholder.bolt")

local disclosure = CardOdds.listPaidEligibleOutcomes(fixture, true)
check("verified paid disclosure ready", disclosure.status == "Ready" and disclosure.note == "PerSlotIndependent" and disclosure.slots == 2)

local fixtureProduct = {
	developerProductId = 1001,
	packId = fixture.id,
	displayName = "Fixture Verified Pack",
	verification = "VERIFIED" :: "VERIFIED",
	paidPurchaseAllowed = true,
}
local restricted = PaidGate.evaluate(fixture, { known = true, arePaidRandomItemsRestricted = true }, fixtureProduct)
check("policy restriction blocks prompt", not restricted.ok and restricted.code == "PolicyRestricted")
local unknownPolicy = PaidGate.evaluate(fixture, { known = false, arePaidRandomItemsRestricted = false }, fixtureProduct)
check("unknown policy blocks prompt", not unknownPolicy.ok and unknownPolicy.code == "PolicyUnknown")
local allowed = PaidGate.evaluate(fixture, { known = true, arePaidRandomItemsRestricted = false }, fixtureProduct)
check("verified policy allows prompt", allowed.ok)

local payer = PlayerData.createDefault()
local receipt = { purchaseId = "receipt-1", productId = 1001, playerKey = "player-1" }
local first = PurchaseEntitlements.applyReceipt(payer, receipt, { fixtureProduct }, { [fixture.id] = fixture })
check("receipt grants unopened entitlement", first.ok and first.value.decision == "PurchaseGranted" and first.value.reason == "Granted")
check("receipt does not roll", HeroCollection.count(payer, "placeholder.bolt") == 0 and #payer.unopenedPacks == 1)
local again = PurchaseEntitlements.applyReceipt(payer, receipt, { fixtureProduct }, { [fixture.id] = fixture })
check("duplicate receipt does not grant twice", again.ok and again.value.reason == "Duplicate" and #payer.unopenedPacks == 1)
local conflict = PurchaseEntitlements.applyReceipt(payer, {
	purchaseId = "receipt-1",
	productId = 1001,
	playerKey = "player-2",
}, { fixtureProduct }, { [fixture.id] = fixture })
check("receipt player mismatch conflicts", not conflict.ok and conflict.code == "ReceiptConflict")

local stranger = PlayerData.createDefault()
local pending = PurchaseEntitlements.applyReceipt(stranger, receipt, {}, nil)
check("unknown product is not granted", pending.ok and pending.value.decision == "NotProcessedYet")
check("unconfigured receipt is not stored", next(stranger.receipts) == nil and #stranger.unopenedPacks == 0)

local forged = RemoteContract.validateOpenEarnedPack({ packId = "placeholder.starter", coins = 999 })
check("forged remote field rejected", not forged.ok and forged.code == "InvalidPayload")
local gate = RemoteContract.createRateGate(1)
check("rate gate allows then blocks", gate:allow("player-1", "OpenEarnedPack", 0) and not gate:allow("player-1", "OpenEarnedPack", 0.5))
check("rate gate opens after interval", gate:allow("player-1", "OpenEarnedPack", 1))

local store = PlayerData.createMemoryStore()
store:save("user-1", payer)
local loaded = store:load("user-1")
check("memory profile roundtrip", loaded.ok and #loaded.value.unopenedPacks == 1 and loaded.value.receipts["receipt-1"] ~= nil)
local reconciled = PlayerData.reconcile({ currencies = { coins = 4 } })
check("reconcile fills missing mastery", reconciled.ok and reconciled.value.currencies.coins == 4 and reconciled.value.currencies.mastery == 0)

local run = RunCombat.begin()
local mastered = RunCombat.grantSurvivalMastery(payer, run, 5)
check("survival grants mastery", mastered.ok and payer.currencies.mastery == 5)
RunCombat.finish(run)
local after = RunCombat.grantSurvivalMastery(payer, run, 1)
check("finished run grants nothing", not after.ok and payer.currencies.mastery == 5)

local ProfileSession = require("../src/shared/server/ProfileSession")
local PackOpen = require("../src/shared/server/PackOpen")
local SeededRoll = require("../src/shared/server/SeededRoll")
local Reveal = require("../src/shared/ui/Reveal")

local oddsLines = PackUI.oddsLines(shipping)
check("odds panel marks provisional", string.find(table.concat(oddsLines, "\n"), "PROVISIONAL", 1, true) ~= nil)
check("odds panel does not use demo wildcard", string.find(table.concat(oddsLines, "\n"), "60.00", 1, true) == nil)

local foilPreview = Reveal.describe("Placeholder Frontline", "Hero", true, true)
check("foil preview is not a grant", Reveal.banner(foilPreview) == "Foil preview — not a reward")

local sessionStore = ProfileSession.createMemoryStore()
local joined = ProfileSession.load(sessionStore, "player_15", "token-a", 1000)
check("studio starter coins", joined.ok and joined.value.currencies.coins == 30)
local openGate = RemoteContract.createRateGate(PackOpen.interval())
local seeded = SeededRoll.integer(99)
local forgedOpen = PackOpen.request(joined.value, { packId = "placeholder.starter", cardId = "placeholder.bolt", weight = 999 }, "15", 0, openGate, seeded)
check("forged open fields rejected", not forgedOpen.ok and forgedOpen.code == "InvalidPayload")
check("forged open grants nothing", HeroCollection.count(joined.value, "placeholder.bolt") == 0 and HeroCollection.count(joined.value, "placeholder.frontline") == 0)
local firstOpen = PackOpen.request(joined.value, { packId = "placeholder.starter" }, "15", 0, openGate, seeded)
check("server open grants one card", firstOpen.ok and firstOpen.value.foil == false and firstOpen.value.provisional == true)
local grantedId = if firstOpen.ok then firstOpen.value.cardId else ""
local repeatSeed = SeededRoll.integer(99)
local expectedRoll = repeatSeed(2)
local expectedCard = if expectedRoll == 1 then "placeholder.frontline" else "placeholder.bolt"
check("seeded roll matches weight index", grantedId == expectedCard)
local rushedOpen = PackOpen.request(joined.value, { packId = "placeholder.starter" }, "15", 0.4, openGate, seeded)
check("second open is rate limited", not rushedOpen.ok and rushedOpen.code == "RateLimited")
check("rate limit did not add a card", HeroCollection.count(joined.value, grantedId) == 1)
local saved = ProfileSession.save(sessionStore, "player_15", "token-a", joined.value, 1001, true)
check("session save", saved.ok)
local rejoined = ProfileSession.load(sessionStore, "player_15", "token-b", 1002)
check("rejoin keeps the card and coins", rejoined.ok and HeroCollection.count(rejoined.value, grantedId) == 1 and rejoined.value.currencies.coins == 20)
local locked = ProfileSession.load(sessionStore, "player_15", "token-c", 1003)
check("fresh session lock blocks a second server", not locked.ok and locked.code == "SessionLocked")

local ProductCatalog = require("../src/shared/data/ProductCatalog")
local PaidPurchase = require("../src/shared/server/PaidPurchase")
local ReceiptCommit = require("../src/shared/server/ReceiptCommit")

check("live charges stay off", ProductCatalog.liveChargesEnabled() == false)
local legendary = PackDefinitions.get("legendary.booster")
check(
	"legendary pack matches free weights on two slots",
	legendary ~= nil
		and legendary.slots == 2
		and #legendary.outcomes == 2
		and legendary.outcomes[1].weight == shipping.outcomes[1].weight
		and legendary.outcomes[2].weight == shipping.outcomes[2].weight
)
local legendaryRows = if legendary ~= nil then CardOdds.listFinalOutcomes(legendary) else nil
check("legendary slot odds are 50/50", legendaryRows ~= nil and legendaryRows.ok and legendaryRows.value[1].basisPoints == 5000 and legendaryRows.value[2].basisPoints == 5000 and CardOdds.sumBasisPoints(legendaryRows.value) == 10000)
local legendaryRoll = if legendary ~= nil then PackRoller.rollPack(legendary, function()
	return 1
end) else nil
check("legendary roll uses the shared weight table", legendaryRoll ~= nil and legendaryRoll.ok and #legendaryRoll.value == 2 and legendaryRoll.value[1].cardId == "placeholder.frontline" and legendaryRoll.value[2].cardId == "placeholder.frontline")
local sample = SeededRoll.integer(20261117)
local heroPulls = 0
local spellPulls = 0
if legendary ~= nil then
	for _ = 1, 10000 do
		local pulled = PackRoller.rollPack(legendary, sample)
		if pulled.ok then
			for _, roll in pulled.value do
				if roll.cardId == "placeholder.frontline" then
					heroPulls += 1
				else
					spellPulls += 1
				end
			end
		end
	end
end
check("legendary sample stays near the free mix", heroPulls + spellPulls == 20000 and heroPulls > 9600 and heroPulls < 10400)
local legendaryBuyer = PlayerData.createDefault()
Economy.grantCoins(legendaryBuyer, 100)
local legendaryBuy = Economy.buyEarnedPack(legendaryBuyer, "legendary.booster")
check("legendary pack is not an earned purchase", not legendaryBuy.ok and legendaryBuyer.currencies.coins == 100 and #legendaryBuyer.unopenedPacks == 0)
local legendaryHolder = PlayerData.createDefault()
local blockedLegendary = PurchaseEntitlements.applyReceipt(legendaryHolder, {
	purchaseId = "legendary-receipt",
	productId = 3732907303,
	playerKey = "player-1",
}, products, nil)
check(
	"legendary receipt is not granted",
	blockedLegendary.ok
		and blockedLegendary.value.decision == "NotProcessedYet"
		and blockedLegendary.value.reason == "UnverifiedProduct"
		and next(legendaryHolder.receipts) == nil
		and #legendaryHolder.unopenedPacks == 0
)

local forgedPaid = PaidPurchase.request({ packId = "placeholder.starter", purchaseId = "fake" }, {
	known = true,
	arePaidRandomItemsRestricted = false,
}, true)
check("forged paid remote rejected", not forgedPaid.ok and forgedPaid.code == "InvalidPayload")
local restrictedPaid = PaidPurchase.request({ packId = "placeholder.starter" }, {
	known = true,
	arePaidRandomItemsRestricted = true,
}, true)
check("restricted paid request blocked", not restrictedPaid.ok and restrictedPaid.code == "PolicyRestricted")
local unknownPaid = PaidPurchase.request({ packId = "placeholder.starter" }, {
	known = false,
	arePaidRandomItemsRestricted = false,
}, true)
check("unknown policy blocks paid request", not unknownPaid.ok and unknownPaid.code == "PolicyUnknown")
local liveOff = PaidPurchase.request({ packId = "placeholder.starter" }, {
	known = true,
	arePaidRandomItemsRestricted = false,
}, false)
check("live charges disabled", not liveOff.ok and liveOff.code == "LiveChargesDisabled")
local earnedAnyway = PlayerData.createDefault()
Economy.grantCoins(earnedAnyway, 10)
check("restricted policy does not block earned packs", Economy.buyEarnedPack(earnedAnyway, "placeholder.starter").ok)
local beforePrompt = #earnedAnyway.unopenedPacks
local prompt = PurchaseEntitlements.onPromptFinished()
check("prompt close is not a receipt", not prompt.ok and prompt.code == "PromptIsNotReceipt" and #earnedAnyway.unopenedPacks == beforePrompt)

local pity = CardOdds.playerFinalOutcomes(shipping, { pityCharges = 1, luckMultiplier = 1, excludeOwned = false })
check("unconfigured pity blocks odds", not pity.ok and pity.code == "ModifierNotConfigured")
local shop = PackUI.shopText({ known = true, arePaidRandomItemsRestricted = false })
local paidLines = table.concat(PackUI.paidOddsLines(), "\n")
check("paid odds name the creator product", string.find(paidLines, "Legendary Booster Pack", 1, true) ~= nil and string.find(paidLines, "3732907303", 1, true) ~= nil)
check(
	"paid odds list both designed percents",
	string.find(shop, "50.00% (5000/10000) Hero - Placeholder Frontline", 1, true) ~= nil
		and string.find(shop, "50.00% (5000/10000) Spell - Placeholder Bolt", 1, true) ~= nil
		and string.find(shop, "At least one Placeholder Frontline: 75.00%", 1, true) ~= nil
		and string.find(shop, "expects 0.50 Placeholder Frontline", 1, true) ~= nil
		and string.find(shop, "expects 1.00 Placeholder Frontline", 1, true) ~= nil
		and string.find(shop, "1% wildcard is not a product", 1, true) ~= nil
)
check("paid odds state the configuration gap", string.find(shop, "Live charges: OFF", 1, true) ~= nil and string.find(shop, "MarketplaceService", 1, true) ~= nil and string.find(shop, "cannot be traded or gifted", 1, true) ~= nil)
check("free odds still match the starter roll table", listed.ok and string.find(table.concat(PackUI.oddsLines(shipping), "\n"), "50.00% ", 1, true) ~= nil)
local ProductPrice = require("../src/shared/data/ProductPrice")
local quoted = ProductPrice.fromInfo({ PriceInRobux = 10, Name = "Marketplace fixture" })
local missingPrice = ProductPrice.fromInfo({})
local fractionalPrice = ProductPrice.fromInfo({ PriceInRobux = 10.5 })
check("marketplace price is read from info", quoted.status == "Ready" and quoted.priceInRobux == 10 and string.find(ProductPrice.line(quoted), "10 from MarketplaceService", 1, true) ~= nil)
check("missing marketplace price stays blank", missingPrice.status == "Unavailable" and fractionalPrice.status == "Unavailable" and string.find(ProductPrice.line(missingPrice), "unavailable", 1, true) ~= nil)
local unpaidLegendary = PaidPurchase.request({ packId = "legendary.booster" }, {
	known = true,
	arePaidRandomItemsRestricted = false,
}, true)
check("legendary prompt stays unverified", not unpaidLegendary.ok and unpaidLegendary.code == "UnverifiedPaidBlocked")
local receiptPackId = if first.ok then first.value.entitlementId else ""
local openGatePaid = RemoteContract.createRateGate(0)
local restrictedOpen = PackOpen.openOwned(payer, { entitlementId = receiptPackId }, "player-1", 0, openGatePaid, function()
	return 1
end, { known = true, arePaidRandomItemsRestricted = true })
check("restricted policy blocks paid opening", not restrictedOpen.ok and restrictedOpen.code == "PolicyRestricted" and #payer.unopenedPacks == 1 and HeroCollection.count(payer, "placeholder.bolt") == 0)
local unknownOpen = PackOpen.openOwned(payer, { entitlementId = receiptPackId }, "player-1", 1, openGatePaid, function()
	return 1
end, { known = false, arePaidRandomItemsRestricted = false })
check("unknown policy blocks paid opening", not unknownOpen.ok and unknownOpen.code == "PolicyUnknown" and #payer.unopenedPacks == 1)

local commitStore = ProfileSession.createMemoryStore()
local owner = ProfileSession.load(commitStore, "player_9", "server-a", 2000)
check("receipt session claimed", owner.ok)
local raceReceipt = { purchaseId = "race-1", productId = 1001, playerKey = "player_9" }
local racePacks = { [fixture.id] = fixture }
local raceProducts = { fixtureProduct }
local grantedRace = ReceiptCommit.process(commitStore, "player_9", "server-a", raceReceipt, raceProducts, racePacks, 2001, true)
check("owning server grants one unopened pack", grantedRace.ok and grantedRace.value.decision == "PurchaseGranted" and grantedRace.value.reason == "Granted" and grantedRace.value.profile ~= nil and #grantedRace.value.profile.unopenedPacks == 1)
local otherServer = ReceiptCommit.process(commitStore, "player_9", "server-b", raceReceipt, raceProducts, racePacks, 2002, true)
check("other server waits during the lock", otherServer.ok and otherServer.value.decision == "NotProcessedYet" and otherServer.value.reason == "SessionLocked")
local duplicateRace = ReceiptCommit.process(commitStore, "player_9", "server-a", raceReceipt, raceProducts, racePacks, 2003, true)
check("duplicate receipt stays one pack", duplicateRace.ok and duplicateRace.value.reason == "Duplicate" and duplicateRace.value.profile ~= nil and #duplicateRace.value.profile.unopenedPacks == 1)
local absent = ReceiptCommit.process(commitStore, "player_9", "server-a", {
	purchaseId = "race-2",
	productId = 1001,
	playerKey = "player_9",
}, raceProducts, racePacks, 2004, false)
local absentBlob = commitStore:GetAsync("player_9")
check("absent player is not processed", absent.ok and absent.value.reason == "PlayerAbsent" and absentBlob ~= nil and absentBlob.profile.receipts["race-2"] == nil)

local downStore = {} :: ProfileSession.Store
function downStore:UpdateAsync(_key: string, _transform: (ProfileSession.Blob?) -> ProfileSession.Blob?): ProfileSession.Blob?
	error("network")
end
function downStore:GetAsync(_key: string): ProfileSession.Blob?
	return nil
end
local failedNet = ReceiptCommit.process(downStore, "player_9", "server-a", {
	purchaseId = "race-3",
	productId = 1001,
	playerKey = "player_9",
}, raceProducts, racePacks, 2005, true)
check("network failure is not acknowledged", failedNet.ok and failedNet.value.decision == "NotProcessedYet" and failedNet.value.reason == "StoreFailed")

local crashRows: { [string]: ProfileSession.Blob } = {
	player_3 = { sessionToken = "server-a", sessionAt = 3000, profile = PlayerData.createDefault() },
}
local crashStore = {} :: ProfileSession.Store
function crashStore:UpdateAsync(key: string, transform: (ProfileSession.Blob?) -> ProfileSession.Blob?): ProfileSession.Blob?
	local nextBlob = transform(crashRows[key])
	if nextBlob ~= nil then
		crashRows[key] = nextBlob
	end
	error("shutdown before ack")
end
function crashStore:GetAsync(key: string): ProfileSession.Blob?
	return crashRows[key]
end
local crashed = ReceiptCommit.process(crashStore, "player_3", "server-a", {
	purchaseId = "race-4",
	productId = 1001,
	playerKey = "player_3",
}, raceProducts, racePacks, 3001, true)
check("shutdown does not acknowledge", crashed.ok and crashed.value.decision == "NotProcessedYet" and crashRows.player_3.profile.receipts["race-4"] ~= nil)
local retryStore = ProfileSession.createMemoryStore()
retryStore:UpdateAsync("player_3", function()
	return crashRows.player_3
end)
local retried = ReceiptCommit.process(retryStore, "player_3", "server-a", {
	purchaseId = "race-4",
	productId = 1001,
	playerKey = "player_3",
}, raceProducts, racePacks, 3002, true)
check("lost ack retries as a duplicate", retried.ok and retried.value.reason == "Duplicate" and retried.value.profile ~= nil and #retried.value.profile.unopenedPacks == 1)

local released = ProfileSession.save(commitStore, "player_9", "server-a", grantedRace.value.profile :: any, 2100, true)
local rejoinedPack = ProfileSession.load(commitStore, "player_9", "server-c", 2200)
check("rejoin keeps the unopened receipt pack", released.ok and rejoinedPack.ok and #rejoinedPack.value.unopenedPacks == 1)
local consumed = PurchaseEntitlements.openEntitlement(rejoinedPack.value, rejoinedPack.value.unopenedPacks[1].id, function()
	return 1
end, racePacks)
local savedOpened = ProfileSession.save(commitStore, "player_9", "server-c", rejoinedPack.value, 2300, true)
local afterOpen = ProfileSession.load(commitStore, "player_9", "server-d", 2400)
local third = ReceiptCommit.process(commitStore, "player_9", "server-d", raceReceipt, raceProducts, racePacks, 2401, true)
check(
	"opened receipt pack survives rejoin once",
	consumed.ok and savedOpened.ok and afterOpen.ok and #afterOpen.value.unopenedPacks == 0 and third.ok and third.value.reason == "Duplicate" and #third.value.profile.unopenedPacks == 0
)

local travelSpeed = 100
local travelTicks = CombatSim.travelTicks(travelSpeed)
local travelElapsed = travelTicks * CombatTables.tick
local travelExpected = CombatTables.pathLength() / travelSpeed
check("fast enemy keeps path time within one tick", math.abs(travelElapsed - travelExpected) < CombatTables.tick)

local rearEnemy = { progress = 20, hp = 10, speed = 10, leakDamage = 1, alive = true, leaked = false }
local leadEnemy = { progress = 45, hp = 10, speed = 10, leakDamage = 1, alive = true, leaked = false }
local picked = CombatSim.pickFirst({ rearEnemy, leadEnemy }, { x = 25, y = 10 }, 24)
check("first target is furthest on the path", picked == leadEnemy)

local fighter = PlayerData.createDefault()
HeroCollection.grant(fighter, "placeholder.frontline", 1)
local unplaced = RunCombat.fight(fighter, "placeholder.wave.1", 20261117)
check(
	"unplaced wave earns nothing",
	unplaced.ok and not unplaced.value.survived and fighter.currencies.mastery == 0 and fighter.currencies.coins == 0 and fighter.realmId == "placeholder.tower" and #fighter.unopenedPacks == 0
)
HeroCollection.grant(fighter, "placeholder.bolt", 1)
local placed = Progression.place(fighter, "placeholder.frontline", "lane.mid")
local first = RunCombat.fight(fighter, "placeholder.wave.1", 20261117)
local replay = CombatSim.simulate(fighter, "placeholder.wave.1", 7)
check("placement accepted", placed.ok)
local replayedFight = RunCombat.fight(fighter, "placeholder.wave.1", 20261117)
check(
	"cleared wave does not pay twice",
	replayedFight.ok and replayedFight.value.survived and replayedFight.value.coins == 0 and fighter.currencies.mastery == 5 and fighter.currencies.coins == 10
)
check(
	"placed hero survives wave 1",
	first.ok and first.value.survived and first.value.mastery == 5 and first.value.coins == 10 and fighter.currencies.mastery == 5 and fighter.currencies.coins == 10,
	if first.ok then "killed " .. tostring(first.value.killed) .. " leaked " .. tostring(first.value.leaked) .. " dmg " .. tostring(first.value.damageDealt) else "err"
)
check(
	"same wave ignores the seed",
	replay.ok and first.ok and replay.value.ticks == first.value.ticks and replay.value.damageDealt == first.value.damageDealt
)
check("survival unlocks the gate realm and pack", fighter.realmId == "placeholder.gate" and fighter.unlockedPacks["placeholder.gate"] == true)
local broke = Progression.upgrade(PlayerData.createDefault(), "placeholder.frontline")
check("upgrade rejects an unowned card", not broke.ok and broke.ok == false and broke.code == "NotOwned")
local poorMastery = PlayerData.createDefault()
HeroCollection.grant(poorMastery, "placeholder.frontline", 1)
local brokeMastery = Progression.upgrade(poorMastery, "placeholder.frontline")
check("upgrade spends nothing without mastery", not brokeMastery.ok and brokeMastery.ok == false and brokeMastery.code == "InsufficientMastery" and poorMastery.currencies.mastery == 0)
local earlyGate = Economy.buyEarnedPack(PlayerData.createDefault(), "placeholder.gate")
check("gate pack stays locked before a clear", not earlyGate.ok and earlyGate.ok == false and earlyGate.code == "UnknownPack")
local boughtGate = Economy.buyEarnedPack(fighter, "placeholder.gate")
check("unlocked gate pack uses the earned path", boughtGate.ok and fighter.currencies.coins == 0 and fighter.currencies.mastery == 5 and #fighter.unopenedPacks == 1 and fighter.unopenedPacks[1].packId == "placeholder.gate" and fighter.unopenedPacks[1].state == "Unopened")
local gateRows = CardOdds.listFinalOutcomes(PackDefinitions.gatePack())
check("gate pack shares the starter weights", gateRows.ok and gateRows.value[1].weight == 1 and gateRows.value[2].weight == 1 and gateRows.value[1].basisPoints == 5000)
local ranked = Progression.upgrade(fighter, "placeholder.frontline")
check("mastery raises hero damage", ranked.ok and ranked.value == 1 and fighter.currencies.mastery == 0 and CombatTables.damage("placeholder.frontline", 1) == 14)
local lockedWave = RunCombat.fight(PlayerData.createDefault(), "placeholder.wave.2", 1)
check("wave 2 stays locked", not lockedWave.ok and lockedWave.ok == false and lockedWave.code == "WaveLocked")
local weak = PlayerData.createDefault()
HeroCollection.grant(weak, "placeholder.frontline", 1)
HeroCollection.grant(weak, "placeholder.bolt", 1)
Progression.place(weak, "placeholder.frontline", "lane.mid")
Progression.recordClear(weak, "placeholder.wave.1")
local weakFight = RunCombat.fight(weak, "placeholder.wave.2", 20261117)
check(
	"rank 0 falls to wave 2",
	weakFight.ok and not weakFight.value.survived and weak.currencies.mastery == 0,
	if weakFight.ok then "killed " .. tostring(weakFight.value.killed) .. " leaked " .. tostring(weakFight.value.leaked) .. " dmg " .. tostring(weakFight.value.damageDealt) else "err"
)
weak.currencies.mastery = 5
Progression.upgrade(weak, "placeholder.frontline")
local strongFight = RunCombat.fight(weak, "placeholder.wave.2", 20261117)
check(
	"ranked hero survives wave 2",
	strongFight.ok and strongFight.value.survived and weak.currencies.mastery == 5 and weak.currencies.coins == 10,
	if strongFight.ok then "killed " .. tostring(strongFight.value.killed) .. " leaked " .. tostring(strongFight.value.leaked) .. " dmg " .. tostring(strongFight.value.damageDealt) else "err"
)
local spellOnly = PlayerData.createDefault()
HeroCollection.grant(spellOnly, "placeholder.bolt", 1)
local spellBase = CombatSim.simulate(spellOnly, "placeholder.wave.1", 3)
spellOnly.ranks["placeholder.bolt"] = 1
local spellRanked = CombatSim.simulate(spellOnly, "placeholder.wave.1", 3)
check(
	"spell rank raises damage and does not grant",
	spellBase.ok and spellRanked.ok and spellRanked.value.damageDealt > spellBase.value.damageDealt and spellOnly.currencies.mastery == 0 and #spellOnly.unopenedPacks == 0
)
local forgedPlace = RemoteContract.validatePlaceHero({ cardId = "placeholder.frontline", anchorId = "lane.mid", damage = 99 })
local forgedWave = RemoteContract.validateStartWave({ waveId = "placeholder.wave.1", coins = 10 })
check("forged combat fields are rejected", not forgedPlace.ok and not forgedWave.ok)
local combatText = CombatUI.describe(fighter, if first.ok then first.value else nil)
check("combat copy stays labelled", string.find(combatText, "UNVERIFIED_PLACEHOLDER", 1, true) ~= nil and string.find(combatText, "50.00% (5000/10000)", 1, true) ~= nil)
local roundTrip = PlayerData.reconcile(fighter :: any)
check(
	"reconcile keeps placement rank and unlock",
	roundTrip.ok and roundTrip.value.placement[1].cardId == "placeholder.frontline" and roundTrip.value.ranks["placeholder.frontline"] == 1 and roundTrip.value.unlockedPacks["placeholder.gate"] == true and #roundTrip.value.unopenedPacks == 1
)
local freshCombat = PlayerData.reconcile({ currencies = { coins = 4 } })
check("old saves gain empty combat fields", freshCombat.ok and freshCombat.value.realmId == "placeholder.tower" and #freshCombat.value.placement == 0 and freshCombat.value.currencies.coins == 4)

local ProductCatalog = require("../src/shared/data/ProductCatalog")
local fullReveal = Presentation.revealSteps("full", false)
local fastReveal = Presentation.revealSteps("fast", false)
local reducedReveal = Presentation.revealSteps("reduced", true)
local foilReveal = Presentation.revealSteps("full", true)
check("reveal rests at scale 1", fullReveal[#fullReveal].scale == 1 and reducedReveal[1].scale == 1 and foilReveal[#foilReveal].scale == 1)
check(
	"motion shortens the rip",
	Presentation.totalSeconds(fullReveal) > Presentation.totalSeconds(fastReveal) and Presentation.totalSeconds(fastReveal) > Presentation.totalSeconds(reducedReveal)
)
check("foil adds a shimmer and does not change weights", foilReveal[#foilReveal].id == "shimmer" and shipping.outcomes[1].weight == 1 and shipping.outcomes[2].weight == 1)
check("reduced reveal skips squash", reducedReveal[1].id == "show" and reducedReveal[1].seconds == 0)
check("motion cycle is full, fast, reduced", Presentation.cycle("full") == "fast" and Presentation.cycle("fast") == "reduced" and Presentation.cycle("reduced") == "full")
check("unknown motion falls back to full", Presentation.parse("nope") == "full" and Presentation.motionLabel("reduced") == "Motion: Reduced")
local revealCue = Presentation.cue("reveal", "full")
local quietCue = Presentation.cue("reveal", "reduced")
check("cues have no audio asset", revealCue.audible == false and quietCue.audible == false and revealCue.haptic > 0 and quietCue.haptic == 0)
local survivedHit = Presentation.impact("full", true)
local defeatHit = Presentation.impact("full", false)
local reducedHit = Presentation.impact("reduced", false)
check("impact stays inside the mobile budget", survivedHit.particles == 10 and defeatHit.particles == 12 and defeatHit.flash == true and defeatHit.hold == 0.1)
check("reduced motion drops shake, particles, and flash", reducedHit.trauma == 0 and reducedHit.particles == 0 and reducedHit.flash == false and reducedHit.hold == 0)
local trauma = Presentation.decayTrauma(0.8, 0, 1.2)
trauma = math.min(trauma + 0.4, 1)
for _ = 1, 90 do
	trauma = Presentation.decayTrauma(trauma, 1 / 30, 1.2)
end
check("trauma decays to rest", trauma == 0)
check("a calm camera stays put", Presentation.shakeOffset(0, 2, 1).x == 0 and Presentation.shakeOffset(0, 2, 1).y == 0)
check("phone targets stay tappable", Presentation.buttonHeight(390) >= 44 and Presentation.bodyText(390) >= 18 and Presentation.buttonHeight(1080) <= 56)
check("card faces stay original motifs", Presentation.face("Hero") == "shield" and Presentation.face("Spell") == "chevron")
check("card detail says foil is not rolled", string.find(Presentation.cardDetail("Placeholder Frontline", "Hero", 2, 1), "does not roll foil", 1, true) ~= nil)
local idleMeters = CombatUI.meters(nil)
check("idle tower bar is full and labelled", idleMeters[1].label == "Tower 15/15" and idleMeters[1].fill == 1 and idleMeters[2].label == "No wave yet")
local clearMeters = CombatUI.meters({ seed = 1, ticks = 108, damageDealt = 63, survived = true, towerHp = 15 })
check("clear bar names the ticks", clearMeters[2].fill == 1 and string.find(clearMeters[2].label, "Cleared in 108 ticks", 1, true) ~= nil)
local fellMeters = CombatUI.meters({ seed = 1, ticks = 10, damageDealt = 4, survived = false, towerHp = 0 })
check("loss bar names the fall and pays nothing", fellMeters[1].fill == 0 and string.find(fellMeters[2].label, "No Mastery and no coins", 1, true) ~= nil)
local brokenMeters = CombatUI.meters({ seed = 1, ticks = 0 / 0, damageDealt = 0 / 0, survived = false, towerHp = 0 / 0 })
check("broken meter numbers stay finite", brokenMeters[1].fill == brokenMeters[1].fill and brokenMeters[1].fill >= 0 and brokenMeters[1].fill <= 1)
check("polish leaves live charges off", ProductCatalog.liveChargesEnabled() == false)
check("polish leaves the odds button", PackUI.quote(shipping, 10, { known = true, arePaidRandomItemsRestricted = true }, nil).oddsButtonLabel == "Odds / Details")

local function oddsTextMatches(pack, text: string): boolean
	local rows = CardOdds.listFinalOutcomes(pack)
	if not rows.ok or CardOdds.sumBasisPoints(rows.value) ~= 10000 then
		return false
	end
	for _, row in rows.value do
		local percent = string.format("%.2f", row.basisPoints / 100)
		if string.find(text, percent .. "%", 1, true) == nil then
			return false
		end
	end
	return true
end
local legendaryPack = PackDefinitions.paidPack()
check(
	"displayed odds are the roll table",
	oddsTextMatches(shipping, table.concat(PackUI.oddsLines(shipping), "\n"))
		and oddsTextMatches(PackDefinitions.gatePack(), table.concat(PackUI.oddsLines(PackDefinitions.gatePack()), "\n"))
		and oddsTextMatches(legendaryPack, table.concat(PackUI.paidOddsLines(), "\n"))
)
local seenRoll = { [1] = "", [2] = "" }
for roll = 1, CardOdds.totalWeight(shipping) do
	seenRoll[roll] = shipping.outcomes[CardOdds.pickIndex(shipping, roll)].cardId
end
check("starter weights enumerate to one half each", seenRoll[1] == "placeholder.frontline" and seenRoll[2] == "placeholder.bolt")
local sim = SeededRoll.integer(20261117)
local simTrials = 20000
local slotHits = { ["placeholder.frontline"] = 0, ["placeholder.bolt"] = 0 }
local packsWithFrontline = 0
for _ = 1, simTrials do
	local rolled = PackRoller.rollPack(legendaryPack, sim)
	local sawFrontline = false
	if rolled.ok then
		for _, roll in rolled.value do
			slotHits[roll.cardId] += 1
			if roll.cardId == "placeholder.frontline" then
				sawFrontline = true
			end
		end
	end
	if sawFrontline then
		packsWithFrontline += 1
	end
end
check(
	"long seed stays near the declared 50/50 and 75% at-least-one",
	math.abs(slotHits["placeholder.frontline"] - simTrials) < 800
		and math.abs(slotHits["placeholder.bolt"] - simTrials) < 800
		and math.abs(packsWithFrontline - (simTrials * 3) // 4) < 700
)

local fallbackStore = ProfileSession.createMemoryStore()
local failingPrimary = {} :: ProfileSession.Store
function failingPrimary:UpdateAsync(_key: string, _transform: (ProfileSession.Blob?) -> ProfileSession.Blob?): ProfileSession.Blob?
	error("down")
end
function failingPrimary:GetAsync(_key: string): ProfileSession.Blob?
	return nil
end
local primaryFailed = ProfileSession.callStore(failingPrimary, fallbackStore, "player_x", function()
	return { sessionToken = "t", sessionAt = 1, profile = PlayerData.createDefault() }
end)
check("failed primary does not write the fallback", primaryFailed == false and fallbackStore:GetAsync("player_x") == nil)
local memoryWrite = ProfileSession.callStore(nil, fallbackStore, "player_x", function()
	return { sessionToken = "t", sessionAt = 1, profile = PlayerData.createDefault() }
end)
check("unconfigured store still uses memory", memoryWrite == true and fallbackStore:GetAsync("player_x") ~= nil)

local staleStore = ProfileSession.createMemoryStore()
local staleClaim = ProfileSession.load(staleStore, "player_stale", "tok", 5000)
local staleMemory = PlayerData.clone(staleClaim.value :: any)
staleMemory.currencies.coins = 4
local staleGrant = ReceiptCommit.process(staleStore, "player_stale", "tok", {
	purchaseId = "stale-1",
	productId = 1001,
	playerKey = "player_stale",
}, raceProducts, racePacks, 5001, true)
local staleSave = ProfileSession.save(staleStore, "player_stale", "tok", staleMemory, 5002, false)
local staleBlob = staleStore:GetAsync("player_stale")
check(
	"stale save keeps the receipt pack and the newer coins",
	staleClaim.ok and staleGrant.ok and staleSave.ok and staleBlob ~= nil and staleBlob.profile.currencies.coins == 4 and staleBlob.profile.receipts["stale-1"] ~= nil and #staleBlob.profile.unopenedPacks == 1
)
local consumedStale = PlayerData.clone(staleBlob.profile)
consumedStale.unopenedPacks = {}
local consumedSave = ProfileSession.save(staleStore, "player_stale", "tok", consumedStale, 5003, false)
local consumedBlob = staleStore:GetAsync("player_stale")
check(
	"opening removes the pack without deleting the receipt",
	consumedSave.ok and consumedBlob ~= nil and consumedBlob.profile.receipts["stale-1"] ~= nil and #consumedBlob.profile.unopenedPacks == 0
)

print(string.format("tests: %d passed, %d failed", passed, failed))
if failed > 0 then
	process.exit(1)
end
