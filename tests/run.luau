--!strict

local CardOdds = require("../src/shared/data/CardOdds")
local PackDefinitions = require("../src/shared/data/PackDefinitions")
local ProductCatalog = require("../src/shared/data/ProductCatalog")
local PackUI = require("../src/shared/ui/PackUI")
local Board = require("../src/shared/ui/Board")
local Presentation = require("../src/shared/ui/Presentation")
local PlayerData = require("../src/shared/server/PlayerData")
local HeroCollection = require("../src/shared/server/HeroCollection")
local Economy = require("../src/shared/server/Economy")
local PackOpen = require("../src/shared/server/PackOpen")
local PackRoller = require("../src/shared/server/PackRoller")
local SeededRoll = require("../src/shared/server/SeededRoll")
local RemoteContract = require("../src/shared/net/RemoteContract")
local PaidPurchase = require("../src/shared/server/PaidPurchase")
local PurchaseEntitlements = require("../src/shared/server/PurchaseEntitlements")
local ProfileSession = require("../src/shared/server/ProfileSession")
local ReceiptCommit = require("../src/shared/server/ReceiptCommit")
local Progression = require("../src/shared/server/Progression")
local RunCombat = require("../src/shared/server/RunCombat")
local CombatSim = require("../src/shared/server/CombatSim")

local passed = 0
local failed = 0

local function check(name: string, condition: boolean)
	if condition then
		passed += 1
		print("PASS " .. name)
	else
		failed += 1
		print("FAIL " .. name)
	end
end

