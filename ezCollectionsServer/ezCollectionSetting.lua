local ezCollections = {};

--#######################################################
--#######            幻化试衣间系统设置            ######
--#######################################################

--插件版本号,用于验证玩家客户端的版本号,一般不要改
ezCollections.SERVERVERSION = 2.2;

--插件缓存版本号,只要改动过物品的数据,需要更改这里的数值
--只要玩家的客户端里缓存的数据版本和这里不一样,就会强制给玩家更新缓存
ezCollections.CACHEVERSION = 1;

--每个插件消息列表包含的项目数,没必要不要改
--值越大消息越长,服务端需要发送的包越少,但过长的消息会让客户端无法处理
--值越小服务端需要发送的包就越多
ezCollections.MaxListCount = 50;

--开启调试模式
--true  -> 控制台显示调试信息输出
--false -> 控制台隐藏调试信息输出
ezCollections.DEBUG = false;

--开启开发者模式
--玩家游戏中开启GM模式后重载客户端(/reloadui)即可开启插件的开发者模式
--可以在相关物品商右键直接设定物品的相关属性.如商店物品等.
--该功能目前没实现,仅能查看物品额外的一些信息
--true  -> 开启开发者模式
--false -> 关闭开发者模式
ezCollections.DEVELOPERMODE = false;


--查询数据库任务表的奖励物品信息,用于给藏品加上一个任务来源的标签,类似的标签还有boss掉落,世界掉落,商人售卖等,实际没什么用,只是用来看的
--如不想启用就留空
--ezCollections.QueryQuestRewardItemText = "SELECT id, RewardItemId1, RewardItemId2, RewardItemId3, RewardItemId4, RewardChoiceItemId1, RewardChoiceItemId2, RewardChoiceItemId3, RewardChoiceItemId4, RewardChoiceItemId5, RewardChoiceItemId6 FROM quest_template";
ezCollections.QueryQuestRewardItemText = "";

--查询数据库商人的售卖物品
ezCollections.QueryNPCVendorItemText = "SELECT item FROM npc_vendor GROUP BY item";



--#######################################################
--##  以上为全部可以修改的功能设置,下面的内容不要修改  ##
--#######################################################

return ezCollections;