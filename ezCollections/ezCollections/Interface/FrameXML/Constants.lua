LIGHTBLUE_FONT_COLOR		= CreateColor(0.53, 0.67, 1.0);

LE_ITEM_QUALITY_POOR = 0;
LE_ITEM_QUALITY_COMMON = 1;
LE_ITEM_QUALITY_UNCOMMON = 2;
LE_ITEM_QUALITY_RARE = 3;
LE_ITEM_QUALITY_EPIC = 4;
LE_ITEM_QUALITY_LEGENDARY = 5;
LE_ITEM_QUALITY_ARTIFACT = 6;
LE_ITEM_QUALITY_HEIRLOOM = 7;
LE_ITEM_QUALITY_WOW_TOKEN = 8;
NUM_LE_ITEM_QUALITYS = 8;

LE_ITEM_WEAPON_AXE1H = 0;
LE_ITEM_WEAPON_AXE2H = 1;
LE_ITEM_WEAPON_BOWS = 2;
LE_ITEM_WEAPON_GUNS = 3;
LE_ITEM_WEAPON_MACE1H = 4;
LE_ITEM_WEAPON_MACE2H = 5;
LE_ITEM_WEAPON_POLEARM = 6;
LE_ITEM_WEAPON_SWORD1H = 7;
LE_ITEM_WEAPON_SWORD2H = 8;
LE_ITEM_WEAPON_STAFF = 9;
LE_ITEM_WEAPON_FIST = 10;
LE_ITEM_WEAPON_GENERIC = 11;
LE_ITEM_WEAPON_DAGGER = 12;
LE_ITEM_WEAPON_THROWN = 13;
LE_ITEM_WEAPON_CROSSBOW = 14;
LE_ITEM_WEAPON_WAND = 15;
LE_ITEM_WEAPON_FISHINGPOLE = 16;
NUM_LE_ITEM_WEAPON = 17;

LE_ITEM_ARMOR_GENERIC = 0;
LE_ITEM_ARMOR_CLOTH = 1;
LE_ITEM_ARMOR_LEATHER = 2;
LE_ITEM_ARMOR_MAIL = 3;
LE_ITEM_ARMOR_PLATE = 4;
LE_ITEM_ARMOR_SHIELD = 5;
LE_ITEM_ARMOR_LIBRAM = 6;
LE_ITEM_ARMOR_IDOL = 7;
LE_ITEM_ARMOR_TOTEM = 8;
LE_ITEM_ARMOR_SIGIL = 9;
NUM_LE_ITEM_ARMORS = 10;

LE_TRANSMOG_COLLECTION_TYPE_HEAD = 1;
LE_TRANSMOG_COLLECTION_TYPE_SHOULDER = 2;
LE_TRANSMOG_COLLECTION_TYPE_BACK = 3;
LE_TRANSMOG_COLLECTION_TYPE_CHEST = 4;
LE_TRANSMOG_COLLECTION_TYPE_TABARD = 5;
LE_TRANSMOG_COLLECTION_TYPE_SHIRT = 6;
LE_TRANSMOG_COLLECTION_TYPE_WRIST = 7;
LE_TRANSMOG_COLLECTION_TYPE_HANDS = 8;
LE_TRANSMOG_COLLECTION_TYPE_WAIST = 9;
LE_TRANSMOG_COLLECTION_TYPE_LEGS = 10;
LE_TRANSMOG_COLLECTION_TYPE_FEET = 11;
LE_TRANSMOG_COLLECTION_TYPE_WAND = 12;
LE_TRANSMOG_COLLECTION_TYPE_1H_AXE = 13;
LE_TRANSMOG_COLLECTION_TYPE_1H_SWORD = 14;
LE_TRANSMOG_COLLECTION_TYPE_1H_MACE = 15;
LE_TRANSMOG_COLLECTION_TYPE_DAGGER = 16;
LE_TRANSMOG_COLLECTION_TYPE_FIST = 17;
LE_TRANSMOG_COLLECTION_TYPE_SHIELD = 18;
LE_TRANSMOG_COLLECTION_TYPE_HOLDABLE = 19;
LE_TRANSMOG_COLLECTION_TYPE_2H_AXE = 20;
LE_TRANSMOG_COLLECTION_TYPE_2H_SWORD = 21;
LE_TRANSMOG_COLLECTION_TYPE_2H_MACE = 22;
LE_TRANSMOG_COLLECTION_TYPE_STAFF = 23;
LE_TRANSMOG_COLLECTION_TYPE_POLEARM = 24;
LE_TRANSMOG_COLLECTION_TYPE_BOW = 25;
LE_TRANSMOG_COLLECTION_TYPE_GUN = 26;
LE_TRANSMOG_COLLECTION_TYPE_CROSSBOW = 27;
LE_TRANSMOG_COLLECTION_TYPE_THROWN = 28;
LE_TRANSMOG_COLLECTION_TYPE_FISHING_POLE = 29;
LE_TRANSMOG_COLLECTION_TYPE_MISC = 30;
NUM_LE_TRANSMOG_COLLECTION_TYPES = 30;

