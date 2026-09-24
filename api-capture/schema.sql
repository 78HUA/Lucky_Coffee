-- ============================================================
--  Lucky Coffee 教学 API —— 数据库结构 + 初始化数据
--  数据来源: https://kf.webxyq.com
--  抓取时间: 2026-09-15 21:41:18
--  说明: 表结构由真实接口返回数据反推;字段命名保持与接口一致
-- ============================================================

SET NAMES utf8mb4;

-- ------------------------------------------------------------
-- 1. banner 轮播图
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `banner`;
CREATE TABLE `banner` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  `banner_img` VARCHAR(512) NOT NULL COMMENT '轮播图地址',
  `name`       VARCHAR(128) NOT NULL COMMENT '商品名称',
  `pid`        VARCHAR(64)  NOT NULL COMMENT '关联商品 pid',
  `sort_order` INT          NOT NULL DEFAULT 0 COMMENT '排序(接口未返回,预留)',
  PRIMARY KEY (`id`),
  KEY `idx_banner_pid` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='首页轮播图';

INSERT INTO `banner` (`banner_img`, `name`, `pid`, `sort_order`) VALUES
  ('https://kf.webxyq.com/images/product_large/IMG_0389_02.jpg', '卡布奇诺瑞纳冰', 'rena_ice003', 0),
  ('https://kf.webxyq.com/images/product_large/IMG_0388_02.jpg', '抹茶瑞纳冰', 'rena_ice002', 1),
  ('https://kf.webxyq.com/images/product_large/IMG_0380_02.jpg', '标准美式', 'coffee001', 2),
  ('https://kf.webxyq.com/images/product_large/IMG_0382_02.jpg', '摩卡', 'coffee003', 3);

