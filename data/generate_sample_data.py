# -*- coding: utf-8 -*-
"""
依据《00_项目总说明与模拟数据字典.docx》合成 6 张示例 CSV。
用途：在拿到课程真实 模拟数据 之前，先验证 Docker->Hive->建表->导入->清洗 全链路。
说明：
  - 字段顺序 / 类型严格对齐数据字典（与 sql/ods/01_create_ods_tables.sql 一致）
  - 刻意植入字典 4.3 节描述的五类脏数据：缺失 / 重复 / 异常 / 格式不一致 / 业务逻辑错误
  - 这些是【样例数据】，拿到真实数据后直接覆盖同名文件即可
"""
import csv, random, os

random.seed(20241027)
OUT = os.path.dirname(os.path.abspath(__file__))

def write_csv(name, header, rows):
    path = os.path.join(OUT, name)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.writer(f)
        w.writerow(header)
        w.writerows(rows)
    print(f"  -> {name}: {len(rows)} 行 (+表头)")

# ---------------- ods_user ----------------
user_header = ["user_id","user_name","gender","age","city","province","register_date","member_level","phone","email"]
user_dirty = [
    ["U000001","许浩然","男",42,"宝鸡","陕西省","2023-11-25","金卡会员","13892127520","u000001@example.com"],
    ["U000002","李娜","女",28,"西安","陕西省","2023/11/25","普通","13912345678","u000002@example.com"],
    ["U000003","王强","M",35,"北京","北京市","20231125","gold","138-9212-7520","u000003@example.com"],
    ["U000004","赵敏","女","","上海","上海市","2023-12-01","普通","13700001111",""],            # 年龄缺失 + 邮箱缺失
    ["U000005","陈杰","男",200,"广州","广东省","2024-01-15","钻石会员","13611112222","u000005@example.com"], # 年龄异常200
    ["U000006","刘洋","未知",25,"深圳","广东省","2024/02/20","银卡会员","13522223333","u000006@example.com"],
    ["U000007","周婷","F",31,"杭州","浙江省","20240228","普通","13433334444",""],                  # 邮箱缺失
    ["U000008","吴磊","男",-3,"成都","四川省","2024-03-10","金卡会员","13344445555","u000008@example.com"], # 年龄异常-3
]
first_names = ["张伟","王芳","李勇","刘洋","陈静","杨帆","黄磊","周杰","吴婷","徐强","孙丽","马涛","朱琳","胡军","郭明","林峰","何雪","高翔","罗刚","梁艳"]
cities = [("南京","江苏省"),("武汉","湖北省"),("重庆","重庆市"),("天津","天津市"),("苏州","江苏省"),("青岛","山东省")]
genders = ["男","女"]
levels = ["金卡会员","普通","银卡会员","钻石会员"]
user_rows = list(user_dirty)
for i in range(len(user_dirty), 30):
    uid = f"U{i+1:06d}"
    nm = random.choice(first_names)
    gd = random.choice(genders)
    age = random.randint(18, 65)
    c, p = random.choice(cities)
    rd = f"2024-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
    lv = random.choice(levels)
    ph = f"13{random.randint(0,9)}{random.randint(100000000,999999999)}"
    em = f"u{uid}@example.com"
    user_rows.append([uid, nm, gd, age, c, p, rd, lv, ph, em])
write_csv("ods_user.csv", user_header, user_rows)

# ---------------- ods_product ----------------
prod_header = ["product_id","product_name","category","sub_category","brand","price","cost","stock","status","launch_date"]
prod_dirty = [
    ["P00001","营养米糊","母婴玩具","辅食","贝亲",62.0,44.47,3934,"在售","2023-11-20"],
    ["P00002","纸尿裤","母婴玩具 ","辅食","帮宝适",99.9,70.0,2000,"在售",""],          # category尾空格 + launch_date缺失
    ["P00003","进口奶粉","母婴玩具","辅食","BABYCARE",-626.74,400.0,500,"在售","2023-12-01"], # 价格负数
    ["P00004","智能手表","数码家电","穿戴","Xiaomi",999999.0,2000.0,10,"在售","2024-01-10"], # 价格异常高
    ["P00005","纯棉T恤","服饰鞋包","上衣","UNIQLO",129.0,60.0,0,"缺货","2024-02-15"],     # 库存0
]
prod_names = [("蓝牙耳机","数码家电","音频","Sony"),("跑步鞋","运动户外","鞋","Nike"),
              ("儿童绘本","图书文娱","读物","中信"),("精华液","美妆个护","护肤","Loreal"),
              ("大米5kg","食品生鲜","粮油","金龙鱼"),("积木玩具","母婴玩具","益智","LEGO")]
prod_rows = list(prod_dirty)
for i in range(len(prod_dirty), 25):
    pid = f"P{i+1:05d}"
    nm, cat, sub, br = random.choice(prod_names)
    price = round(random.uniform(20, 800), 2)
    cost = round(price * random.uniform(0.5, 0.8), 2)
    stock = random.randint(50, 5000)
    status = random.choice(["在售","下架","缺货"])
    launch = f"2024-{random.randint(1,12):02d}-{random.randint(1,28):02d}"
    prod_rows.append([pid, nm, cat, sub, br, price, cost, stock, status, launch])
write_csv("ods_product.csv", prod_header, prod_rows)