LE_TRANSMOG_TYPE_APPEARANCE = 0;
LE_TRANSMOG_TYPE_ILLUSION = 1;
NUM_LE_TRANSMOG_TYPES = 2;

LE_TRANSMOG_SEARCH_TYPE_ITEMS = 1;
LE_TRANSMOG_SEARCH_TYPE_BASE_SETS = 2;
LE_TRANSMOG_SEARCH_TYPE_USABLE_SETS = 3;
NUM_LE_TRANSMOG_SEARCH_TYPES = 3;

LE_TRANSMOG_SET_FILTER_COLLECTED = 1;
LE_TRANSMOG_SET_FILTER_UNCOLLECTED = 2;
LE_TRANSMOG_SET_FILTER_PVE = 3;
LE_TRANSMOG_SET_FILTER_PVP = 4;
LE_TRANSMOG_SET_FILTER_CORE = 5;
LE_TRANSMOG_SET_FILTER_WOWHEAD = 6;
LE_TRANSMOG_SET_FILTER_CLOTH = 7;
LE_TRANSMOG_SET_FILTER_LEATHER = 8;
LE_TRANSMOG_SET_FILTER_MAIL = 9;
LE_TRANSMOG_SET_FILTER_PLATE = 10;
LE_TRANSMOG_SET_FILTER_MISC = 11;
LE_TRANSMOG_SET_FILTER_GROUP = 12;
LE_TRANSMOG_SET_FILTER_SORT = 13;
LE_TRANSMOG_SET_FILTER_STORE = 14;
NUM_LE_TRANSMOG_SET_FILTERS = 14;

LE_MOUNT_JOURNAL_FILTER_COLLECTED = 1;
LE_MOUNT_JOURNAL_FILTER_NOT_COLLECTED = 2;
LE_MOUNT_JOURNAL_FILTER_UNUSABLE = 3;
LE_MOUNT_JOURNAL_FILTER_SUBSCRIPTION = 4;
NUM_LE_MOUNT_JOURNAL_FILTERS = 4;

LE_PET_JOURNAL_FILTER_COLLECTED = 1;
LE_PET_JOURNAL_FILTER_NOT_COLLECTED = 2;
LE_PET_JOURNAL_FILTER_SUBSCRIPTION = 3;
NUM_LE_PET_JOURNAL_FILTERS = 3;

LE_SORT_BY_NAME = 1;
LE_SORT_BY_LEVEL = 2;
LE_SORT_BY_RARITY = 3;
LE_SORT_BY_PETTYPE = 4;
NUM_LE_PET_SORT_PARAMETERS = 4;

-- ezCollections: custom indexing only for things we (potentially) care about to keep the overall number below 32 to allow it to fit into a numeric bitfield
LE_FRAME_TUTORIAL_PET_JOURNAL = 1;
LE_FRAME_TUTORIAL_TOYBOX_FAVORITE = 2;
LE_FRAME_TUTORIAL_TOYBOX_MOUSEWHEEL_PAGING = 3;
LE_FRAME_TUTORIAL_TOYBOX = 4;
LE_FRAME_TUTORIAL_HEIRLOOM_JOURNAL = 5;
LE_FRAME_TUTORIAL_HEIRLOOM_JOURNAL_TAB = 6;
LE_FRAME_TUTORIAL_HEIRLOOM_JOURNAL_LEVEL = 7;
LE_FRAME_TUTORIAL_TRANSMOG_JOURNAL_TAB = 8;
LE_FRAME_TUTORIAL_TRANSMOG_MODEL_CLICK = 9;
LE_FRAME_TUTORIAL_TRANSMOG_SPECS_BUTTON = 10;
LE_FRAME_TUTORIAL_TRANSMOG_OUTFIT_DROPDOWN = 11;
LE_FRAME_TUTORIAL_TRANSMOG_SETS_TAB = 12;
LE_FRAME_TUTORIAL_TRANSMOG_SETS_VENDOR_TAB = 13;
LE_FRAME_TUTORIAL_EZCOLLECTIONS_MICRO_BUTTON = 14;
LE_FRAME_TUTORIAL_EZCOLLECTIONS_PORTRAIT_BUTTON = 15;
LE_FRAME_TUTORIAL_EZCOLLECTIONS_TRANSMOG_TAB = 16;
NUM_LE_FRAME_TUTORIALS = 16;

