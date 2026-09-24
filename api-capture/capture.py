#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Lucky Coffee 教学 API —— 接口契约与数据抓取脚本
只调用只读接口(GET),不触碰写操作接口,避免污染教学环境数据。
"""
import json
import os
import sys
import time
import urllib.parse
import urllib.request

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

BASE = "https://kf.webxyq.com"
APPKEY = "U2FsdGVkX19WSQ59Cg+Fj9jNZPxRC5y0xB1iV06BeNA="
OUT = r"E:\Lucky_coffee\api-capture"
RAW = os.path.join(OUT, "raw")
os.makedirs(RAW, exist_ok=True)

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

_request_log = []


def get(path, params=None, save_as=None, delay=0.25):
    """发起 GET 请求;返回 (解析后的对象, 原始文本)"""
    q = {"appkey": APPKEY}
    if params:
        q.update(params)
    url = BASE + path + "?" + urllib.parse.urlencode(q)
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw = resp.read()
            text = raw.decode("utf-8", errors="replace")
        _request_log.append({"path": path, "params": params or {}, "status": 200, "bytes": len(raw)})
        if save_as:
            with open(os.path.join(RAW, save_as + ".json"), "w", encoding="utf-8", newline="\n") as f:
                f.write(text)
        time.sleep(delay)
        try:
            return json.loads(text), text
        except json.JSONDecodeError as e:
            print(f"  !! JSON 解析失败 {save_as}: {e}")
            return None, text
    except Exception as e:
        _request_log.append({"path": path, "params": params or {}, "status": "ERR", "error": str(e)})
        print(f"  ERR {path} {params} -> {e}")
        return None, None


def main():
    summary = {"captured_at": time.strftime("%Y-%m-%d %H:%M:%S"), "base": BASE}

    print("=" * 72)
    print("1) banner")
    banner, _ = get("/banner", save_as="banner")
    if banner:
        print(f"   banner 条数 = {len(banner.get('result', []))}")

    print("\n2) type (商品分类)")
    types, _ = get("/type", save_as="type")
    type_list = types.get("result", []) if types else []
    print(f"   分类数 = {len(type_list)}")
    for t in type_list:
        print(f"     id={t.get('id')}  type={t.get('type')}  {t.get('typeDesc')}")

    print("\n3) typeProducts (热门)")
    hot, _ = get("/typeProducts", {"key": "isHot", "value": "1"}, save_as="typeProducts-isHot")
    hot_pids = [p["pid"] for p in (hot or {}).get("result", [])]
    print(f"   热门商品 = {len(hot_pids)}")

    print("\n4) typeProducts (按分类)")
    by_type = {}
    for t in type_list:
        name = t.get("type")
        data, _ = get("/typeProducts", {"key": "type", "value": name},
                      save_as=f"typeProducts-{name}")
        items = (data or {}).get("result", [])
        by_type[name] = items
        print(f"   {name:<12} {len(items)} 个商品")

    # 汇总去重商品
    products = {}
    for items in ([hot.get("result", []) if hot else []] + list(by_type.values())):
        for p in items:
            if p.get("pid"):
                products[p["pid"]] = p
    print(f"\n   去重后商品总数 = {len(products)}")

    print("\n5) productDetail (逐个商品)")
    details = {}
    for i, pid in enumerate(sorted(products), 1):
        d, _ = get("/productDetail", {"pid": pid}, save_as=f"productDetail-{pid}")
        details[pid] = d
        print(f"   [{i:>2}/{len(products)}] {pid:<14} {'OK' if d else 'FAIL'}")
    ok = sum(1 for v in details.values() if v)
    print(f"   成功 {ok}/{len(products)}")

    print("\n6) search (抽样)")
    searches = {}
    for kw in ["咖啡", "拿铁", "拿铁", "冰", "茶"]:
        d, _ = get("/search", {"name": kw}, save_as=f"search-{urllib.parse.quote(kw)}")
        searches[kw] = d
    print(f"   搜索关键词 = {len(searches)}")

    # ---------- 汇总输出 ----------
    seed = {
        "meta": {"source": BASE, "captured_at": summary["captured_at"]},
        "banner": (banner or {}).get("result", []),
        "types": type_list,
        "products": [products[k] for k in sorted(products)],
        "product_details": {k: v for k, v in details.items() if v},
    }
    with open(os.path.join(OUT, "seed-data.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(seed, f, ensure_ascii=False, indent=2)

    with open(os.path.join(OUT, "raw", "_request-log.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(_request_log, f, ensure_ascii=False, indent=2)

    summary.update({
        "banner_count": len(seed["banner"]),
        "type_count": len(type_list),
        "product_count": len(seed["products"]),
        "product_detail_ok": len(seed["product_details"]),
        "requests": len(_request_log),
    })
    with open(os.path.join(OUT, "capture-summary.json"), "w", encoding="utf-8", newline="\n") as f:
        json.dump(summary, f, ensure_ascii=False, indent=2)

    print("\n" + "=" * 72)
    print(f"完成: banner={summary['banner_count']}  分类={summary['type_count']}  "
          f"商品={summary['product_count']}  详情OK={summary['product_detail_ok']}  "
          f"请求数={summary['requests']}")
    print(f"输出目录: {OUT}")


if __name__ == "__main__":
    main()
