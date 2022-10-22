-- 仅当本地化与客户端区域设置匹配时才加载本地化
if GetLocale() ~= "zhCN" then
    return;
end

ezCollections.Encounters =
{
    [161] = "36,0,拉克佐",
    [162] = "36,0,斯尼德",
    [163] = "36,0,基尔尼格",
    [164] = "36,0,重拳先生",
    [165] = "36,0,曲奇",
    [166] = "36,0,绿皮队长",
    [167] = "36,0,艾德温·范克里夫",
    [201] = "558,0,死亡观察者希尔拉克",
    [202] = "558,0,大主教玛拉达尔",
    [203] = "557,0,潘德莫努斯",
    [204] = "557,0,塔瓦洛克",
    [205] = "557,0,节点亲王沙法尔",
    [206] = "556,0,黑暗编织者塞斯",
    [207] = "556,0,利爪之王艾吉斯",
    [208] = "555,0,赫尔默大使",
    [209] = "555,0,煽动者布莱卡特",
    [210] = "555,0,沃匹尔大师",
    [211] = "555,0,摩摩尔",
    [212] = "619,0,纳多克斯长老",
    [213] = "619,0,塔达拉姆王子",
    [214] = "619,0,耶戈达·觅影者",
    [215] = "619,0,传令官沃拉兹",
    [216] = "601,0,看门者克里克希尔",
    [217] = "601,0,哈多诺克斯",
    [218] = "601,0,阿努巴拉克",
    [219] = "48,0,加摩拉",
    [220] = "48,0,萨利维丝",
    [221] = "48,0,格里哈斯特",
    [222] = "48,0,洛古斯·杰特",
    [224] = "48,0,瑟拉吉斯",
    [225] = "48,0,暮光领主克尔里斯",
    [226] = "48,0,阿库麦尔",
    [227] = "230,0,审讯官格斯塔恩",
    [228] = "230,0,洛考尔",
    [229] = "230,0,驯犬者格雷布玛尔",
    [230] = "230,0,法则之戒",
    [231] = "230,0,控火师罗格雷恩",
    [232] = "230,0,伊森迪奥斯",
    [233] = "230,0,典狱官斯迪尔基斯",
    [234] = "230,0,弗诺斯·达克维尔",
    [235] = "230,0,贝尔加",
    [236] = "230,0,怒炉将军",
    [237] = "230,0,傀儡统帅阿格曼奇",
    [238] = "230,0,霍尔雷·黑须",
    [239] = "230,0,法拉克斯",
    [240] = "230,0,雷布里·斯库比格特",
    [241] = "230,0,普拉格",
    [242] = "230,0,弗莱拉斯大使",
    [243] = "230,0,七贤",
    [244] = "230,0,玛格姆斯",
    [245] = "230,0,达格兰·索瑞森大帝",
    [246] = "558,1,死亡观察者希尔拉克",
    [247] = "558,1,大主教玛拉达尔",
    [248] = "557,1,潘德莫努斯",
    [249] = "557,1,塔瓦洛克",
    [250] = "557,1,尤尔",
    [251] = "557,1,节点亲王沙法尔",
    [252] = "556,1,黑暗编织者塞斯",
    [253] = "556,1,安苏",
    [254] = "556,1,利爪之王艾吉斯",
    [255] = "555,1,赫尔默大使",
    [256] = "555,1,煽动者布莱卡特",
    [257] = "555,1,沃匹尔大师",
    [258] = "555,1,摩摩尔",
    [259] = "619,1,纳多克斯长老",
    [260] = "619,1,塔达拉姆王子",
    [261] = "619,1,耶戈达·觅影者",
    [262] = "619,1,埃曼尼塔",
    [263] = "619,1,传令官沃拉兹",
    [264] = "601,1,看门者克里克希尔",
    [265] = "601,1,哈多诺克斯",
    [266] = "601,1,阿努巴拉克",
    [267] = "229,0,欧莫克大王",
    [268] = "229,0,暗影猎手沃什加斯",
    [269] = "229,0,指挥官沃恩",
    [270] = "229,0,烟网蛛后",
    [271] = "229,0,乌洛克",
    [272] = "229,0,军需官兹格雷斯",
    [273] = "229,0,奴役者基兹鲁尔",
    [274] = "229,0,哈雷肯",
    [275] = "229,0,维姆萨拉克",
    [276] = "229,0,烈焰卫士艾博希尔",
    [277] = "229,0,索拉卡·火冠",
    [278] = "229,0,大酋长雷德·黑手",
    [279] = "229,0,比斯巨兽",
    [280] = "229,0,达基萨斯将军",
    [281] = "560,0,时空猎手",
    [282] = "560,1,时空猎手",
    [283] = "560,0,斯卡洛克上尉",
    [284] = "560,1,斯卡洛克上尉",
    [285] = "560,0,德拉克中尉",
    [286] = "560,1,德拉克中尉",
    [287] = "269,0,时空领主德亚",
    [288] = "269,1,时空领主德亚",
    [289] = "269,0,坦普卢斯",
    [290] = "269,1,坦普卢斯",
    [291] = "269,0,埃欧努斯",
    [292] = "269,1,埃欧努斯",
    [293] = "595,0,肉钩",
    [294] = "595,0,塑血者沙尔拉姆",
    [295] = "595,0,时光领主埃博克",
    [296] = "595,0,玛尔加尼斯",
    [297] = "595,1,肉钩",
    [298] = "595,1,塑血者沙尔拉姆",
    [299] = "595,1,时光领主埃博克",
    [300] = "595,1,玛尔加尼斯",
    [301] = "547,0,背叛者门努",
    [302] = "547,0,巨钳鲁克玛尔",
    [303] = "547,0,夸格米拉",
    [304] = "547,1,背叛者门努",
    [305] = "547,1,巨钳鲁克玛尔",
    [306] = "547,1,夸格米拉",
    [314] = "545,0,水术师瑟丝比娅",
    [315] = "545,1,水术师瑟丝比娅",
    [316] = "545,0,机械师斯蒂里格",
    [317] = "545,1,机械师斯蒂里格",
    [318] = "545,0,督军卡利瑟里斯",
    [319] = "545,1,督军卡利瑟里斯",
    [320] = "546,0,霍加尔芬",
    [321] = "546,1,霍加尔芬",
    [322] = "546,0,加兹安",
    [323] = "546,1,加兹安",
    [329] = "546,0,沼地领主穆塞雷克",
    [330] = "546,1,沼地领主穆塞雷克",
    [331] = "546,0,黑色阔步者",
    [332] = "546,1,黑色阔步者",
    [334] = "650,0,总冠军",
    [336] = "650,1,总冠军",
    [338] = "650,0,银色勇士",
    [339] = "650,1,银色勇士",
    [340] = "650,0,黑骑士",
    [341] = "650,1,黑骑士",
    [343] = "429,0,瑟雷姆·刺蹄",
    [344] = "429,0,海多斯博恩",
    [345] = "429,0,蕾瑟塔蒂丝",
    [346] = "429,0,荒野变形者奥兹恩",
    [347] = "429,0,伊琳娜·暗木",
    [348] = "429,0,卡雷迪斯镇长",
    [349] = "429,0,伊莫塔尔",
    [350] = "429,0,特迪斯·扭木",
    [361] = "429,0,托塞德林王子",
    [362] = "429,0,卫兵摩尔达",
    [363] = "429,0,践踏者克雷格",
    [364] = "429,0,卫兵芬古斯",
    [365] = "429,0,卫兵斯里基克",
    [366] = "429,0,克罗卡斯",
    [367] = "429,0,观察者克鲁什",
    [368] = "429,0,戈多克大王",
    [369] = "600,0,托尔戈",
    [370] = "600,1,托尔戈",
    [371] = "600,0,召唤者诺沃斯",
    [372] = "600,1,召唤者诺沃斯",
    [373] = "600,0,暴龙之王爵德",
    [374] = "600,1,暴龙之王爵德",
    [375] = "600,0,先知萨隆亚",
    [376] = "600,1,先知萨隆亚",
    [378] = "90,0,粘性辐射尘",
    [379] = "90,0,格鲁比斯",
    [380] = "90,0,电刑器6000型",
    [381] = "90,0,群体打击者9-60",
    [382] = "90,0,机械师瑟玛普拉格",
    [383] = "604,0,斯拉德兰",
    [384] = "604,1,斯拉德兰",
    [385] = "604,0,达卡莱巨像",
    [386] = "604,1,达卡莱巨像",
    [387] = "604,0,莫拉比",
    [388] = "604,1,莫拉比",
    [389] = "604,1,凶残的伊克",
    [390] = "604,0,迦尔达拉",
    [391] = "604,1,迦尔达拉",
    [392] = "543,0,巡视者加戈玛",
    [393] = "543,1,巡视者加戈玛",
    [394] = "543,0,无疤者奥摩尔",
    [395] = "543,1,无疤者奥摩尔",
    [396] = "543,0,传令官瓦兹德",
    [397] = "543,1,传令官瓦兹德",
    [401] = "542,0,制造者",
    [402] = "542,1,制造者",
    [403] = "542,0,布洛戈克",
    [404] = "542,1,布洛戈克",
    [405] = "542,0,击碎者克里丹",
    [406] = "542,1,击碎者克里丹",
    [407] = "540,0,高阶术士奈瑟库斯",
    [408] = "540,1,高阶术士奈瑟库斯",
    [409] = "540,1,血卫士伯鲁恩",
    [410] = "540,0,战争使者沃姆罗格",
    [411] = "540,1,战争使者沃姆罗格",
    [412] = "540,0,酋长卡加斯·刃拳",
    [413] = "540,1,酋长卡加斯·刃拳",
    [414] = "585,0,塞林·火心",
    [415] = "585,1,塞林·火心",
    [416] = "585,0,维萨鲁斯",
    [417] = "585,1,维萨鲁斯",
    [418] = "585,0,女祭司德莉希亚",
    [419] = "585,1,女祭司德莉希亚",
    [420] = "585,0,凯尔萨斯·逐日者",
    [421] = "585,1,凯尔萨斯·逐日者",
    [422] = "349,0,诺克赛恩",
    [423] = "349,0,锐刺鞭笞者",
    [424] = "349,0,维利塔恩",
    [425] = "349,0,被诅咒的塞雷布拉斯",
    [426] = "349,0,兰斯利德",
    [427] = "349,0,工匠吉兹洛克",
    [428] = "349,0,洛特格里普",
    [429] = "349,0,瑟莱德丝公主",
    [430] = "389,0,奥格弗林特 ",
    [431] = "389,0,饥饿者塔拉加曼",
    [432] = "389,0,祈求者耶戈什",
    [433] = "389,0,巴扎兰",
    [434] = "129,0,图特卡什",
    [435] = "129,0,火眼莫德雷斯",
    [436] = "129,0,暴食者",
    [437] = "129,0,寒冰之王亚门纳尔",
    [438] = "47,0,鲁古格",
    [439] = "47,0,阿格姆",
    [440] = "47,0,亡语者贾格巴",
    [441] = "47,0,主宰拉姆塔斯",
    [443] = "47,0,卡尔加·刺肋",
    [444] = "189,0,审讯员韦沙斯",
    [445] = "189,0,血法师萨尔诺斯",
    [446] = "189,0,驯犬者洛克希",
    [447] = "189,0,奥法师杜安",
    [448] = "189,0,赫洛德",
    [449] = "189,0,大检察官法尔班克斯",
    [450] = "189,0,大检察官怀特迈恩",
    [451] = "289,0,传令官基尔图诺斯",
    [452] = "289,0,詹迪斯·巴罗夫",
    [453] = "289,0,血骨傀儡",
    [454] = "289,0,马杜克·布莱克波尔",
    [455] = "289,0,维克图斯",
    [456] = "289,0,莱斯·霜语",
    [457] = "289,0,讲师玛丽希亚",
    [458] = "289,0,瑟尔林·卡斯迪诺夫教授",
    [459] = "289,0,博学者普克尔特",
    [460] = "289,0,拉文尼亚",
    [461] = "289,0,阿雷克斯·巴罗夫领主",
    [462] = "289,0,伊露希亚·巴罗夫",
    [463] = "289,0,黑暗院长加丁",
    [464] = "33,0,雷希戈尔",
    [465] = "33,0,屠夫拉佐克劳",
    [466] = "33,0,席瓦莱恩男爵",
    [467] = "33,0,指挥官斯普林瓦尔",
    [468] = "33,0,盲眼守卫奥杜",
    [469] = "33,0,吞噬者芬鲁斯",
    [470] = "33,0,狼王南杜斯",
    [471] = "33,0,大法师阿鲁高",
    [472] = "329,0,不可宽恕者",
    [473] = "329,0,弗雷斯特恩",
    [474] = "329,0,悲惨的提米",
    [475] = "329,0,希望破坏者威利",
    [476] = "329,0,指挥官玛洛尔",
    [477] = "329,0,档案管理员加尔福特",
    [478] = "329,0,巴纳扎尔",
    [479] = "329,0,安娜丝塔丽男爵夫人",
    [480] = "329,0,奈鲁布恩坎",
    [481] = "329,0,苍白的玛勒基",
    [482] = "329,0,巴瑟拉斯镇长",
    [483] = "329,0,Ramnstein the Gorger",
    [484] = "329,0,瑞文戴尔男爵",
    [485] = "109,0,阿塔拉利恩",
    [486] = "109,0,德姆塞卡尔",
    [487] = "109,0,德拉维沃尔",
    [488] = "109,0,预言者迦玛兰",
    [490] = "109,0,摩弗拉斯",
    [491] = "109,0,哈扎斯",
    [492] = "109,0,哈卡的化身",
    [493] = "109,0,伊兰尼库斯的阴影",
    [494] = "552,0,自由的瑟雷凯斯",
    [495] = "552,1,自由的瑟雷凯斯",
    [496] = "552,0,末日预言者达尔莉安",
    [497] = "552,1,末日预言者达尔莉安",
    [498] = "552,0,天怒预言者苏克拉底",
    [499] = "552,1,天怒预言者苏克拉底",
    [500] = "552,0,预言者斯克瑞斯",
    [501] = "552,1,预言者斯克瑞斯",
    [502] = "553,0,指挥官萨拉妮丝",
    [504] = "553,1,指挥官萨拉妮丝",
    [505] = "553,0,高级植物学家弗雷温",
    [506] = "553,1,高级植物学家弗雷温",
    [507] = "553,0,看管者索恩格林",
    [508] = "553,1,看管者索恩格林",
    [509] = "553,0,拉伊",
    [510] = "553,1,拉伊",
    [511] = "553,0,迁跃扭木",
    [512] = "553,1,迁跃扭木",
    [513] = "554,0,机械领主卡帕西图斯",
    [514] = "554,1,机械领主卡帕西图斯",
    [515] = "554,0,灵术师塞比瑟蕾",
    [516] = "554,1,灵术师塞比瑟蕾",
    [517] = "554,0,计算者帕萨雷恩",
    [518] = "554,1,计算者帕萨雷恩",
    [519] = "576,1,Frozen Commander",
    [520] = "576,0,大魔导师泰蕾丝塔",
    [521] = "576,1,大魔导师泰蕾丝塔",
    [522] = "576,0,阿诺玛鲁斯",
    [523] = "576,1,阿诺玛鲁斯",
    [524] = "576,0,塑树者奥莫洛克",
    [525] = "576,1,塑树者奥莫洛克",
    [526] = "576,0,克莉斯塔萨",
    [527] = "576,1,克莉斯塔萨",
    [528] = "578,0,审讯者达库斯",
    [529] = "578,1,审讯者达库斯",
    [530] = "578,0,瓦尔洛斯·云击",
    [531] = "578,1,瓦尔洛斯·云击",
    [532] = "578,0,法师领主伊洛姆",
    [533] = "578,1,法师领主伊洛姆",
    [534] = "578,0,魔网守护者埃雷苟斯",
    [535] = "578,1,魔网守护者埃雷苟斯",
    [536] = "34,0,可怕的塔格尔",
    [537] = "34,0,卡姆·深怒",
    [538] = "34,0,哈姆霍克",
    [539] = "34,0,巴基尔·斯瑞德",
    [540] = "34,0,迪克斯特·瓦德",
    [541] = "608,0,First Prisoner",
    [542] = "608,1,First Prisoner",
    [543] = "608,0,Second Prisoner",
    [544] = "608,1,Second Prisoner",
    [545] = "608,0,塞安妮苟萨",
    [546] = "608,1,塞安妮苟萨",
    [547] = "70,0,鲁维罗什",
    [548] = "70,0,失踪的矮人",
    [549] = "70,0,艾隆纳亚",
    [551] = "70,0,远古巨石卫士",
    [552] = "70,0,加加恩·火锤",
    [553] = "70,0,格瑞姆洛克",
    [554] = "70,0,阿扎达斯",
    [555] = "602,0,比亚格里将军",
    [556] = "602,1,比亚格里将军",
    [557] = "602,0,沃尔坎",
    [558] = "602,1,沃尔坎",
    [559] = "602,0,艾欧纳尔",
    [560] = "602,1,艾欧纳尔",
    [561] = "602,0,洛肯",
    [562] = "602,1,洛肯",
    [563] = "599,0,克莱斯塔卢斯",
    [564] = "599,1,克莱斯塔卢斯",
    [565] = "599,0,悲伤圣女",
    [566] = "599,1,悲伤圣女",
    [567] = "599,0,Tribunal of Ages",
    [568] = "599,1,Tribunal of Ages",
    [569] = "599,0,塑铁者斯约尼尔",
    [570] = "599,1,塑铁者斯约尼尔",
    [571] = "574,0,凯雷塞斯王子",
    [572] = "574,1,凯雷塞斯王子",
    [573] = "574,0,Skarvold & Dalronn",
    [574] = "574,1,Skarvold & Dalronn",
    [575] = "574,0,掠夺者因格瓦尔",
    [576] = "574,1,掠夺者因格瓦尔",
    [577] = "575,0,席瓦拉·索格蕾",
    [578] = "575,1,席瓦拉·索格蕾",
    [579] = "575,0,戈托克·苍蹄",
    [580] = "575,1,戈托克·苍蹄",
    [581] = "575,0,残忍的斯卡迪",
    [582] = "575,1,残忍的斯卡迪",
    [583] = "575,0,伊米隆国王",
    [584] = "575,1,伊米隆国王",
    [585] = "43,0,安娜科德拉",
    [586] = "43,0,考布莱恩",
    [587] = "43,0,克雷什",
    [588] = "43,0,皮萨斯",
    [589] = "43,0,斯卡姆",
    [590] = "43,0,瑟芬迪斯",
    [591] = "43,0,永生者沃尔丹",
    [592] = "43,0,吞噬者穆坦努斯",
    [593] = "209,0,水占师维蕾萨",
    [594] = "209,0,Ghaz'rilla",
    [595] = "209,0,安图苏尔",
    [596] = "209,0,殉教者塞卡",
    [597] = "209,0,巫医祖穆拉恩",
    [598] = "209,0,耐克鲁姆",
    [599] = "209,0,暗影祭司塞瑟斯",
    [600] = "209,0,乌克兹·沙顶",
    [601] = "564,0,高阶督军纳因图斯",
    [602] = "564,0,苏普雷姆斯",
    [603] = "564,0,阿卡玛之影",
    [604] = "564,0,塔隆·血魔",
    [605] = "564,0,古尔图格·血沸",
    [606] = "564,0,圣骨匣的灵魂",
    [607] = "564,0,莎赫拉丝主母",
    [608] = "564,0,The Illidari Council",
    [609] = "564,0,伊利丹·怒风",
    [610] = "469,0,狂野的拉佐格尔",
    [611] = "469,0,堕落的瓦拉斯塔兹",
    [612] = "469,0,勒什雷尔",
    [613] = "469,0,费尔默",
    [614] = "469,0,埃博诺克",
    [615] = "469,0,弗莱格尔",
    [616] = "469,0,克洛玛古斯",
    [617] = "469,0,奈法利安",
    [618] = "534,0,雷基·冬寒",
    [619] = "534,0,安纳塞隆",
    [620] = "534,0,卡兹洛加",
    [621] = "534,0,阿兹加洛",
    [622] = "534,0,阿克蒙德",
    [623] = "548,0,不稳定的海度斯",
    [624] = "548,0,鱼斯拉",
    [625] = "548,0,盲眼者莱欧瑟拉斯",
    [626] = "548,0,深水领主卡拉瑟雷斯",
    [627] = "548,0,莫洛格里·踏潮者",
    [628] = "548,0,瓦丝琪",
    [629] = "649,0,诺森德猛兽",
    [630] = "649,1,诺森德猛兽",
    [631] = "649,2,诺森德猛兽",
    [632] = "649,3,诺森德猛兽",
    [633] = "649,0,加拉克苏斯大王",
    [634] = "649,1,加拉克苏斯大王",
    [635] = "649,2,加拉克苏斯大王",
    [636] = "649,3,加拉克苏斯大王",
    [637] = "649,0,阵营冠军",
    [638] = "649,1,阵营冠军",
    [639] = "649,2,阵营冠军",
    [640] = "649,3,阵营冠军",
    [641] = "649,0,瓦格里双子",
    [642] = "649,1,瓦格里双子",
    [643] = "649,2,瓦格里双子",
    [644] = "649,3,瓦格里双子",
    [645] = "649,0,阿努巴拉克",
    [646] = "649,1,阿努巴拉克",
    [647] = "649,2,阿努巴拉克",
    [648] = "649,3,阿努巴拉克",
    [649] = "565,0,莫加尔大王",
    [650] = "565,0,屠龙者格鲁尔",
    [651] = "544,0,玛瑟里顿",
    [652] = "532,0,猎手阿图门",
    [653] = "532,0,莫罗斯",
    [654] = "532,0,贞节圣女",
    [655] = "532,0,Opera Event",
    [656] = "532,0,馆长",
    [657] = "532,0,特雷斯坦·邪蹄",
    [658] = "532,0,埃兰之影",
    [659] = "532,0,虚空幽龙",
    [660] = "532,0,Chess Event",
    [661] = "532,0,玛克扎尔王子",
    [662] = "532,0,夜之魇",
    [663] = "409,0,鲁西弗隆",
    [664] = "409,0,玛格曼达",
    [665] = "409,0,基赫纳斯",
    [666] = "409,0,加尔",
    [667] = "409,0,沙斯拉尔",
    [668] = "409,0,迦顿男爵",
    [669] = "409,0,萨弗隆先驱者",
    [670] = "409,0,焚化者古雷曼格",
    [671] = "409,0,管理者埃克索图斯",
    [672] = "409,0,拉格纳罗斯",
    [673] = "533,0,阿努布雷坎",
    [674] = "533,1,阿努布雷坎",
    [677] = "533,0,黑女巫法琳娜",
    [678] = "533,1,黑女巫法琳娜",
    [679] = "533,0,迈克斯纳",
    [680] = "533,1,迈克斯纳",
    [681] = "533,0,药剂师诺斯",
    [682] = "533,1,药剂师诺斯",
    [683] = "533,0,肮脏的希尔盖",
    [684] = "533,1,肮脏的希尔盖 ",
    [685] = "533,0,洛欧塞布",
    [686] = "533,1,洛欧塞布",
    [687] = "533,0,教官拉苏维奥斯",
    [689] = "533,1,教官拉苏维奥斯",
    [690] = "533,0,收割者戈提克",
    [691] = "533,1,收割者戈提克",
    [692] = "533,0,The Four Horsemen",
    [693] = "533,1,The Four Horsemen",
    [694] = "533,0,帕奇维克",
    [695] = "533,1,帕奇维克 ",
    [696] = "533,0,格罗布鲁斯",
    [697] = "533,1,格罗布鲁斯",
    [698] = "533,0,格拉斯",
    [699] = "533,1,格拉斯",
    [700] = "533,0,塔迪乌斯",
    [701] = "533,1,塔迪乌斯",
    [702] = "533,0,萨菲隆",
    [703] = "533,1,萨菲隆",
    [704] = "533,0,克尔苏加德",
    [706] = "533,1,克尔苏加德",
    [707] = "249,0,奥妮克希亚",
    [708] = "249,1,奥妮克希亚",
    [709] = "531,0,预言者斯克拉姆",
    [710] = "531,0,Silithid Royalty",
    [711] = "531,0,沙尔图拉",
    [712] = "531,0,顽强的范克瑞斯",
    [713] = "531,0,维希度斯",
    [714] = "531,0,哈霍兰公主",
    [715] = "531,0,Twin Emperors",
    [716] = "531,0,奥罗",
    [717] = "531,0,克苏恩",
    [718] = "509,0,库林纳克斯",
    [719] = "509,0,拉贾克斯将军",
    [720] = "509,0,莫阿姆",
    [721] = "509,0,吞咽者布鲁",
    [722] = "509,0,狩猎者阿亚米斯",
    [723] = "509,0,无疤者奥斯里安",
    [724] = "580,0,卡雷苟斯",
    [725] = "580,0,布鲁塔卢斯",
    [726] = "580,0,Felmyst",
    [727] = "580,0,Eredar Twins",
    [728] = "580,0,穆鲁",
    [729] = "580,0,基尔加丹",
    [730] = "550,0,奥",
    [731] = "550,0,空灵机甲",
    [732] = "550,0,大星术师索兰莉安",
    [733] = "550,0,凯尔萨斯·逐日者",
    [734] = "616,0,玛里苟斯",
    [735] = "616,1,玛里苟斯",
    [736] = "615,0,塔尼布隆",
    [737] = "615,1,塔尼布隆",
    [738] = "615,0,沙德隆",
    [739] = "615,1,沙德隆",
    [740] = "615,0,维斯匹隆",
    [741] = "615,1,维斯匹隆",
    [742] = "615,0,萨塔里奥",
    [743] = "615,1,萨塔里奥",
    [744] = "603,0,烈焰巨兽",
    [745] = "603,0,掌炉者伊格尼斯",
    [746] = "603,0,锋鳞",
    [747] = "603,0,XT-002拆解者",
    [748] = "603,0,The Iron Council",
    [749] = "603,0,科隆加恩",
    [750] = "603,0,欧尔莉亚",
    [751] = "603,0,霍迪尔",
    [752] = "603,0,托里姆",
    [753] = "603,0,弗蕾亚",
    [754] = "603,0,米米尔隆",
    [755] = "603,0,维扎克斯将军",
    [756] = "603,0,尤格-萨隆",
    [757] = "603,0,观察者奥尔加隆",
    [758] = "603,1,烈焰巨兽",
    [759] = "603,1,掌炉者伊格尼斯",
    [760] = "603,1,锋鳞",
    [761] = "603,1,XT-002拆解者",
    [762] = "603,1,The Iron Council",
    [763] = "603,1,科隆加恩",
    [764] = "603,1,欧尔莉亚",
    [765] = "603,1,霍迪尔",
    [766] = "603,1,托里姆",
    [767] = "603,1,弗蕾亚",
    [768] = "603,1,米米尔隆",
    [769] = "603,1,维扎克斯将军",
    [770] = "603,1,尤格-萨隆",
    [771] = "603,1,观察者奥尔加隆",
    [772] = "624,0,岩石看守者阿尔卡冯",
    [773] = "624,1,岩石看守者阿尔卡冯",
    [774] = "624,0,风暴看守者埃玛尔隆",
    [775] = "624,1,风暴看守者埃玛尔隆",
    [776] = "624,0,火焰看守者科拉隆",
    [777] = "624,1,火焰看守者科拉隆",
    [778] = "568,0,埃基尔松",
    [779] = "568,0,纳洛拉克",
    [780] = "568,0,加亚莱",
    [781] = "568,0,哈尔拉兹",
    [782] = "568,0,妖术领主玛拉卡斯",
    [783] = "568,0,祖尔金",
    [784] = "309,0,高阶祭司温诺希斯",
    [785] = "309,0,高阶祭司耶克里克",
    [786] = "309,0,高阶祭司玛尔里",
    [787] = "309,0,血领主曼多基尔",
    [788] = "309,0,Edge of Madness",
    [789] = "309,0,高阶祭司塞卡尔",
    [790] = "309,0,加兹兰卡",
    [791] = "309,0,高阶祭司娅尔罗",
    [792] = "309,0,妖术师金度",
    [793] = "309,0,哈卡",
    [829] = "632,0,布隆亚姆",
    [830] = "632,1,布隆亚姆 ",
    [831] = "632,0,噬魂者",
    [832] = "632,1,噬魂者",
    [833] = "658,0,熔炉之主加弗斯特",
    [834] = "658,1,熔炉之主加弗斯特",
    [835] = "658,0,科瑞克",
    [836] = "658,1,科瑞克",
    [837] = "658,0,Overlrod Tyrannus",
    [838] = "658,1,Overlrod Tyrannus",
    [839] = "668,0,玛维恩",
    [840] = "668,1,玛维恩",
    [841] = "668,0,法瑞克",
    [842] = "668,1,法瑞克",
    [843] = "668,0,Escaped from Arthas",
    [844] = "668,1,Escaped from Arthas",
    [845] = "631,0,玛洛加尔领主",
    [846] = "631,0,亡语者女士",
    [847] = "631,0,炮舰战斗",
    [848] = "631,0,死亡使者萨鲁法尔",
    [849] = "631,0,烂肠",
    [850] = "631,0,腐面",
    [851] = "631,0,普崔塞德教授",
    [852] = "631,0,鲜血王子议会",
    [853] = "631,0,鲜血女王兰娜瑟尔",
    [854] = "631,0,踏梦者瓦莉瑟瑞娅",
    [855] = "631,0,辛达苟萨",
    [856] = "631,0,巫妖王",
    [857] = "631,1,玛洛加尔领主",
    [858] = "631,1,亡语者女士",
    [859] = "631,1,炮舰战斗",
    [860] = "631,1,死亡使者萨鲁法尔",
    [861] = "631,1,烂肠",
    [862] = "631,1,腐面",
    [863] = "631,1,普崔塞德教授",
    [864] = "631,1,鲜血王子议会",
    [865] = "631,1,鲜血女王兰娜瑟尔",
    [866] = "631,1,踏梦者瓦莉瑟瑞娅",
    [867] = "631,1,辛达苟萨",
    [868] = "631,1,巫妖王",
    [883] = "47,0,暴怒的阿迦赛罗斯",
    [885] = "624,0,寒冰看守者图拉旺",
    [886] = "624,1,寒冰看守者图拉旺",
    [887] = "724,0,海里昂",
    [888] = "724,1,海里昂",
    [889] = "724,1,战争之子巴尔萨鲁斯",
    [890] = "724,0,战争之子巴尔萨鲁斯",
    [891] = "724,0,塞维娅娜·怒火",
    [892] = "724,1,塞维娅娜·怒火",
    [893] = "724,0,萨瑞瑟里安将军",
    [894] = "724,1,萨瑞瑟里安将军",
};