-- Instance
INSTANCE_TYPE_DUNGEON = 1;
INSTANCE_TYPE_RAID = 2;
INSTANCE_TYPE_BG = 3;
INSTANCE_TYPE_ARENA = 4;

PET_TYPE_SUFFIX = {
[1] = "Humanoid",
[2] = "Dragon",
[3] = "Flying",
[4] = "Undead",
[5] = "Critter",
[6] = "Magical",
[7] = "Elemental",
[8] = "Beast",
[9] = "Water",
[10] = "Mechanical",
};

-- TRANSMOG
ENCHANT_EMPTY_SLOT_FILEDATAID = [[Interface\Icons\INV_Scroll_05]];
WARDROBE_TOOLTIP_CYCLE_ARROW_ICON = [[|TInterface\AddOns\ezCollections\Interface\Transmogrify\transmog-tooltip-arrow:12:11:-1:-1|t]];
WARDROBE_TOOLTIP_CYCLE_SPACER_ICON = [[|TInterface\AddOns\ezCollections\Interface\Common\spacer:12:11:-1:-1|t]];
WARDROBE_CYCLE_KEY = "TAB";
WARDROBE_PREV_VISUAL_KEY = "LEFT";
WARDROBE_NEXT_VISUAL_KEY = "RIGHT";
WARDROBE_UP_VISUAL_KEY = "UP";
WARDROBE_DOWN_VISUAL_KEY = "DOWN";

TRANSMOG_INVALID_CODES = {
	"NO_ITEM",
	"NOT_SOULBOUND",
	"LEGENDARY",
	"ITEM_TYPE",
	"DESTINATION",
	"MISMATCH",
	"",		-- same item
	"",		-- invalid source
	"",		-- invalid source quality
	"CANNOT_USE",
}

TRANSMOG_SOURCE_BOSS_DROP = 1;
TRANSMOG_SOURCE_QUEST = 2;
TRANSMOG_SOURCE_VENDOR = 3;
TRANSMOG_SOURCE_WORLD_DROP = 4;
TRANSMOG_SOURCE_ACHIEVEMENT = 5;
TRANSMOG_SOURCE_PROFESSION = 6;
TRANSMOG_SOURCE_STORE = 7;
TRANSMOG_SOURCE_SUBSCRIPTION = 8;
MAX_TRANSMOG_SOURCES = 8;

TRANSMOG_SLOTS = {
	[1]  = { slot = "HEADSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_HEAD },
	[2]  = { slot = "SHOULDERSLOT", 		transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_SHOULDER },
	[3]  = { slot = "BACKSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_BACK },
	[4]  = { slot = "CHESTSLOT",		 	transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_CHEST },
	[5]  = { slot = "TABARDSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_TABARD },
	[6]  = { slot = "SHIRTSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_SHIRT },
	[7]  = { slot = "WRISTSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_WRIST },
	[8]  = { slot = "HANDSSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_HANDS },
	[9]  = { slot = "WAISTSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_WAIST },
	[10] = { slot = "LEGSSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_LEGS },
	[11] = { slot = "FEETSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = LE_TRANSMOG_COLLECTION_TYPE_FEET },
	[12] = { slot = "MAINHANDSLOT", 		transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = nil },
	[13] = { slot = "SECONDARYHANDSLOT", 	transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = nil },
	[14] = { slot = "MAINHANDSLOT", 		transmogType = LE_TRANSMOG_TYPE_ILLUSION,	armorCategoryID = nil },
	[15] = { slot = "SECONDARYHANDSLOT",	transmogType = LE_TRANSMOG_TYPE_ILLUSION,	armorCategoryID = nil },
	[16] = { slot = "RANGEDSLOT", 			transmogType = LE_TRANSMOG_TYPE_APPEARANCE,	armorCategoryID = nil },
}

FIRST_TRANSMOG_COLLECTION_WEAPON_TYPE = LE_TRANSMOG_COLLECTION_TYPE_FEET + 1;
LAST_TRANSMOG_COLLECTION_WEAPON_TYPE = NUM_LE_TRANSMOG_COLLECTION_TYPES;
NO_TRANSMOG_SOURCE_ID = 0;
NO_TRANSMOG_VISUAL_ID = 0;

-- TEXTURES
QUESTION_MARK_ICON = [[INTERFACE\ICONS\INV_MISC_QUESTIONMARK.BLP]];

-- TUTORIALS
HELPTIP_HEIGHT_PADDING = 29;

-- ezCollections
ANIMATION_ARMOR_PREVIEW = 15;
ANIMATION_WEAPON_PREVIEW_MAIN = 51;
ANIMATION_WEAPON_PREVIEW_OFF = 63;
