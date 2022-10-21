-- Load localization only if it matches the client locale
if GetLocale() ~= "zhCN" then
    return;
end

BINDING_NAME_TOGGLECOLLECTIONS = "Toggle Collections"
BINDING_NAME_TOGGLECOLLECTIONSHEIRLOOM = "Toggle Heirlooms Pane"
BINDING_NAME_TOGGLECOLLECTIONSMOUNTJOURNAL = "Toggle Mount Journal"
BINDING_NAME_TOGGLECOLLECTIONSPETJOURNAL = "Toggle Pet Journal"
BINDING_NAME_TOGGLECOLLECTIONSTOYBOX = "Toggle Toy Box"
BINDING_NAME_TOGGLECOLLECTIONSWARDROBE = "Toggle Appearances"
BINDING_NAME_TOGGLETRANSMOGRIFY = "Toggle Transmogrify"
COLLECTED = "Collected"
COLLECTION_PAGE_NUMBER = "Page %d / %d"
COLLECTION_UNOPENED_PLURAL = "You have unopened items in your collection."
COLLECTION_UNOPENED_SINGULAR = "You have an unopened item in your collection."
COLLECTIONS = "Collections"
COLLECTIONS_MICRO_BUTTON_SPEC_TUTORIAL = "Mounts, pets, toys, and heirlooms can all be found here!"
HEIRLOOM_UPGRADE_TOOLTIP_FORMAT = "Heirloom Upgrade Level: %d/%d"
HEIRLOOMS = "Heirlooms"
HEIRLOOMS_CATEGORY_BACK = "Back"
HEIRLOOMS_CATEGORY_CHEST = "Chest"
HEIRLOOMS_CATEGORY_HEAD = "Head"
HEIRLOOMS_CATEGORY_LEGS = "Legs"
HEIRLOOMS_CATEGORY_SHOULDER = "Shoulder"
HEIRLOOMS_CATEGORY_TRINKETS_RINGS_AND_NECKLACES = "Trinkets, Rings & Necklaces"
HEIRLOOMS_CATEGORY_WEAPON = "Weapons"
HEIRLOOMS_CLASS_FILTER_FORMAT = "|c%s%s|r"
HEIRLOOMS_CLASS_SPEC_FILTER_FORMAT = "|c%s%s|r (%s)"
HEIRLOOMS_JOURNAL = "Heirlooms Journal"
HEIRLOOMS_JOURNAL_TUTORIAL_TAB = "Heirlooms you acquire are automatically added to your heirloom collection."
HEIRLOOMS_JOURNAL_TUTORIAL_UPGRADE = "This is the max level of the heirloom. You can raise this level by using special upgrade tokens."
HEIRLOOMS_MICRO_BUTTON_SPEC_TUTORIAL = "Visit the Heirlooms pane to view your heirloom collection."
HEIRLOOMS_PROGRESS_FORMAT = "%d/%d"
MOUNT_JOURNAL_NOT_COLLECTED = "You have not collected this mount."
NEW = "New"
NEW_CAPS = "NEW"
NOT_COLLECTED = "Not Collected"
SPELL_FAILED_MOUNT_COLLECTED_ON_OTHER_CHAR = "You have collected this mount but it is not usable on this character."
TRANSMOG_ALL_SPECIALIZATIONS = "All specializations"
TRANSMOG_APPLY_TO = "Apply to:"
TRANSMOG_CATEGORY_FAVORITE_LIMIT = "You cannot add any more favorites in this category."
TRANSMOG_COLLECTED = "Collected"
TRANSMOG_CURRENT_SPECIALIZATION = "Current specialization only"
TRANSMOG_EMPTY_SLOT_FORMAT = "(%s)"
TRANSMOG_JOURNAL_TAB_TUTORIAL = "The Appearances tab shows all the item appearances you can use for transmogrification."
TRANSMOG_MOUSE_CLICK_TUTORIAL = "Right-click to favorite an appearance. Ctrl-click to view it on your character."
TRANSMOG_NO_VALID_ITEMS_EQUIPPED = "No valid items equipped."
TRANSMOG_OUTFIT_ALL_INVALID_APPEARANCES = "You can't save this outfit because none of the item appearances can be transmogrified by your character."
TRANSMOG_OUTFIT_ALREADY_EXISTS = "An outfit with that name already exists."
TRANSMOG_OUTFIT_CHECKING_APPEARANCES = "Checking appearances..."
TRANSMOG_OUTFIT_CONFIRM_DELETE = "Are you sure you want to delete the outfit %s?"
TRANSMOG_OUTFIT_CONFIRM_OVERWRITE = "You already have an oufit named %s. Would you like to overwrite it?"
TRANSMOG_OUTFIT_CONFIRM_SAVE = "Are you sure you want to overwrite the outfit %s?"
TRANSMOG_OUTFIT_DELETE = "Delete Outfit"
TRANSMOG_OUTFIT_DROPDOWN_TUTORIAL = "Created the perfect outfit? Save it for future use."
TRANSMOG_OUTFIT_EDIT = "Rename/Delete"
TRANSMOG_OUTFIT_NAME = "Enter Outfit Name:"
TRANSMOG_OUTFIT_NEW = "New Outfit"
TRANSMOG_OUTFIT_NONE = "No Outfit"
TRANSMOG_OUTFIT_SOME_INVALID_APPEARANCES = "One or more item appearances won't be saved in this outfit because they can't be transmogrified by your character."
TRANSMOG_REQUIRED_ABILITY = "%s required to use this appearance."
TRANSMOG_REQUIRED_FACTION = "%s - %s reputation required to use this appearance."
TRANSMOG_REQUIRED_LEVEL = "Level %d required to use this appearance."
TRANSMOG_REQUIRED_SKILL = "%s (%d) required to use this appearance."
TRANSMOG_SET_PARTIALLY_KNOWN = "You know some of the appearances granted by this set already."
TRANSMOG_SOURCE_1 = "Boss Drop"
TRANSMOG_SOURCE_2 = "Quest"
TRANSMOG_SOURCE_3 = "Vendor"
TRANSMOG_SOURCE_4 = "World Drop"
TRANSMOG_SOURCE_5 = "Achievement"
TRANSMOG_SOURCE_6 = "Profession"
TRANSMOG_SOURCE_7 = "|cFF00C0FFStore|r"
TRANSMOG_SOURCE_8 = "|cFF00C0FFSubscription|r"
TRANSMOG_SPECS_BUTTON_TUTORIAL = "You can apply this look to all your specializations, or just your current one."
TRANSMOGRIFIED = "Transmogrified to:\n%s"
TRANSMOGRIFIED_ENCHANT = "Illusion: %s"
TRANSMOGRIFIED_HEADER = "Transmogrified to:"
TRANSMOGRIFY = "Transmogrify"
TRANSMOGRIFY_CLEAR_ALL_PENDING = "Undo all pending changes"
TRANSMOGRIFY_ILLUSION_INVALID_ITEM = "The equipped item cannot be transmogrified with enchants."
TRANSMOGRIFY_INVALID_CANNOT_USE = "You cannot use the item that has this appearance."
TRANSMOGRIFY_INVALID_DESTINATION = "This item cannot be transmogrified."
TRANSMOGRIFY_INVALID_ITEM_TYPE = "This type of item cannot be transmogrified."
TRANSMOGRIFY_INVALID_LEGENDARY = "Legendary items cannot be transmogrified."
TRANSMOGRIFY_INVALID_MISMATCH = "This item type isn't compatible with this appearance."
TRANSMOGRIFY_INVALID_NO_ITEM = "There is no equipped item in this slot."
TRANSMOGRIFY_INVALID_NOT_SOULBOUND = "This item is not soulbound."
TRANSMOGRIFY_LOSE_REFUND = "Using this item for transmogrify will make it non-refundable.\nDo you wish to continue?"
TRANSMOGRIFY_LOSE_TRADE = "Using this item for transmogrify will make it non-tradeable.\nDo you wish to continue?"
TRANSMOGRIFY_STYLE_UNCOLLECTED = "You haven't collected this appearance yet."
TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN = "You've collected this appearance"
TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN = "You haven't collected this appearance"
TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN = "You've collected this appearance, but not from this item"
TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNUSABLE = "This appearance can't be used by your character"
TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNCOLLECTABLE = "This item can't be used for transmogrification, but may be worn as equipment"
TRANSMOGRIFY_TOOLTIP_REVERT = "To be reverted"
WARDROBE = "Appearances"
WARDROBE_NO_SEARCH = "Search is not available for this category."
WARDROBE_OTHER_ITEMS = "Other items using this appearance:"
WARDROBE_TOOLTIP_CYCLE = "Press Tab to cycle through items."
WARDROBE_TOOLTIP_DUNGEONS = "Dungeons in %s"
WARDROBE_TOOLTIP_ENCOUNTER_SOURCE = "%s in %s"
WARDROBE_TOOLTIP_RAIDS = "Raids in %s"
WARDROBE_TOOLTIP_TRANSMOGRIFIER = "Visit a Transmogrifier to apply this appearance to your outfit."
WARDROBE_TRANSMOGRIFY_AS = "Transmogrify as:"
FAVORITES = "Favorites"
FAVORITES_FILTER = "Only Favorites"
BATTLE_PET_UNFAVORITE = "Remove Favorite"
TOYBOX_FAVORITE_HELP = "Right-click to favorite a toy. Favorite toys are pinned to the first page."
BATTLE_PET_FAVORITE = "Set Favorite"
MOUNT_JOURNAL_SUMMON_RANDOM_FAVORITE_MOUNT = "Summon Random\nFavorite Mount"
ERR_MOUNT_NO_FAVORITES = "You have no valid favorite mounts."
MOUNT_JOURNAL_NO_VALID_FAVORITES = "You have selected no favorite mounts appropriate for this area.\nRight-Click in the Mount Journal to set Favorites."
ERR_LEARN_TOY_S = "%s has been added to your Toy Box."
ERR_LEARN_HEIRLOOM_S = "%s has been added to your heirloom collection."
ERR_LEARN_TRANSMOG_S = "%s has been added to your appearance collection."
ERR_REVOKE_TRANSMOG_S = "%s has been removed from your appearance collection."
WEAPON_ENCHANTMENT = "Weapon Enchantment"
ROTATE_LEFT = "Rotate Left"
ROTATE_RIGHT = "Rotate Right"
ROTATE_TOOLTIP = "Left-click on character and drag to rotate."
RESET_POSITION = "Reset Position"
DRAG_MODEL = "Drag"
DRAG_MODEL_TOOLTIP = "Right-click on character and drag to move it within the window."
WILL_BE_TRANSMOGRIFIED_HEADER = "To be transmogrified to:"
SOURCES = "Sources"
CHECK_ALL = "Check All"
UNCHECK_ALL = "Uncheck All"
SEARCH_LOADING_TEXT = "Loading..."
SEARCH_PROGRESS_BAR_TEXT = "Searching"
WARDROBE_ITEMS = "Items"
WARDROBE_SETS = "Sets"
TRANSMOG_APPEARANCE_USABLE_HOLIDAY = "This appearance is only usable during holiday: %s."
WARDROBE_ALTERNATE_ITEMS = "Other items that unlock this slot:"
TRANSMOG_SET_PARTIALLY_KNOWN = "You know some of the appearances granted by this set already."
ERR_TRANSMOG_SET_ALREADY_KNOWN = "All appearances are already in your collection."
ERR_COMPLETED_TRANSMOG_SET_S = "You've completed the set %s."
TRANSMOG_SET_LINK_FORMAT = "%s (%s)"
TRANSMOG_SET_PVP = "PvP"
TRANSMOG_SET_PVE = "PvE"
TRANSMOG_SETS_TAB_TUTORIAL = "View all the appearance sets you can collect for your class here."
TRANSMOG_SETS_VENDOR_TUTORIAL = "View and apply your completed appearance sets here."
TRANSMOG_SETS_UNFAVORITE_WITH_DESCRIPTION = "Remove Favorite (%s)"
TRANSMOG_SETS_FAVORITE_WITH_DESCRIPTION = "Set Favorite (%s)"
TRANSMOG_SETS_TAB_DISABLED = "You don't have any completed or usable appearance sets."
TRANSMOG_SET_PARTIALLY_KNOWN_CLASS = "Contains %d uncollected |4appearance:appearances;."
TRANSMOG_SET_PARTIALLY_KNOWN_MIX = "Contains %1$d uncollected |4appearance:appearances; for your class and %2$d uncollected |4appearance:appearances; for other classes."
TRANSMOG_SET_LIMITED_TIME_SET = "Limited Time Set"
TRANSMOG_SET_LIMITED_TIME_SET_TOOLTIP = "This set can be collected during the current season only."
ITEM_COSMETIC = "Cosmetic"
ITEM_REQ_ALLIANCE = "Alliance Only"
ITEM_REQ_HORDE = "Horde Only"
ITEM_TOY_ONUSE = "Use: Adds this toy to your Toy Box."
TOTAL_MOUNTS = "Total Mounts"
ERR_NO_RIDING_SKILL = "You can learn riding and obtain a mount from your riding trainer at level 20"
MOUNT_JOURNAL_FILTER_UNUSABLE = "Unusable"
MOUNT_JOURNAL_FILTER_AQUATIC = "Aquatic"
MOUNT_JOURNAL_FILTER_FLYING = "Flying"
MOUNT_JOURNAL_FILTER_GROUND = "Ground"
MOUNT_JOURNAL_FILTER_TYPE = "Type"
UNWRAP = "Unwrap"
BATTLE_PET_SOURCE_1 = "Drop"
BATTLE_PET_SOURCE_2 = "Quest"
BATTLE_PET_SOURCE_3 = "Vendor"
BATTLE_PET_SOURCE_4 = "Profession"
BATTLE_PET_SOURCE_5 = "Pet Battle"
BATTLE_PET_SOURCE_6 = "Achievement"
BATTLE_PET_SOURCE_7 = "World Event"
BATTLE_PET_SOURCE_8 = "Promotion"
BATTLE_PET_SOURCE_9 = "Trading Card Game"
BATTLE_PET_SOURCE_10 = "In-Game Shop"
BATTLE_PET_SOURCE_11 = "Discovery"
BATTLE_PET_SOURCE_12 = "Other"
BATTLE_PET_NAME_1 = "Humanoid"
BATTLE_PET_NAME_2 = "Dragonkin"
BATTLE_PET_NAME_3 = "Flying"
BATTLE_PET_NAME_4 = "Undead"
BATTLE_PET_NAME_5 = "Critter"
BATTLE_PET_NAME_6 = "Magic"
BATTLE_PET_NAME_7 = "Elemental"
BATTLE_PET_NAME_8 = "Beast"
BATTLE_PET_NAME_9 = "Aquatic"
BATTLE_PET_NAME_10 = "Mechanical"
BATTLE_PET_SUMMON = "Summon"
BATTLE_PETS_TOTAL_PETS = "Total Pets"
PET_JOURNAL_SUMMON_RANDOM_FAVORITE_PET = "Summon Random\nFavorite Pet"
PET_JOURNAL_FILTER_USABLE_ONLY = "Usable Only"
PET_FAMILIES = "Pet Families"
RAID_FRAME_SORT_LABEL = "Sort By"
TOY = "Toy"
TOY_BOX = "Toy Box"
TOY_PROGRESS_FORMAT = "%d/%d"
TOYBOX_MOUSEWHEEL_PAGING_HELP = "Tip: You can use your mouse wheel to quickly page through the Toy Box."
TOYBOX_MICRO_BUTTON_SPEC_TUTORIAL = "Visit the Toy Box to view your toy collection."
EXPANSION_FILTER_TEXT = "Expansion"
EXPANSION_NAME0 = "Classic"
EXPANSION_NAME1 = "The Burning Crusade"
EXPANSION_NAME2 = "Wrath of the Lich King"
DRESSING_ROOM_APPEARANCE_LIST = "Appearance List"
TRANSMOG_OUTFIT_HYPERLINK_TEXT = [[|TInterface\AddOns\ezCollections\Interface\Minimap\Tracking\Transmogrifier:13:13:-1:1|tOutfit]]
LINK_TRANSMOG_OUTFIT = "Link Outfit"
SLASH_TRANSMOG_OUTFIT1 = "/outfit"
TRANSMOG_OUTFIT_POST_IN_CHAT = "Post in Chat"
TRANSMOG_OUTFIT_COPY_TO_CLIPBOARD = "Copy to Clipboard |cffffd100(to share online)|r"
LINK_TRANSMOG_OUTFIT_HELPTIP = "Share this outfit by linking it in chat or online"
TRANSMOG_OUTFIT_COPY_TO_CLIPBOARD_NOTICE = "Outfit link copied to clipboard."
TRANSMOG_OUTFIT_LINK_INVALID = "Invalid outfit link."
VIEW_IN_DRESSUP_FRAME = "View in Dressing Room"
LFG_CALL_TO_ARMS = "Call To Arms: %s";
LFG_CALL_TO_ARMS_EXPLANATION = "If you perform this role, you will receive bonus rewards!";
