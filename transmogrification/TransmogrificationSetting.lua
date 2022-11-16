local Transmogrify = {}
Transmogrify.VisualWeapon = {}
Transmogrify.STORE = {}
local VisualWeapon = Transmogrify.VisualWeapon;
local STORE = Transmogrify.STORE;
_ENV = require("MiscDefine");

--#######################################################
--#######  幻化功能的设置选项,按照注释根据需要改写 ######
--#######################################################

--功能Npc的ID
Transmogrify.NPC_Entry = 0;

--设定幻化菜单每页显示多少项
Transmogrify.PageItemLimit = 8

--设置能幻化的物品ID的范围
--最小物品id
Transmogrify.MinItemEntry = 1;
--最大物品id
Transmogrify.MaxItemEntry = 70000;

--[[
允许幻化的物品品质
    true    => 允许
    false   => 不允许
]]--
Transmogrify.Qualities ={
    [0]  = true, -- 允许灰色装备幻化
    [1]  = true, -- 允许白色装备
    [2]  = true, -- 允许绿色装备
    [3]  = true, -- 允许蓝色装备
    [4]  = true, -- 允许紫色装备
    [5]  = true, -- 允许橙色装备
    [6]  = true, -- 允许红色神器
    [7]  = true, -- 允许传家宝
}

--[[
需要金币
    1 => 需要金币数 = 按照物品买价(买价低于1G的按照1G) * 倍率(GoldModifier)
    2 => 需要金币数 = 固定金币(GoldCost)
]]--
Transmogrify.RequireGold = 1;
--倍率
Transmogrify.GoldModifier = 1.0;
--固定消耗金币数
Transmogrify.GoldCost = 100000;

--[[
幻化模式:
    标准模式 = 1
        标准模式下,只有玩家拥有相应的武器或装备才能幻化.
    收集模式 = 2
        收集模式,玩家曾经拥有过的武器或装备随时都能幻化.
    体验模式 = 3
        体验模式,玩家能直接幻化游戏中任何存在的武器或者装备.
]]--
Transmogrify.Model = 2;

--收集模式下是否开启账号共享(该设置仅收集模式下生效)
Transmogrify.AccountMode = false;

--收集模式下查询玩家藏品事件更新间隔(该设置仅收集模式下生效)
--时间越短体验越友好
--1毫秒毫无必要,1秒就有很好的体验,如服务器性能不行可以视情况相应调高
--单位:毫秒 (1000毫秒 = 1秒)
Transmogrify.UpdateSkinsEventTime = 1000;

--是否开启牌子
Transmogrify.RequireToken = true;
--牌子ID
Transmogrify.TokenEntry = 49426;
--牌子数量
Transmogrify.TokenAmount = 1;

--是否允许跨甲幻化
Transmogrify.AllowMixedArmorTypes = true;
--是否允许跨武器幻化
Transmogrify.AllowMixedWeaponTypes = true;

--隐藏幻化效果
Transmogrify.HIDE_ITEM = 15;

--#######################################################
--#####         武器幻光系统功能相关设置设置         ####
--#######################################################

--幻光功能是否开启
VisualWeapon.Enable = true;

--在幻化需要消耗金币基础上幻光系统的倍率,如果1.0则和幻化消耗的金币一样
VisualWeapon.GoldModifier = 1.0;

--在幻化需要消耗牌子的基础上幻光系统的倍率,如果1.0则和幻化消耗的牌子数一样,为0则表示幻光不需要消耗牌子(如果幻化开启了需要牌子的情况下)
VisualWeapon.TokenModifier = 1.0;

--[[
幻光模式:
    拥有模式 = 1
        持有模式,玩家需要背包或者银行中拥有对应的附魔卷轴才可以使用该幻光效果.
    收集模式 = 2
        收集模式,玩家曾经获得过相应的附魔卷轴将永久可用使用该幻光效果.
    体验模式 = 3
        体验模式,玩家能直接使用所有的幻光效果.
]]--
VisualWeapon.Model = 2;

--收集模式下是否开启账号共享
--该设置仅收集模式下生效
VisualWeapon.AccountMode = false;