local night = PackDefinitions.get("packvania.night")
assert(night ~= nil)
local rows = CardOdds.listFinalOutcomes(night)
check("night pack lists four final outcomes", rows.ok and #rows.value == 4 and CardOdds.sumBasisPoints(rows.value) == 10000)
check("shipping stays unverified", PackDefinitions.validateShipping().ok)
check("demo odds are absent", string.find(table.concat(PackUI.oddsLines(night), "\n"), "60.00", 1, true) == nil)
check("odds button is Odds / Details", PackUI.quote(night, 30, { known = true, arePaidRandomItemsRestricted = false }, nil).oddsButtonLabel == "Odds / Details")
check("live charges stay off", ProductCatalog.liveChargesEnabled() == false)
check("pity is not configured", not CardOdds.playerFinalOutcomes(night, { pityCharges = 1, luckMultiplier = 1, excludeOwned = false }).ok)

local seen = {}
for roll = 1, CardOdds.totalWeight(night) do
	local cardId = night.outcomes[CardOdds.pickIndex(night, roll)].cardId
	seen[cardId] = (seen[cardId] or 0) + 1
end
check("enumerated weights match the table", seen["packvania.warden"] == 2 and seen["packvania.bolt"] == 2 and seen["packvania.keeper"] == 1)

local sim = SeededRoll.integer(20261117)
local hits = { ["packvania.warden"] = 0, ["packvania.bolt"] = 0, ["packvania.keeper"] = 0, ["packvania.gargoyle"] = 0 }
local trials = 12000
local moon = PackDefinitions.paidPack()
for _ = 1, trials do
	local rolled = PackRoller.rollPack(moon, sim)
	if rolled.ok then
		for _, roll in rolled.value do
			hits[roll.cardId] += 1
		end
	end
end
check(
	"long seed stays near the designed weights",
	math.abs(hits["packvania.warden"] - trials * 2 / 3) < 500 and math.abs(hits["packvania.keeper"] - trials / 3) < 400
)
local paidText = table.concat(PackUI.paidOddsLines(), "\n")
check("paid disclosure names both slots and stays off", string.find(paidText, "independently", 1, true) ~= nil and string.find(paidText, "Live charges: OFF", 1, true) ~= nil and string.find(paidText, "3732907303", 1, true) ~= nil)

local profile = PlayerData.createDefault()
Economy.applyStarterGrant(profile)
check("starter coins", profile.currencies.coins == 30)
local gate = RemoteContract.createRateGate(0)
local opened = PackOpen.request(profile, { packId = "packvania.night" }, "p", 0, gate, function()
	return 1
end)
check("earned open grants one card and spends 10", opened.ok and profile.currencies.coins == 20 and HeroCollection.count(profile, "packvania.warden") == 1 and profile.packsOpened == 1)
check("forged open is rejected", not RemoteContract.validateOpenEarnedPack({ packId = "packvania.night", coins = 99 }).ok)
check("moonlit pack is not an earned buy", not Economy.buyEarnedPack(profile, "packvania.moonlit").ok)
check("paid request stays disabled", not PaidPurchase.request({ packId = "packvania.moonlit" }, { known = true, arePaidRandomItemsRestricted = false }, false).ok)
check("restricted paid request is blocked", PaidPurchase.request({ packId = "packvania.moonlit" }, { known = true, arePaidRandomItemsRestricted = true }, true).code == "PolicyRestricted")
check("prompt close is not a receipt", PurchaseEntitlements.onPromptFinished().code == "PromptIsNotReceipt")

local fixture = {
	id = "fixture.pack",
	displayName = "Fixture",
	verification = "VERIFIED" :: "VERIFIED",
	slots = 2,
	earnedCost = { status = "VERIFIED" :: "VERIFIED", currency = "coins" :: "coins", amount = 10 },
	outcomes = {
		{ cardId = "packvania.warden", weight = 1 },
		{ cardId = "packvania.bolt", weight = 3 },
	},
}
local fixtureRows = CardOdds.listFinalOutcomes(fixture)
check("fixture basis points", fixtureRows.ok and fixtureRows.value[1].basisPoints == 2500 and fixtureRows.value[2].basisPoints == 7500)
local fixtureProduct = {
	developerProductId = 1001,
	packId = fixture.id,
	displayName = "Fixture",
	verification = "VERIFIED" :: "VERIFIED",
	paidPurchaseAllowed = true,
}
local payer = PlayerData.createDefault()
local receipt = { purchaseId = "r1", productId = 1001, playerKey = "player_1" }
local granted = PurchaseEntitlements.applyReceipt(payer, receipt, { fixtureProduct }, { [fixture.id] = fixture })
local again = PurchaseEntitlements.applyReceipt(payer, receipt, { fixtureProduct }, { [fixture.id] = fixture })
check("receipt grants one unopened pack and does not roll", granted.ok and granted.value.reason == "Granted" and again.value.reason == "Duplicate" and #payer.unopenedPacks == 1 and HeroCollection.count(payer, "packvania.bolt") == 0)
local blockedOpen = PackOpen.openOwned(payer, { entitlementId = payer.unopenedPacks[1].id }, "player_1", 1, RemoteContract.createRateGate(0), function()
	return 1
end, { known = true, arePaidRandomItemsRestricted = true })
check("restricted player cannot open a paid pack", not blockedOpen.ok and blockedOpen.code == "PolicyRestricted" and #payer.unopenedPacks == 1)

local store = ProfileSession.createMemoryStore()
local loaded = ProfileSession.load(store, "player_1", "server-a", 10)
check("session load grants starter coins once", loaded.ok and loaded.value.currencies.coins == 30)
local committed = ReceiptCommit.process(store, "player_1", "server-a", { purchaseId = "live-1", productId = 1001, playerKey = "player_1" }, { fixtureProduct }, { [fixture.id] = fixture }, 11, true)
check("commit stores one entitlement", committed.ok and committed.value.reason == "Granted" and committed.value.profile ~= nil and #committed.value.profile.unopenedPacks == 1)
local other = ReceiptCommit.process(store, "player_1", "server-b", { purchaseId = "live-2", productId = 1001, playerKey = "player_1" }, { fixtureProduct }, { [fixture.id] = fixture }, 12, true)
check("other server waits", other.ok and other.value.reason == "SessionLocked")
local absent = ReceiptCommit.process(store, "player_1", "server-a", { purchaseId = "live-3", productId = 1001, playerKey = "player_1" }, { fixtureProduct }, { [fixture.id] = fixture }, 13, false)
check("absent player is not processed", absent.ok and absent.value.reason == "PlayerAbsent")
local down = {} :: ProfileSession.Store
function down:UpdateAsync()
	error("down")
end
function down:GetAsync()
	return nil
end
local failedNet = ReceiptCommit.process(down, "player_1", "server-a", { purchaseId = "live-4", productId = 1001, playerKey = "player_1" }, { fixtureProduct }, { [fixture.id] = fixture }, 14, true)
check("store failure is not acknowledged", failedNet.ok and failedNet.value.decision == "NotProcessedYet")
local memory = ProfileSession.createMemoryStore()
local untouched = ProfileSession.callStore(down, memory, "k", function()
	return nil
end)
check("failed primary does not write memory", untouched == false and memory:GetAsync("k") == nil)

local before = PlayerData.clone(committed.value.profile :: any)
before.currencies.coins = 4
before.receipts = {}
before.unopenedPacks = {}
local saved = ProfileSession.save(store, "player_1", "server-a", before, 20, false)
local blob = store:GetAsync("player_1")
check("stale save keeps the receipt pack", saved.ok and blob ~= nil and blob.profile.currencies.coins == 4 and blob.profile.receipts["live-1"] ~= nil and #blob.profile.unopenedPacks == 1)

local old = PlayerData.reconcile({ currencies = { coins = 4 } })
check("old saves gain the new fields", old.ok and old.value.currencies.coins == 4 and old.value.packsOpened == 0 and #old.value.equippedRelics == 0)

local fighter = PlayerData.createDefault()
HeroCollection.grant(fighter, "packvania.warden", 1)
local unplaced = RunCombat.fight(fighter, "packvania.wave.courtyard", 7)
check("an empty lane falls and pays nothing", unplaced.ok and not unplaced.value.survived and fighter.currencies.coins == 0 and fighter.currencies.mastery == 0)
Progression.place(fighter, "packvania.warden", "lane.mid")
local first = RunCombat.fight(fighter, "packvania.wave.courtyard", 7)
local replay = RunCombat.fight(fighter, "packvania.wave.courtyard", 99)
check("one warden clears the courtyard", first.ok and first.value.survived and fighter.currencies.mastery == 5 and fighter.currencies.coins == 10)
check("a cleared wave does not pay twice", replay.ok and replay.value.survived and replay.value.coins == 0 and fighter.currencies.mastery == 5 and fighter.currencies.coins == 10)
check("clear unlocks the chapel pack and a relic", fighter.unlockedPacks["packvania.chapel"] == true and fighter.relics["packvania.cloak"] == true)
check("relics do not change pack odds", CardOdds.listFinalOutcomes(night).value[1].basisPoints == rows.value[1].basisPoints)
local locked = RunCombat.fight(PlayerData.createDefault(), "packvania.wave.chapel", 1)
check("chapel stays locked", not locked.ok and locked.code == "WaveLocked")
local chapelEarly = CombatSim.simulate(fighter, "packvania.wave.chapel", 1)
check("one warden falls at the chapel", chapelEarly.ok and not chapelEarly.value.survived)
HeroCollection.grant(fighter, "packvania.bolt", 1)
Progression.place(fighter, "packvania.bolt", "lane.back")
Progression.upgrade(fighter, "packvania.warden")
local chapel = RunCombat.fight(fighter, "packvania.wave.chapel", 3)
check("a ranked pair clears the chapel", chapel.ok and chapel.value.survived and fighter.currencies.mastery == 8)
local shot = Board.snapshot(fighter, { known = true, arePaidRandomItemsRestricted = false })
local result = Board.resultLines(fighter, chapel.value)
check("the board is Packvania", shot.title == "Packvania" and shot.oddsButtonLabel == "Odds / Details" and shot.paidEnabled == false)
check("the result panel names the wave", result[1] == "CLEARED" and string.find(table.concat(result, "\n"), "Packs opened", 1, true) ~= nil)
check("quests track recruits and clears", shot.quests[3].done == true)
check("bestiary remembers the chapel", shot.bestiary[1].known or shot.bestiary[2].known or shot.bestiary[3].known)
check("motion has a reduced step", Presentation.revealSeconds("reduced") == 0 and Presentation.buttonHeight(390) >= 44)
check("forged wave is rejected", not RemoteContract.validateStartWave({ waveId = "packvania.wave.courtyard", damage = 99 }).ok)

print(string.format("tests: %d passed, %d failed", passed, failed))
if failed > 0 then
	process.exit(1)
end
