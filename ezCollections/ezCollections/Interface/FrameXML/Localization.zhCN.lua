-- Load localization only if it matches the client locale
if GetLocale() ~= "zhCN" then
    return;
end

BINDING_NAME_TOGGLECOLLECTIONS = "切换藏品"
BINDING_NAME_TOGGLECOLLECTIONSHEIRLOOM = "切换传家宝界面"
BINDING_NAME_TOGGLECOLLECTIONSMOUNTJOURNAL = "切换坐骑日记"
BINDING_NAME_TOGGLECOLLECTIONSPETJOURNAL = "切换宠物日记"
BINDING_NAME_TOGGLECOLLECTIONSTOYBOX = "切换玩具盒"
BINDING_NAME_TOGGLECOLLECTIONSWARDROBE = "切换外观"
BINDING_NAME_TOGGLETRANSMOGRIFY = "切换幻化"
COLLECTED = "已收集"
COLLECTION_PAGE_NUMBER = "页面 %d / %d"
COLLECTION_UNOPENED_PLURAL = "你的收藏中有一件未开封的物品。"
COLLECTION_UNOPENED_SINGULAR = "你的收藏中有一件未开封的物品。"
COLLECTIONS = "收藏品"
COLLECTIONS_MICRO_BUTTON_SPEC_TUTORIAL = "坐骑、宠物、玩具和传家宝都可以在这里找到！"
HEIRLOOM_UPGRADE_TOOLTIP_FORMAT = "传家宝升级等级：%d/%d"
HEIRLOOMS = "传家宝"
HEIRLOOMS_CATEGORY_BACK = "返回"
HEIRLOOMS_CATEGORY_CHEST = "胸部"
HEIRLOOMS_CATEGORY_HEAD = "头部"
HEIRLOOMS_CATEGORY_LEGS = "腿部"
HEIRLOOMS_CATEGORY_SHOULDER = "肩部"
HEIRLOOMS_CATEGORY_TRINKETS_RINGS_AND_NECKLACES = "小饰品、戒指和项链"
HEIRLOOMS_CATEGORY_WEAPON = "武器"
HEIRLOOMS_CLASS_FILTER_FORMAT = "|c%s%s|r"
HEIRLOOMS_CLASS_SPEC_FILTER_FORMAT = "|c%s%s|r (%s)"
HEIRLOOMS_JOURNAL = "传家宝日记"
HEIRLOOMS_JOURNAL_TUTORIAL_TAB = "您获得的传家宝会自动添加到您的传家宝收藏中。"
HEIRLOOMS_JOURNAL_TUTORIAL_UPGRADE = "这是传家宝的最高等级。 您可以通过使用特殊升级令牌来提高该等级。"
HEIRLOOMS_MICRO_BUTTON_SPEC_TUTORIAL = "访问传家宝界面以查看您的传家宝收藏。"
HEIRLOOMS_PROGRESS_FORMAT = "%d/%d"
MOUNT_JOURNAL_NOT_COLLECTED = "你还没有收集到这个坐骑。"
NEW = "新的"
NEW_CAPS = "新的"
NOT_COLLECTED = "未收集"
SPELL_FAILED_MOUNT_COLLECTED_ON_OTHER_CHAR = "你已经收集了这个坐骑，但它不能用于这个角色。"
TRANSMOG_ALL_SPECIALIZATIONS = "所有专业"
TRANSMOG_APPLY_TO = "适用于："
TRANSMOG_CATEGORY_FAVORITE_LIMIT = "您无法在该类别中添加更多收藏夹。"
TRANSMOG_COLLECTED = "已收集"
TRANSMOG_CURRENT_SPECIALIZATION = "仅限当前专业"
TRANSMOG_EMPTY_SLOT_FORMAT = "(%s)"
TRANSMOG_JOURNAL_TAB_TUTORIAL = "外观选项卡显示所有可用于幻化的物品外观。"
TRANSMOG_MOUSE_CLICK_TUTORIAL = "右键单击以收藏外观。 按住 Ctrl 键单击以查看您的角色。"
TRANSMOG_NO_VALID_ITEMS_EQUIPPED = "没有装备有效的物品。"
TRANSMOG_OUTFIT_ALL_INVALID_APPEARANCES = "您无法保存这件装备，因为您的角色无法幻化任何物品外观。"
TRANSMOG_OUTFIT_ALREADY_EXISTS = "同名的外观已经存在。"
TRANSMOG_OUTFIT_CHECKING_APPEARANCES = "检查外观..."
TRANSMOG_OUTFIT_CONFIRM_DELETE = "您确定要删除外观 %s 吗？"
TRANSMOG_OUTFIT_CONFIRM_OVERWRITE = "您已经有一个外观名称 %s。 你想覆盖它吗？"
TRANSMOG_OUTFIT_CONFIRM_SAVE = "你确定要覆盖%s的外观吗？"
TRANSMOG_OUTFIT_DELETE = "删除外观"
TRANSMOG_OUTFIT_DROPDOWN_TUTORIAL = "创造了完美的外观？ 保存以备将来使用。"
TRANSMOG_OUTFIT_EDIT = "重命名/删除"
TRANSMOG_OUTFIT_NAME = "输入外观名称："
TRANSMOG_OUTFIT_NEW = "新外观"
TRANSMOG_OUTFIT_NONE = "没有外观"
TRANSMOG_OUTFIT_SOME_INVALID_APPEARANCES = "一件或多件物品外观不会保存在这套服装中，因为它们不能被你的角色幻化。"
TRANSMOG_REQUIRED_ABILITY = "%s 需要使用该外观。"
TRANSMOG_REQUIRED_FACTION = "%s - 使用该外观需要 %s 声望。"
TRANSMOG_REQUIRED_LEVEL = "使用该外观需要 %d 级。"
TRANSMOG_REQUIRED_SKILL = "使用该外观需要 %s (%d)。"
TRANSMOG_SET_PARTIALLY_KNOWN = "你已经知道这个系列授予的一些外观。"
TRANSMOG_SOURCE_1 = "首领掉落"
TRANSMOG_SOURCE_2 = "任务"
TRANSMOG_SOURCE_3 = "商人出售"
TRANSMOG_SOURCE_4 = "世界掉落"
TRANSMOG_SOURCE_5 = "成就"
TRANSMOG_SOURCE_6 = "专业技能"
TRANSMOG_SOURCE_7 = "|cFF00C0FF商城|r"
TRANSMOG_SOURCE_8 = "|cFF00C0FF活动|r"
TRANSMOG_SPECS_BUTTON_TUTORIAL = "您可以将该外观应用于您的所有专业，或仅应用于您当前的专业。"
TRANSMOGRIFIED = "幻化为：\n%s"
TRANSMOGRIFIED_ENCHANT = "幻象：%s"
TRANSMOGRIFIED_HEADER = "幻化为："
TRANSMOGRIFY = "幻化"
TRANSMOGRIFY_CLEAR_ALL_PENDING = "取消所有未保存的更改"
TRANSMOGRIFY_ILLUSION_INVALID_ITEM = "装备的物品不能被附魔幻化。"
TRANSMOGRIFY_INVALID_CANNOT_USE = "您不能使用具有该外观的物品。"
TRANSMOGRIFY_INVALID_DESTINATION = "该物品无法幻化。"
TRANSMOGRIFY_INVALID_ITEM_TYPE = "该类物品无法幻化。"
TRANSMOGRIFY_INVALID_LEGENDARY = "传说级物品不能幻化。"
TRANSMOGRIFY_INVALID_MISMATCH = "该物品类型与该外观不兼容。"
TRANSMOGRIFY_INVALID_NO_ITEM = "该插槽内没有装备物品。"
TRANSMOGRIFY_INVALID_NOT_SOULBOUND = "这个物品不是灵魂绑定的。"
TRANSMOGRIFY_LOSE_REFUND = "使用此物品进行幻化将使其不可退款。\n您要继续吗？"
TRANSMOGRIFY_LOSE_TRADE = "使用此物品进行幻化将使其无法交易。\你想继续吗？"
TRANSMOGRIFY_STYLE_UNCOLLECTED = "你还没有收藏这个外观。"
TRANSMOGRIFY_TOOLTIP_APPEARANCE_KNOWN = "您已收藏此外观"
TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNKNOWN = "你还没有收藏这个外观"
TRANSMOGRIFY_TOOLTIP_ITEM_UNKNOWN_APPEARANCE_KNOWN = "您已收集此外观，但不是来自该物品"
TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNUSABLE = "您的角色无法使用此外观"
TRANSMOGRIFY_TOOLTIP_APPEARANCE_UNCOLLECTABLE = "此物品不能用于幻化，但可以作为装备佩戴"
TRANSMOGRIFY_TOOLTIP_REVERT = "待恢复"
WARDROBE = "外观"
WARDROBE_NO_SEARCH = "搜索不适用于该类别。"
WARDROBE_OTHER_ITEMS = "使用此外观的其他物品："
WARDROBE_TOOLTIP_CYCLE = "按 Tab 循环浏览物品。"
WARDROBE_TOOLTIP_DUNGEONS = "在地下城 %s"
WARDROBE_TOOLTIP_ENCOUNTER_SOURCE = "%s 在 %s"
WARDROBE_TOOLTIP_RAIDS = "在团队 %s"
WARDROBE_TOOLTIP_TRANSMOGRIFIER = "拜访幻化师，将这种外观应用到你的装备上。"
WARDROBE_TRANSMOGRIFY_AS = "幻化为："
FAVORITES = "收藏夹"
FAVORITES_FILTER = "仅收藏夹"
BATTLE_PET_UNFAVORITE = "删除收藏夹"
TOYBOX_FAVORITE_HELP = "右键单击以收藏玩具。 最喜欢的玩具固定在第一页。"
BATTLE_PET_FAVORITE = "设置收藏夹"
MOUNT_JOURNAL_SUMMON_RANDOM_FAVORITE_MOUNT = "召唤随机\n偏好坐骑"
ERR_MOUNT_NO_FAVORITES = "您没有有效的收藏坐骑。"
MOUNT_JOURNAL_NO_VALID_FAVORITES = "您没有选择适合该区域的收藏坐骑。\n右键单击坐骑日志以设置收藏夹。"
ERR_LEARN_TOY_S = "%s 已添加到您的玩具箱中。"
ERR_LEARN_HEIRLOOM_S = "%s 已添加到您的传家宝收藏中。"
ERR_LEARN_TRANSMOG_S = "%s 已添加到您的外观收藏中。"
ERR_REVOKE_TRANSMOG_S = "%s 已从您的外观收藏中删除。"
WEAPON_ENCHANTMENT = "武器附魔"
ROTATE_LEFT = "向左旋转"
ROTATE_RIGHT = "向右旋转"
ROTATE_TOOLTIP = "左键单击角色并拖动旋转。"
RESET_POSITION = "重置位置"
DRAG_MODEL = "拖动"
DRAG_MODEL_TOOLTIP = "右键单击角色并拖动将其移动到窗口内。"
WILL_BE_TRANSMOGRIFIED_HEADER = "幻化为："
SOURCES = "来源"
CHECK_ALL = "勾选所有"
UNCHECK_ALL = "撤选所有"
SEARCH_LOADING_TEXT = "正在加载..."
SEARCH_PROGRESS_BAR_TEXT = "搜索"
WARDROBE_ITEMS = "物品"
WARDROBE_SETS = "套装"
TRANSMOG_APPEARANCE_USABLE_HOLIDAY = "此外观仅在假日期间可用：%s。"
WARDROBE_ALTERNATE_ITEMS = "其他可以解锁这个插槽的物品："
TRANSMOG_SET_PARTIALLY_KNOWN = "你已经知道这个系列授予的一些外观。"
ERR_TRANSMOG_SET_ALREADY_KNOWN = "所有外观都已在您的收藏中。"
ERR_COMPLETED_TRANSMOG_SET_S = "您已完成设置 %s。"
TRANSMOG_SET_LINK_FORMAT = "%s (%s)"
TRANSMOG_SET_PVP = "PvP"
TRANSMOG_SET_PVE = "PvE"
TRANSMOG_SETS_TAB_TUTORIAL = "在这里查看您可以收集的所有外观套装。"
TRANSMOG_SETS_VENDOR_TUTORIAL = "在这里查看并应用完成的外观套装。"
TRANSMOG_SETS_UNFAVORITE_WITH_DESCRIPTION = "删除收藏夹(%s)"
TRANSMOG_SETS_FAVORITE_WITH_DESCRIPTION = "设置收藏夹(%s)"
TRANSMOG_SETS_TAB_DISABLED = "您没有任何已完成或可用的外观集。"
TRANSMOG_SET_PARTIALLY_KNOWN_CLASS = "包含 %d 个未收集的 |4appearance:外观；。"
TRANSMOG_SET_PARTIALLY_KNOWN_MIX = "包含 %1$d 个未收集的 |4appearance:外观；为您的职业和%2$d未收集 |4appearance:外观；对于其他职业。"
TRANSMOG_SET_LIMITED_TIME_SET = "限时套装"
TRANSMOG_SET_LIMITED_TIME_SET_TOOLTIP = "此套装只能在当前季节收集。"
ITEM_COSMETIC = "化妆品"
ITEM_REQ_ALLIANCE = "仅限联盟"
ITEM_REQ_HORDE = "仅限部落"
ITEM_TOY_ONUSE = "使用：将此玩具添加到您的玩具箱中。"
TOTAL_MOUNTS = "总坐骑"
ERR_NO_RIDING_SKILL = "您可以在20级的时候从你的骑乘教练那里学习骑乘和获得坐骑"
MOUNT_JOURNAL_FILTER_UNUSABLE = "无法使用"
MOUNT_JOURNAL_FILTER_AQUATIC = "水栖"
MOUNT_JOURNAL_FILTER_FLYING = "飞行"
MOUNT_JOURNAL_FILTER_GROUND = "地面"
MOUNT_JOURNAL_FILTER_TYPE = "类型"
UNWRAP = "来源"
BATTLE_PET_SOURCE_1 = "掉落"
BATTLE_PET_SOURCE_2 = "任务"
BATTLE_PET_SOURCE_3 = "商人"
BATTLE_PET_SOURCE_4 = "专业技能"
BATTLE_PET_SOURCE_5 = "宠物对战"
BATTLE_PET_SOURCE_6 = "成就"
BATTLE_PET_SOURCE_7 = "世界事件"
BATTLE_PET_SOURCE_8 = "促销活动"
BATTLE_PET_SOURCE_9 = "集换卡牌游戏"
BATTLE_PET_SOURCE_10 = "游戏商城"
BATTLE_PET_SOURCE_11 = "发现"
BATTLE_PET_SOURCE_12 = "其他"
BATTLE_PET_NAME_1 = "人型"
BATTLE_PET_NAME_2 = "龙类"
BATTLE_PET_NAME_3 = "飞行"
BATTLE_PET_NAME_4 = "亡灵"
BATTLE_PET_NAME_5 = "小动物"
BATTLE_PET_NAME_6 = "魔法"
BATTLE_PET_NAME_7 = "元素"
BATTLE_PET_NAME_8 = "野兽"
BATTLE_PET_NAME_9 = "水栖"
BATTLE_PET_NAME_10 = "机械"
BATTLE_PET_SUMMON = "召唤"
BATTLE_PETS_TOTAL_PETS = "宠物总数"
PET_JOURNAL_SUMMON_RANDOM_FAVORITE_PET = "召唤随机\n偏好宠物"
PET_JOURNAL_FILTER_USABLE_ONLY = "仅可用"
PET_FAMILIES = "宠物院"
RAID_FRAME_SORT_LABEL = "排序"
TOY = "玩具"
TOY_BOX = "玩具箱"
TOY_PROGRESS_FORMAT = "%d/%d"
TOYBOX_MOUSEWHEEL_PAGING_HELP = "提示：您可以使用鼠标滚轮快速翻阅玩具箱。"
TOYBOX_MICRO_BUTTON_SPEC_TUTORIAL = "访问玩具箱以查看您的玩具收藏。"
EXPANSION_FILTER_TEXT = "资料片"
EXPANSION_NAME0 = "经典旧世"
EXPANSION_NAME1 = "燃烧的远征"
EXPANSION_NAME2 = "巫妖王之怒"
DRESSING_ROOM_APPEARANCE_LIST = "外观列表"
TRANSMOG_OUTFIT_HYPERLINK_TEXT = [[|TInterface\AddOns\ezCollections\Interface\Minimap\Tracking\Transmogrifier:13:13:-1:1|t套装]]
LINK_TRANSMOG_OUTFIT = "外观链接"
SLASH_TRANSMOG_OUTFIT1 = "/outfit"
TRANSMOG_OUTFIT_POST_IN_CHAT = "发送到聊天中"
TRANSMOG_OUTFIT_COPY_TO_CLIPBOARD = "复制到剪贴板 |cffffd100(在线共享)|r"
LINK_TRANSMOG_OUTFIT_HELPTIP = "通过在聊天或在线链接中分享这件外观"
TRANSMOG_OUTFIT_COPY_TO_CLIPBOARD_NOTICE = "外观链接已复制到剪贴板。"
TRANSMOG_OUTFIT_LINK_INVALID = "外观链接无效。"
VIEW_IN_DRESSUP_FRAME = "试衣间"
LFG_CALL_TO_ARMS = "召唤武器%s";
LFG_CALL_TO_ARMS_EXPLANATION = "如果您执行此角色，您将获得额外奖励！";
