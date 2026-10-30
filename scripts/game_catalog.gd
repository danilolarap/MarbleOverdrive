class_name GameCatalog
extends RefCounted
## One source of truth for loadout rules and scenario/appearance selection.
const BUDGET := 6
const DEFAULT_LOADOUT := ["BOOST", "MAGNET", "OIL"]
const ITEMS := {
	"BOOST": {"category": "EQUIPMENT", "cost": 3, "color": Color("64efba")},
	"REPAIR": {"category": "EQUIPMENT", "cost": 2, "color": Color("75e4dd")},
	"SHIELD": {"category": "EQUIPMENT", "cost": 3, "color": Color("79baff")},
	"GRIP": {"category": "EQUIPMENT", "cost": 1, "color": Color("d3ed76")},
	"MAGNET": {"category": "TRAPS", "cost": 2, "color": Color("d4a5ff")},
	"BARRIER": {"category": "TRAPS", "cost": 3, "color": Color("ff829c")},
	"OIL": {"category": "TRAPS", "cost": 1, "color": Color("c2a2e9")},
	"SHOCK": {"category": "TRAPS", "cost": 2, "color": Color("ffc86d")}
}
const SCENARIOS := ["CITY", "PLAYGROUND", "ZOO", "SPACEPORT", "VOLCANO", "ICE", "OCEAN", "JUNGLE", "DESERT", "CANDY", "FACTORY", "SKY_GARDENS"]
const WORLD_COLORS := {
	"CITY": [Color("0a152c"), Color("42d9ef")], "PLAYGROUND": [Color("241533"), Color("ff8bc9")],
	"ZOO": [Color("142a26"), Color("9ee686")], "SPACEPORT": [Color("0d1029"), Color("a399ff")],
	"VOLCANO": [Color("321b23"), Color("ff8053")], "ICE": [Color("142c40"), Color("99dfff")],
	"OCEAN": [Color("0a2c3b"), Color("47dfd3")], "JUNGLE": [Color("102e27"), Color("6fe590")],
	"DESERT": [Color("342a30"), Color("edc78b")], "CANDY": [Color("301d3a"), Color("ef9cda")],
	"FACTORY": [Color("252d38"), Color("efad65")], "SKY_GARDENS": [Color("263249"), Color("a9d8ef")]
}
const PATTERNS := ["SOLID", "STRIPES", "DUAL", "RINGS", "CHECKER", "LIGHTNING"]
const PALETTE := [Color("34e4ef"), Color("ffb14a"), Color("c196ff"), Color("63edab"), Color("ff7795"), Color("6f9dff"), Color("f9ed89"), Color("f1f6ff"), Color("ef69df"), Color("eb775c"), Color("35c6a6"), Color("65748e")]

static func is_trap(id: String) -> bool:
	return ITEMS.has(id) and ITEMS[id].category == "TRAPS"

static func target_lane(owner_index: int, id: String) -> int:
	return 1 - owner_index if is_trap(id) else owner_index

static func loadout_cost(items: Array) -> int:
	var total := 0
	for id in items:
		total += int(ITEMS.get(id, {"cost": 99}).cost)
	return total

static func valid_loadout(items: Array) -> bool:
	return items.size() == 3 and loadout_cost(items) <= BUDGET and items[0] != items[1] and items[1] != items[2] and items[0] != items[2]
