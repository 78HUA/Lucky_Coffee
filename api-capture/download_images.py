#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""把商品图片全部下载到本地,补全存档"""
import json
import os
import sys
import urllib.request
import urllib.parse

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

OUT = r"E:\Lucky_coffee\api-capture"
IMG = os.path.join(OUT, "images")
UA = ("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 "
      "(KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36")

probe = json.load(open(os.path.join(OUT, "image-urls.json"), encoding="utf-8"))
ok = 0
fail = 0
total = 0
manifest = []

for i, item in enumerate(probe, 1):
    url = item["url"]
    # 保留原始目录名,例如 images/product_large/xxx.jpg
    parts = urllib.parse.urlparse(url)
    rel = parts.path.lstrip("/")                 # images/product_large/xxx.jpg
    dst = os.path.join(IMG, rel.replace("images/", "", 1))
    os.makedirs(os.path.dirname(dst), exist_ok=True)
    if os.path.exists(dst) and os.path.getsize(dst) > 0:
        size = os.path.getsize(dst)
        ok += 1
        total += size
        manifest.append({"url": url, "local": os.path.relpath(dst, OUT), "size": size,
                         "used_by": item.get("used_by", []), "cached": True})
        print(f"  [{i:>2}/{len(probe)}] 已存在 {os.path.basename(dst)}")
        continue
    try:
        req = urllib.request.Request(url, headers={"User-Agent": UA})
        with urllib.request.urlopen(req, timeout=30) as r:
            data = r.read()
        with open(dst, "wb") as f:
            f.write(data)
        ok += 1
        total += len(data)
        manifest.append({"url": url, "local": os.path.relpath(dst, OUT), "size": len(data),
                         "used_by": item.get("used_by", [])})
        print(f"  [{i:>2}/{len(probe)}] OK   {os.path.basename(dst):<24} {len(data)/1024:>7.1f} KB")
    except Exception as e:
        fail += 1
        manifest.append({"url": url, "error": str(e), "used_by": item.get("used_by", [])})
        print(f"  [{i:>2}/{len(probe)}] FAIL {os.path.basename(dst)} -> {e}")

with open(os.path.join(OUT, "images-manifest.json"), "w", encoding="utf-8", newline="\n") as f:
    json.dump(manifest, f, ensure_ascii=False, indent=2)

print("\n" + "=" * 64)
print(f"成功 {ok}/{len(probe)}   失败 {fail}   总大小 {total/1024/1024:.2f} MB")
print(f"图片目录: {IMG}")
print(f"清单: {os.path.join(OUT, 'images-manifest.json')}")