# ---------------- ods_store ----------------
store_header = ["store_id","store_name","province","city","district","address","open_date","area","manager"]
stores = [
    ["S001","云购生活·广州旗舰店","广东省","广州","高新区","广州高新区128号","2023-05-12",420,"王伟"],
    ["S002","云购生活·深圳南山店","广东省","深圳","南山区","深圳南山区55号","2023-06-20",360,"李娜"],
    ["S003","云购生活·北京朝阳店","北京市","北京","朝阳区","北京朝阳区9号","2023-04-18",500,"张强"],
    ["S004","云购生活·上海浦东店","上海市","上海","浦东新区","上海浦东新区300号","2023-07-01",480,"陈静"],
    ["S005","云购生活·成都武侯店","四川省","成都","武侯区","成都武侯区77号","2023-08-11",300,"刘洋"],
    ["S006","云购生活·杭州西湖店","浙江省","杭州","西湖区","杭州西湖区21号","2023-09-05",350,"周婷"],
]
write_csv("ods_store.csv", store_header, stores)

# ---------------- ods_order ----------------
order_header = ["order_id","user_id","store_id","order_date","order_time","pay_amount","discount_amount","pay_type","order_status","channel"]
order_rows = []
base_orders = [
    ["O2024000001","U000607","S004","2024-07-26","21:40:40",2484.13,587.46,"微信支付","已完成","APP"],
    ["O2024000002","U000608","S001","2024/07/26","10:12:05",-2484.13,0.0,"wechat","1","app"],   # 负金额+英文混合
    ["O2024000003","U000609","S002","2024-07-27","09:30:00",5000000.0,1000.0,"支付宝","cancelled","门店"], # 异常高金额
    ["O2024000004","U000610","S003","2024-07-27","14:05:22",699.0,50.0,"微信支付","已完成","APP"],
    ["O2024000005","U000611","S005","2024-08-01","19:22:11",320.5,20.0,"支付宝","已完成","app"], # channel大小写
]
for o in base_orders:
    order_rows.append(o)
# 重复订单：O2024000001 整行重复 2 条；另造一条主键重复但字段不同的
order_rows.append(["O2024000001","U000607","S004","2024-07-26","21:40:40",2484.13,587.46,"微信支付","已完成","APP"])
order_rows.append(["O2024000001","U000607","S004","2024-07-26","21:40:40",2484.13,587.46,"微信支付","已完成","APP"])
order_rows.append(["O2024000006","U000612","S006","2024-08-02","11:00:00",150.0,10.0,"微信支付","已完成","APP"])
order_rows.append(["O2024000006","U000612","S006","2024-08-02","11:05:00",155.0,10.0,"微信支付","已完成","APP"]) # 主键重复但金额不同
n = len(order_rows)
while n < 45:
    oid = f"O2024{n:07d}"
    uid = f"U{random.randint(1,30):06d}"
    sid = f"S{random.randint(1,6):03d}"
    od = f"2024-{random.randint(7,9):02d}-{random.randint(1,28):02d}"
    ot = f"{random.randint(0,23):02d}:{random.randint(0,59):02d}:{random.randint(0,59):02d}"
    pay = round(random.uniform(50, 3000), 2)
    disc = round(pay * random.uniform(0, 0.2), 2)
    ptype = random.choice(["微信支付","wechat","支付宝"])
    ostatus = random.choice(["已完成","1","cancelled"])
    chan = random.choice(["APP","app","门店"])
    order_rows.append([oid, uid, sid, od, ot, pay, disc, ptype, ostatus, chan])
    n += 1
write_csv("ods_order.csv", order_header, order_rows)

# ---------------- ods_order_item ----------------
item_header = ["item_id","order_id","product_id","quantity","unit_price","discount"]
item_rows = []
n = 0
while n < 60:
    iid = f"I2025{n+1:010d}"
    oid = random.choice([r[0] for r in order_rows])
    pid = f"P{random.randint(1,25):05d}"
    qty = random.choice([1,2,3,0,-2,99])  # 含0/负/超大
    up = round(random.uniform(10, 800), 2)
    disc = round(random.uniform(0, 0.3), 2)
    item_rows.append([iid, oid, pid, qty, up, disc])
    n += 1
write_csv("ods_order_item.csv", item_header, item_rows)

# ---------------- ods_user_behavior ----------------
beh_header = ["behavior_id","user_id","product_id","behavior_type","behavior_time","session_id"]
beh_types = ["pv","cart","fav","buy","浏览"]
beh_rows = []
n = 0
while n < 40:
    bid = f"B{n+1:08d}"
    uid = f"U{random.randint(1,30):06d}"
    pid = f"P{random.randint(1,25):05d}"
    bt = random.choice(beh_types)
    if random.random() < 0.5:
        btime = f"2024-11-{random.randint(1,30):02d} {random.randint(0,23):02d}:{random.randint(0,59):02d}:{random.randint(0,59):02d}"
    else:
        btime = f"2024/11/{random.randint(1,30):02d} {random.randint(0,23):02d}:{random.randint(0,59):02d}"  # 格式不一致
    sid = f"SES{random.randint(100000,999999)}"
    beh_rows.append([bid, uid, pid, bt, btime, sid])
    n += 1
write_csv("ods_user_behavior.csv", beh_header, beh_rows)

print("\n示例数据生成完成，全部位于:", OUT)
