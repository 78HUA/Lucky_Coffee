#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""统计已抓取数据中引用到的图片 URL,并探测其大小"""
import json
import os
import sys
import urllib.request
import urllib.error

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

OUT = r"E:\Lucky_coffee\api-capture"
seed = json.load(open(os.path.join(OUT, "seed-data.json"), encoding="utf-8"))

UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

urls = {}  # url -> 用途说明


def add(url, why):
    if url and isinstance(url, str) and url.startswith("http"):
        urls.setdefault(url, set()).add(why)


for b in seed["banner"]:
    add(b.get("bannerImg"), "banner")
for p in seed["products"]:
    add(p.get("smallImg"), "product.smallImg")
    add(p.get("largeImg"), "product.largeImg")
for pid, d in seed["product_details"].items():
    for item in (d.get("result") or []):
        add(item.get("small_img"), "detail.small_img")
        add(item.get("large_img"), "detail.large_img")

print(f"引用到的图片 URL 总数(去重)= {len(urls)}")
print()

# 按目录归类
from collections import Counter
dirs = Counter()
for u in urls:
    d = u.rsplit("/", 1)[0]
    dirs[d] += 1
print("按目录分布:")
for d, c in dirs.most_common():
    print(f"  {c:>3} 张   {d}")
print()

print("探测文件大小(HEAD 请求)...")
total = 0
probe = []
for i, u in enumerate(sorted(urls), 1):
    try:
        req = urllib.request.Request(u, headers={"User-Agent": UA}, method="HEAD")
        with urllib.request.urlopen(req, timeout=15) as r:
            size = int(r.headers.get("Content-Length") or 0)
            ctype = r.headers.get("Content-Type", "?")
        total += size
        probe.append({"url": u, "size": size, "type": ctype, "used_by": sorted(urls[u])})
        if i % 10 == 0 or i == len(urls):
            print(f"  [{i:>2}/{len(urls)}] 累计 {total/1024/1024:.2f} MB")
    except Exception as e:
        probe.append({"url": u, "size": None, "error": str(e), "used_by": sorted(urls[u])})
        print(f"  [{i:>2}/{len(urls)}] ERR {u.rsplit('/',1)[-1]} -> {e}")

with open(os.path.join(OUT, "image-urls.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump(probe, f, ensure_ascii=False, indent=2)

ok = [p for p in probe if p.get("size") is not None]
print()
print("=" * 64)
print(f"可访问图片 = {len(ok)}/{len(probe)}")
print(f"预计总大小 = {total/1024/1024:.2f} MB")
print(f"清单已写出 -> {os.path.join(OUT, 'image-urls.json')}")