--如果幻光模式为<持有模式>,该设定将设置是否需要消耗该附魔卷轴,把<持有模式>转变为<消耗模式>.
-- true -> 需要消耗
-- flase -> 不需要消耗
VisualWeapon.RemoveItem = false;

--设定可使用的武器幻光效果
VisualWeapon.Data = {
-- 如果自己有新的附魔光效自己按格式填写
-- 对应关系, 物品 -> 技能效果 -> 技能misc ->SpellItemEnchantment

 -- [物品ID] = SpellItemEnchantment, 
    [Transmogrify.HIDE_ITEM] = 0, --隐藏幻光
    [38779] = 249,  --卷轴：附魔武器 - 初级屠兽
    [38796] = 943,  --卷轴：附魔双手武器 - 次级冲击
    [38813] = 853,  --卷轴：附魔武器 - 次级屠兽
    [38814] = 854,  --卷轴：附魔武器 - 次级元素杀手
    [38821] = 943,  --卷轴：附魔武器 - 攻击
    [38822] = 1897, --卷轴：附魔双手武器 - 冲击
    [38838] = 803,  --卷轴：附魔武器 - 烈焰
    [38840] = 912,  --卷轴：附魔武器 - 屠魔
    [38845] = 963,  --卷轴：附魔双手武器 - 强效冲击
    [38848] = 805,  --卷轴：附魔武器 - 强效攻击
    [38868] = 1894, --卷轴：附魔武器 - 冰寒
    [38869] = 1896, --卷轴：附魔双手武器 - 超强冲击
    [38870] = 1897, --卷轴：附魔武器 - 超强打击
    [38871] = 1898, --卷轴：附魔武器 - 生命偷取
    [38872] = 1899, --卷轴：附魔武器 - 邪恶武器
    [38873] = 1900, --卷轴：附魔武器 - 十字军
    [38874] = 1903, --卷轴：附魔双手武器 - 特效精神
    [38875] = 1904, --卷轴：附魔双手武器 - 特效智力
    [38877] = 2504, --卷轴：附魔武器 - 法术能量
    [38878] = 2505, --卷轴：附魔武器 - 治疗能量
    [38879] = 2563, --卷轴：附魔武器 - 力量
    [38880] = 2564, --卷轴：附魔武器 - 敏捷
    [38883] = 2567, --卷轴：附魔武器 - 强效精神
    [38884] = 2568, --卷轴：附魔武器 - 强效智力
    [38896] = 2646, --卷轴：附魔双手武器 - 敏捷
    [38917] = 963,  --卷轴：附魔武器 - 特效打击
    [38918] = 2666, --卷轴：附魔武器 - 特效智力
    [38919] = 2667, --卷轴：附魔双手武器 - 野蛮
    [38920] = 2668, --卷轴：附魔武器 - 力量
    [38921] = 2669, --卷轴：附魔武器 - 特效法术能量
    [38922] = 2670, --卷轴：附魔双手武器 - 特效敏捷
    [38923] = 2671, --卷轴：附魔武器 - 阳炎
    [38924] = 2672, --卷轴：附魔武器 - 魂霜
    [38925] = 2673, --卷轴：附魔武器 - 猫鼬
    [38926] = 2674, --卷轴：附魔武器 - 魔法激荡
    [38927] = 2675, --卷轴：附魔武器 - 作战专家
    [38946] = 3846, --卷轴：附魔武器 - 特效治疗
    [38947] = 3222, --卷轴：附魔武器 - 强效敏捷
    [38948] = 3225, --卷轴：附魔武器 - 斩杀
    [38963] = 3844, --卷轴：附魔武器 - 优异精神
    [38965] = 3239, --卷轴：附魔武器 - 破冰
    [38972] = 3241, --卷轴：附魔武器 - 生命护卫
    [38981] = 3247, --卷轴：附魔双手武器 - 天谴斩除
    [38988] = 3251, --卷轴：附魔武器 - 巨人杀手
    [38991] = 3830, --卷轴：附魔武器 - 优异法术能量
    [38992] = 3828, --卷轴：附魔双手武器 - 强效野蛮
    [38995] = 1103, --卷轴：附魔武器 - 优异敏捷
    [38998] = 3273, --卷轴：附魔武器 - 死亡霜冻
    [43987] = 3790, --卷轴：附魔武器 - 黑魔法
    [44453] = 1606, --卷轴：附魔武器 - 强效潜能
    [44463] = 3827, --卷轴：附魔双手武器 - 杀戮
    [44466] = 3833, --卷轴：附魔武器 - 超强潜能
    [44467] = 3834, --卷轴：附魔武器 - 极效法术能量
    [44493] = 3789, --卷轴：附魔武器 - 狂暴
    [44497] = 3788, --卷轴：附魔武器 - 精确
    [45056] = 3854, --卷轴：附魔法杖 - 强效法术能量
    [45060] = 3855, --卷轴：附魔法杖 - 法术能量
    [46026] = 3869, --卷轴：附魔武器 - 利刃防护
    [46098] = 3870, --卷轴：附魔武器 - 吸血
    
}