-- ------------------------------------------------------------
-- 2. product_type 商品分类
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `product_type`;
CREATE TABLE `product_type` (
  `id`         BIGINT       NOT NULL COMMENT '主键(接口返回真实 id)',
  `type`       VARCHAR(64)  NOT NULL COMMENT '分类标识,如 latte/coffee',
  `type_desc`  VARCHAR(64)  NOT NULL COMMENT '分类中文名',
  `created_at` DATETIME     NULL,
  `updated_at` DATETIME     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_type` (`type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品分类';

INSERT INTO `product_type` (`id`, `type`, `type_desc`, `created_at`, `updated_at`) VALUES
  (1, 'latte', '拿铁', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (2, 'coffee', '咖啡', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (3, 'rena_ice', '瑞纳冰', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (4, 'fruit_tea', '水果茶', '2026-08-30 08:15:38', '2026-08-30 08:15:38');

-- ------------------------------------------------------------
-- 3. product 商品
--    注意: `desc` 是 MySQL 保留字,必须用反引号
--    注意: 列表接口返回 smallImg/largeImg/isHot/typeDesc(小驼峰)
--          详情接口额外返回 tem/milk/sugar/cream 四个客制化维度
-- ------------------------------------------------------------
DROP TABLE IF EXISTS `product`;
CREATE TABLE `product` (
  `id`         BIGINT       NOT NULL COMMENT '主键(接口返回真实 id)',
  `pid`        VARCHAR(64)  NOT NULL COMMENT '商品业务 ID,如 coffee001',
  `type`       VARCHAR(64)  NOT NULL COMMENT '所属分类标识',
  `name`       VARCHAR(128) NOT NULL COMMENT '商品名',
  `enname`     VARCHAR(128) NULL COMMENT '英文名',
  `price`      DECIMAL(10,2) NOT NULL COMMENT '价格(接口返回字符串)',
  `desc`       TEXT         NULL COMMENT '商品描述',
  `small_img`  VARCHAR(512) NULL COMMENT '小图',
  `large_img`  VARCHAR(512) NULL COMMENT '大图',
  `is_hot`     TINYINT      NOT NULL DEFAULT 0 COMMENT '是否热门 1/0',
  `type_desc`  VARCHAR(64)  NULL COMMENT '分类中文名(冗余)',
  `tem`        VARCHAR(64)  NULL COMMENT '温度选项,如 冷/热',
  `tem_desc`   VARCHAR(32)  NULL COMMENT '温度标签',
  `milk`       VARCHAR(128) NULL COMMENT '奶选项',
  `milk_desc`  VARCHAR(32)  NULL COMMENT '奶标签',
  `sugar`      VARCHAR(128) NULL COMMENT '糖选项',
  `sugar_desc` VARCHAR(32)  NULL COMMENT '糖标签',
  `cream`      VARCHAR(128) NULL COMMENT '奶油选项',
  `cream_desc` VARCHAR(32)  NULL COMMENT '奶油标签',
  `created_at` DATETIME     NULL,
  `updated_at` DATETIME     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_pid` (`pid`),
  KEY `idx_product_type` (`type`),
  KEY `idx_product_hot` (`is_hot`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='商品';

INSERT INTO `product` (`id`,`pid`,`type`,`name`,`enname`,`price`,`desc`,`small_img`,`large_img`,`is_hot`,`type_desc`,`tem`,`tem_desc`,`milk`,`milk_desc`,`sugar`,`sugar_desc`,`cream`,`cream_desc`,`created_at`,`updated_at`) VALUES
  (2, 'coffee001', 'coffee', '标准美式', 'Americano', '22.00', 'Espresso（意式浓缩）与水的黄金配比，带来浓郁的咖啡芬芳，成为脑海中挥之不去的绝妙体验。\n主要原材料：浓缩咖啡，水。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0380_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0380_02.jpg', 0, '咖啡', '冷/热', '温度', '', '奶', '无糖/半份糖/单份糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (4, 'coffee002', 'coffee', '焦糖玛奇朵', 'Caramel Macchiato', '28.00', '焦糖风味奶咖，上层注入丰富奶泡，层次感分明。（建议到店饮用）\n主要原材料：浓缩咖啡，牛奶，香草风味糖浆，焦糖调味酱。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0381_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0381_02.jpg', 0, '咖啡', '冷/热', '温度', '', '奶', '全糖/半糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (3, 'coffee003', 'coffee', '摩卡', 'Mocha', '28.00', '浓缩咖啡与牛奶彼此融合，加入香浓巧克力风味。（建议到店饮用，奶油融化前口感更佳）\n主要原材料：浓缩咖啡，牛奶，巧克力酱，搅打奶油（含香草风味糖浆）。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0382_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0382_02.jpg', 0, '咖啡', '冷/热', '温度', '', '奶', '全糖/半糖', '糖', '默认奶油/无奶油', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (10, 'coffee004', 'coffee', '卡布奇诺', 'Cappuccino', '25.00', '经典奶咖。奶泡与咖啡交融，绵密醇香，轻盈如雪。（建议到店饮用，奶泡消失前口感更佳）\n主要原材料：浓缩咖啡，牛奶。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0386_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0386_02.jpg', 0, '咖啡', '冷/热', '温度', '', '奶', '无糖/半份糖/单份糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (14, 'coffee005', 'coffee', '焦糖标准美式', 'Caramel Americano', '25.00', '焦糖风味糖浆的融入，提升了美式的原始风味，入口清甜，香气四溢。\n主要原材料：浓缩咖啡，水，焦糖风味糖浆。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0391_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0391_02.jpg', 0, '咖啡', '热', '温度', '无奶/单份奶/双份奶', '奶', '全糖/半糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (13, 'coffee006', 'coffee', '奥瑞白', 'Flat White', '28.00', '咖啡与牛奶黄金配比，奶香四溢，口感香醇。\n主要原材料：浓缩咖啡，牛奶。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0390_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0390_02.jpg', 1, '咖啡', '热', '温度', '', '奶', '无糖/半份糖/单份糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (22, 'coffee008', 'coffee', '甜美焦糖冰咖啡', 'Sweet caramel iced coffee', '24.00', '美味饮品，享受美妙的意式浓缩咖啡时刻！主要原料：1个 Caramelito 优选咖啡胶囊、1勺焦糖冰淇淋、咸焦糖糖浆、100毫升香草味牛奶、碎冰。\n图片及包装仅供参考，请以实物为准。建议送达后尽快饮用。到店饮用口感更佳。', 'https://kf.webxyq.com/images/product_small/j001_small.png', 'https://kf.webxyq.com/images/product_large/j001.jpg', 0, '咖啡', '热', '温度', '', '奶', '无糖/半份糖/单份糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (18, 'fruit_tea001', 'fruit_tea', '满杯百香果', 'Passion Fruit & Coconut Jelly Jasmine Tea', '17.00', '清新又浓郁的百香果香气，混合清新茉莉茶香，加上椰果与寒天的爽滑Q弹，满杯椰香果香茶香。\n主要原材料：椰果、百香果汁、原味寒天晶球、茉莉绿茶、原味调味糖浆。\n图片仅供参考，请以实物为准，建议取餐后尽快饮用。', 'https://kf.webxyq.com/images/product_small/d001_small.png', 'https://kf.webxyq.com/images/product_large/d001.png', 1, '水果茶', '冰', '温度', '', '奶', '标准/半糖/0卡糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (19, 'fruit_tea002', 'fruit_tea', '草莓酸饮', 'Strawberry sour drink', '19.00', '草莓和椰果的酸甜搭配，混合醇香牛奶与清新优格，交织出Q滑细腻的口感，莓香四溢很好喝。（饮用前建议搅拌）\n主要原材料：牛奶、草莓汁饮料浓浆、椰果、风味酸奶。\n图片仅供参考，请以实物为准，建议取餐后尽快饮用。', 'https://kf.webxyq.com/images/product_small/e001_small.png', 'https://kf.webxyq.com/images/product_large/e001.png', 0, '水果茶', '冰', '温度', '', '奶', '标准/半糖/0卡糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (20, 'fruit_tea005', 'fruit_tea', '椰子冰', 'Coconut ice', '20.00', '【不含咖啡】优选纯牛奶为底，融进满满椰香，又加入柔和香草风味，椰子控必喝。\n主要原料：纯牛奶、椰子风味粉、香草风味糖浆、原味冰沙粉、冰块、稀奶油（含香草风味糖浆）。\n图片及包装仅供参考，请以实物为准。温馨提示：瑞纳冰系列产品形态为冰沙，无法进行少冰去冰操作，请您谅解。建议送达后尽快饮用。到店饮用口感更佳。 ', 'https://kf.webxyq.com/images/product_small/h001_small.png', 'https://kf.webxyq.com/images/product_large/h001.png', 1, '水果茶', '冰', '温度', '', '奶', '', '糖', '默认奶油/无奶油', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (1, 'latte001', 'latte', '黑糖拿铁', 'Brown Sugar Latte', '28.00', '经典日式黑糖风味拿铁，黑糖与咖啡的美妙融合，香甜温暖、自然醇厚，口感绵长。（建议到店饮用，奶油融化前口感更佳）\n 主要原材料：浓缩咖啡、牛奶、黑糖调味糖浆、原味调味糖浆、可选择添加搅打奶油（含香草风味糖浆）\n 图片仅供参考，请以实物为准，建议取餐后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0378_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0378_02.jpg', 0, '拿铁', '冷/热', '温度', '', '奶', '全糖/半糖', '糖', '默认奶油/无奶油', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (5, 'latte002', 'latte', '香草拿铁', 'Vanilla Latte', '28.00', '拿铁中融入清新香草风味，沁人心脾。\n主要原材料：浓缩咖啡，牛奶，香草风味糖浆。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0379_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0379_02.jpg', 0, '拿铁', '冷/热', '温度', '', '奶', '全糖/半糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (6, 'latte003', 'latte', '拿铁', 'Latte', '25.00', '经典意式奶咖。浓缩咖啡与香醇牛奶融合，口感圆润。\n主要原材料：浓缩咖啡，牛奶。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0383_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0383_02.jpg', 0, '拿铁', '冷/热', '温度', '', '奶', '全糖/半糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (7, 'latte004', 'coffee', '焦糖拿铁', 'Caramel Latte', '28.00', '拿铁中融入醇香焦糖风味，香甜温暖，令人沉醉。\n主要原材料：浓缩咖啡，牛奶，焦糖风味糖浆。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0384_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0384_02.jpg', 1, '拿铁', '冷/热', '温度', '', '奶', '全糖/半糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (8, 'latte005', 'coffee', '榛果拿铁', 'Hazelnut Latte', '28.00', '榛果爱好者的选择！香甜榛果风味与咖啡牛奶融合，诠释另一种新鲜风味。\n主要原材料：浓缩咖啡，牛奶，榛子风味糖浆。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0385_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0385_02.jpg', 1, '拿铁', '冷/热', '温度', '', '奶', '全糖/半糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (15, 'latte006', 'latte', '黑糖啵啵拿铁', 'Brown Sugar Bubble Latte', '28.00', '独特的黑糖风味拿铁，佐以Q嫩儒糯的黑糖口味珍珠，创造出层次丰富的美妙口感。（建议搅拌后饮用）\n主要原材料：浓缩咖啡，黑糖味珍珠，纯牛奶，黑糖味调味糖浆，原味调味糖浆，可选择添加搅打奶油（含香草风味糖浆）\n图片仅供参考，请以实物为准，建议取餐后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0392_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0392_02.jpg', 1, '拿铁', '冷/热', '温度', '', '奶', '全糖/半糖', '糖', '默认奶油/无奶油', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (16, 'latte007', 'latte', '元气厚乳拿铁', 'Walnut Flavored Newer Latte', '21.00', '【新年第一杯，元气开场】香浓核桃风味×酥脆坚果碎稀奶油顶，给你加个元气buff！\n以luckin经典厚乳拿铁为底，新年要有新风味~特添精选厚乳，采用先进冷萃工艺，乳蛋白含量6%。\n主要原料：浓缩咖啡、冷萃厚牛乳（调制奶浆）、纯牛奶、胡桃风味糖浆、糖衣扁桃仁碎、稀奶油（含香草味糖浆）。\n图片及包装仅供参考，请以实物为准。建议送达后尽快饮用。到店饮用口感更佳。', 'https://kf.webxyq.com/images/product_small/b001_small.jpg', 'https://kf.webxyq.com/images/product_large/b001.jpg', 0, '拿铁', '冰/热', '温度', '', '奶', '标准糖/半糖', '糖', '默认奶油/无奶油', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (17, 'latte008', 'latte', '海盐芝士厚乳拿铁', 'Salty Cheese Newer Latte', '18.00', '【特添精选厚乳，采用先进冷萃工艺，乳蛋白含量6%】悉心拼配滑润醇香的厚乳拿铁，缓缓浇入轻盈绵密的海盐芝士奶盖，更添美妙风味。\n主要原料：浓缩咖啡、冷萃厚牛乳（调制奶浆）、纯牛奶、原味调味糖浆、海盐芝士奶盖风味固体饮料、稀奶油。\n图片及包装仅供参考，请以实物为准。建议送达后尽快饮用。到店饮用口感更佳。\n致敏物质：本产品含有乳及乳制品、大豆制品，对此有过敏历史的小伙伴注意哦～', 'https://kf.webxyq.com/images/product_small/c001_small.jpg', 'https://kf.webxyq.com/images/product_large/c001.jpg', 0, '拿铁', '冰/热', '温度', '', '奶', '标准糖/半糖/无糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (21, 'latte009', 'latte', '茴香拿铁', 'Anise latte', '22.00', '平滑、香甜、细致的花香，这款诱人的拿铁咖啡定会愉悦您的味蕾，活跃您的感官。主要原料：1颗 Master Origin Ethiopia 优选咖啡、250毫升牛奶、20毫升大茴香糖浆、绿茉莉花茶包、大茴香瓣。\n图片及包装仅供参考，请以实物为准。建议送达后尽快饮用。到店饮用口感更佳。', 'https://kf.webxyq.com/images/product_small/i001_small.png', 'https://kf.webxyq.com/images/product_large/i001.jpg', 0, '拿铁', '冰/热', '温度', '', '奶', '标准糖/半糖/无糖', '糖', '', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (9, 'rena_ice001', 'rena_ice', '巧克力瑞纳冰', 'Chocolate Exfreezo', '28.00', '醇香巧克力风味搭配牛奶，口感香甜酷爽。（到店饮用口感更佳）\n主要原料：巧克力酱，牛奶，冰沙粉，冰块，搅打奶油（含香草风味糖浆）。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0387_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0387_02.jpg', 0, '瑞纳冰', '', '温度', '', '奶', '', '糖', '默认奶油/无奶油', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (11, 'rena_ice002', 'rena_ice', '抹茶瑞纳冰', 'Matcha Exfreezo', '28.00', '经典抹茶搭配香滑奶油，入口伴有浓郁的抹茶清香。（到店饮用口感更佳）\n主要原料：抹茶风味固体饮料，冰沙粉，牛奶，冰块，搅打稀奶油。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0388_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0388_02.jpg', 0, '瑞纳冰', '', '温度', '', '奶', '', '糖', '默认奶油/无奶油', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38'),
  (12, 'rena_ice003', 'rena_ice', '卡布奇诺瑞纳冰', 'Coppuccino Exfreezo', '28.00', '卡布奇诺咖啡风味融入牛奶与细腻沙冰，香甜纯滑。（到店饮用口感更佳）\n主要原料：卡布奇诺咖啡风味冰沙粉，牛奶，冰沙粉，冰块，搅打奶油（含香草风味糖浆）。\n图片仅供参考，请以实物为准。建议送达后尽快饮用。', 'https://kf.webxyq.com/images/product_small/IMG_0389_02p.jpg', 'https://kf.webxyq.com/images/product_large/IMG_0389_02.jpg', 0, '瑞纳冰', '', '温度', '', '奶', '', '糖', '默认奶油/无奶油', '奶油', '2026-08-30 08:15:38', '2026-08-30 08:15:38');

-- ============================================================
-- 以下表结构根据 API接口文档.md 的接口语义【推测】，无真实数据
-- 上线前请按接口实际返回字段核对
-- ============================================================

-- 4. user 用户
DROP TABLE IF EXISTS `user`;
CREATE TABLE `user` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `phone`      VARCHAR(20)  NOT NULL COMMENT '手机号(登录账号)',
  `password`   VARCHAR(128) NOT NULL COMMENT '密码(务必加密存储)',
  `nick_name`  VARCHAR(64)  NOT NULL COMMENT '昵称',
  `desc`       VARCHAR(512) NULL COMMENT '个人简介',
  `avatar`     VARCHAR(512) NULL COMMENT '头像(接口以 base64 传输)',
  `user_bg`    VARCHAR(512) NULL COMMENT '个人背景图',
  `email`      VARCHAR(128) NULL,
  `is_destroy` TINYINT      NOT NULL DEFAULT 0 COMMENT '是否注销',
  `created_at` DATETIME     NULL,
  `updated_at` DATETIME     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='用户';

-- 5. user_like 收藏
DROP TABLE IF EXISTS `user_like`;
CREATE TABLE `user_like` (
  `id`         BIGINT      NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT      NOT NULL,
  `pid`        VARCHAR(64) NOT NULL,
  `created_at` DATETIME    NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_pid` (`user_id`, `pid`) COMMENT '保证同一用户对同一商品只能收藏一次',
  KEY `idx_like_pid` (`pid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='商品收藏';

-- 6. shopcart 购物车
DROP TABLE IF EXISTS `shopcart`;
CREATE TABLE `shopcart` (
  `id`         BIGINT      NOT NULL AUTO_INCREMENT,
  `user_id`    BIGINT      NOT NULL,
  `pid`        VARCHAR(64) NOT NULL,
  `count`      INT         NOT NULL DEFAULT 1 COMMENT '数量',
  `spec`       VARCHAR(256) NULL COMMENT '规格(温度/奶/糖/奶油快照)',
  `created_at` DATETIME    NULL,
  `updated_at` DATETIME    NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_user_pid_spec` (`user_id`, `pid`, `spec`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='购物车';

-- 7. address 收货地址
DROP TABLE IF EXISTS `address`;
CREATE TABLE `address` (
  `id`         BIGINT       NOT NULL AUTO_INCREMENT,
  `aid`        VARCHAR(64)  NOT NULL COMMENT '地址业务 ID(接口用 aid)',
  `user_id`    BIGINT       NOT NULL,
  `name`       VARCHAR(64)  NOT NULL COMMENT '收货人',
  `phone`      VARCHAR(20)  NOT NULL,
  `region`     VARCHAR(256) NULL COMMENT '省市区',
  `detail`     VARCHAR(512) NULL COMMENT '详细地址',
  `is_default` TINYINT      NOT NULL DEFAULT 0,
  `created_at` DATETIME     NULL,
  `updated_at` DATETIME     NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_aid` (`aid`),
  KEY `idx_addr_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='收货地址';

-- 8. orders 订单
DROP TABLE IF EXISTS `orders`;
CREATE TABLE `orders` (
  `id`          BIGINT        NOT NULL AUTO_INCREMENT,
  `order_no`    VARCHAR(64)   NOT NULL COMMENT '订单号',
  `user_id`     BIGINT        NOT NULL,
  `address_id`  BIGINT        NULL,
  `total_price` DECIMAL(10,2) NOT NULL,
  `status`      TINYINT       NOT NULL DEFAULT 0 COMMENT '0待付款 1已付款 2已收货 3已取消',
  `pay_time`    DATETIME      NULL,
  `created_at`  DATETIME      NULL,
  `updated_at`  DATETIME      NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_order_no` (`order_no`),
  KEY `idx_order_user_status` (`user_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单';

-- 9. order_item 订单明细
DROP TABLE IF EXISTS `order_item`;
CREATE TABLE `order_item` (
  `id`       BIGINT        NOT NULL AUTO_INCREMENT,
  `order_id` BIGINT        NOT NULL,
  `pid`      VARCHAR(64)   NOT NULL,
  `name`     VARCHAR(128)  NOT NULL COMMENT '商品名快照',
  `price`    DECIMAL(10,2) NOT NULL COMMENT '下单时单价快照',
  `count`    INT           NOT NULL,
  `spec`     VARCHAR(256)  NULL COMMENT '规格快照',
  PRIMARY KEY (`id`),
  KEY `idx_item_order` (`order_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='订单明细';