--#######################################################
--##                   商城功能设置                    ##
--#######################################################

--是否启用商城功能,如果关闭下面的设置也会无效
STORE.Enable = true;

--商城地址格式,%d将替代物品id
--如果一个id为123456,的商品,商城地址为http://huanhuashangcheng.com/item-123456.html
--格式则为 huanhuashangcheng.com/item-%d.html
STORE.UrlFormat = "huanhuashangcheng.com/item-%d.html";

--商城CDKey使用后获得的外观是否发放到该账户的所有角色中
STORE.CDKeyAccountShare = false;

--CDKey数据存放在哪一个数据库中?
-- 1 characters
-- 2 world
STORE.CDKeyDatabase = 1;

--是否开启CDKey生成功能?
--如果开启,则每次加载脚本(重启服务端或reload eluna)后自动补充cdk至商城表格设定的数量为止
STORE.EnableGenerateCDKey = false;

--[[
商城兑换码CDK生成规则:
使用这个脚本之前要修改下面的生成规则,否则别人生成的key有可能通过格式检查
虽然一般不会那么巧合刚刚好数据库中有对应的物品对应,改一下总没错
%l 表示小写字母           a-z
%u 表示大写字母           A-Z
%d 表示数字               0-9
%w 表示任何字母或者数字   0-9 A-Z a-z
%a 表示任何字母           A-Z a-z
]]--
STORE.CDKeyFormat = "%w%d%w%d%l%a%d%u%u%u%d%w%u%l%a%w%d%w%u%d%u%d%a%a%d%l%u%l%l%d%l%u%l%d%u%u%w%d%a%d%a%a";

--生成CDKey的输出文件目录,如不填写则仅仅写入到数据库表格中
STORE.GenerateCDKeyDir = "data\\cdkey";

--生成所有的CDKey的文件名, ""为不生成
STORE.GenerateCDKeyFileAll = "_cdk.txt";

--生成单个物品CDKey的文件名格式, ""为不生成
--{id} 物品id`
STORE.GenerateCDKeyFileFormat = "{id}.txt";


--#######################################################
--##   脚本使用到的文本内容,如果想改就自己根据情况改   ##
--#######################################################


Transmogrify.SlotNames = {
    [EQUIPMENT_SLOT_MAINHAND  ] = {"主手武器",    nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_OFFHAND   ] = {"副手",     nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_HEAD      ] = {"头盔",         nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_SHOULDERS ] = {"肩膀",    nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_BODY      ] = {"衬衣",        nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_CHEST     ] = {"胸甲",        nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_WAIST     ] = {"腰带",        nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_LEGS      ] = {"腿部",         nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_FEET      ] = {"脚",         nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_WRISTS    ] = {"护腕",       nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_HANDS     ] = {"手套",        nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_BACK      ] = {"返回",         nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_RANGED    ] = {"远程",       nil, nil, nil, nil, nil, nil, nil, nil},
    [EQUIPMENT_SLOT_TABARD    ] = {"战袍",       nil, nil, nil, nil, nil, nil, nil, nil},
}
Transmogrify.Locales = {
    {"刷新菜单", nil, nil, nil, nil, nil, nil, nil, nil},
    {"移除所有效果", nil, nil, nil, nil, nil, nil, nil, nil},
    {"你确定移除所有装备物品的幻化和幻光效果？", nil, nil, nil, nil, nil, nil, nil, nil},
    {"幻化后的装备将会绑定无法交易.\n你要继续吗?", nil, nil, nil, nil, nil, nil, nil, nil},
    {"你确定要移除的幻化部位是 %s?", nil, nil, nil, nil, nil, nil, nil, nil},
    
    {"返回..", nil, nil, nil, nil, nil, nil, nil, nil},
    {"移除幻化效果", nil, nil, nil, nil, nil, nil, nil, nil},
    {"所有装备的幻化和幻光效果已经移除", nil, nil, nil, nil, nil, nil, nil, nil},
    {"你没有装备需要幻化的装备", nil, nil, nil, nil, nil, nil, nil, nil},
    {"%s 幻化移除", nil, nil, nil, nil, nil, nil, nil, nil},
    
    {" %s 没有可移除的幻化", nil, nil, nil, nil, nil, nil, nil, nil},
    {"%s 幻化成功", nil, nil, nil, nil, nil, nil, nil, nil},
    {"你选择了一个不合适的物品.", nil, nil, nil, nil, nil, nil, nil, nil},
    {"你所选择的物品不存在.", nil, nil, nil, nil, nil, nil, nil, nil},
    {"这个位置还没有装备物品.", nil, nil, nil, nil, nil, nil, nil, nil},
    
    {"你的牌子%s不够", nil, nil, nil, nil, nil, nil, nil, nil},
    {"钱不够", nil, nil, nil, nil, nil, nil, nil, nil},
    {"上一页", nil, nil, nil, nil, nil, nil, nil, nil},
    {"下一页(%s/%s)", nil, nil, nil, nil, nil, nil, nil, nil},
    {"模糊搜索物品(可输入名字或id)", nil, nil, nil, nil, nil, nil, nil, nil},
    
    {"武器幻光", nil, nil, nil, nil, nil, nil, nil, nil},
    {"应用幻光将要消耗%s.\n你要继续吗?", nil, nil, nil, nil, nil, nil, nil, nil},
    {"应用该幻光效果%s.\n你要继续吗?", nil, nil, nil, nil, nil, nil, nil, nil},
    {"武器%s应用该幻光效果成功", nil, nil, nil, nil, nil, nil, nil, nil},
    {"移除幻光效果", nil, nil, nil, nil, nil, nil, nil, nil},
    
    {"你确定要移除幻光效果的部位是 %s?", nil, nil, nil, nil, nil, nil, nil, nil},
    {"%s 幻光效果移除成功.", nil, nil, nil, nil, nil, nil, nil, nil},
    {" %s 没有可移除的幻光效果", nil, nil, nil, nil, nil, nil, nil, nil},
    {" %s|cFFFFFF00已添加到你的幻化收藏中.|r", nil, nil, nil, nil, nil, nil, nil, nil},
    {"CDKey兑换", nil, nil, nil, nil, nil, nil, nil, nil},
    
    {"|cFFFFFF00CDKey兑换|r\n\n使用后将直接添加对应的收藏品外观至|cFFCC0000%s|r的备选物品列表中.", nil, nil, nil, nil, nil, nil, nil, nil},
    {"CDKey格式不正确,请确认输入无误后再重试.", nil, nil, nil, nil, nil, nil, nil, nil},
    {"该CDKey不存在或已被使用,请更换一个或联系管理员处理.", nil, nil, nil, nil, nil, nil, nil, nil},
    {"%s |cFF3399FF[商城]|r", nil, nil, nil, nil, nil, nil, nil, nil},
    {"|cFFCC0000兑换失败|r,该CDKey可兑换%s的外观效果.但检测到该角色或该账号的其他角色已经拥有该外观.", nil, nil, nil, nil, nil, nil, nil, nil},

    {"|cFF00FF66兑换成功|r,外观%s已经进入%s的收藏中.", nil, nil, nil, nil, nil, nil, nil, nil},
}

--#######################################################
--##  以上为全部可以修改的功能设置,下面的内容不要修改  ##
--#######################################################


return Transmogrify;