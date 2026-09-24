#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
图片 URL 批量替换工具

把存档数据里的远程图片地址(https://kf.webxyq.com/images/)
替换成你自己的地址 —— 例如自建后端或对象存储。

用法:
    # 1) 先看看当前状态(不做任何修改)
    py -3.13 rewrite_urls.py --report

    # 2) 替换成自建后端地址
    py -3.13 rewrite_urls.py --to http://localhost:8080/images/

    # 3) 替换成对象存储 / CDN
    py -3.13 rewrite_urls.py --to https://cdn.example.com/lucky/images/

    # 4) 只预览会改什么,不写入
    py -3.13 rewrite_urls.py --to http://x/img/ --dry-run

    # 5) 恢复成原始远程地址
    py -3.13 rewrite_urls.py --restore

    # 6) 连同 raw/ 一起替换(raw/ 默认保持原样作为基准)
    py -3.13 rewrite_urls.py --to http://x/img/ --include-raw
"""
import argparse
import json
import os
import shutil
import sys

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

BASE = os.path.dirname(os.path.abspath(__file__))
ORIGIN_PREFIX = "https://kf.webxyq.com/images/"
BACKUP_DIR = os.path.join(BASE, "_backup_original")
STATE_FILE = os.path.join(BASE, "_rewrite-state.json")

# 默认处理的目标(不含 raw/,raw/ 作为基准保持原样)
DEFAULT_TARGETS = ["schema.sql", "seed-data.json"]
RAW_DIR = "raw"


def load_state():
    if os.path.exists(STATE_FILE):
        try:
            return json.load(open(STATE_FILE, encoding="utf-8"))
        except Exception:
            pass
    return {"current_prefix": ORIGIN_PREFIX, "history": []}


def save_state(state):
    with open(STATE_FILE, "w", encoding="utf-8", newline="\n") as f:
        json.dump(state, f, ensure_ascii=False, indent=2)


def collect_files(include_raw):
    files = []
    for name in DEFAULT_TARGETS:
        p = os.path.join(BASE, name)
        if os.path.exists(p):
            files.append(p)
    if include_raw:
        d = os.path.join(BASE, RAW_DIR)
        if os.path.isdir(d):
            for n in sorted(os.listdir(d)):
                if n.endswith(".json"):
                    files.append(os.path.join(d, n))
    return files


def backup(files):
    """首次修改前备份原文件"""
    os.makedirs(BACKUP_DIR, exist_ok=True)
    made = []
    for p in files:
        rel = os.path.relpath(p, BASE)
        dst = os.path.join(BACKUP_DIR, rel)
        if not os.path.exists(dst):          # 只备份一次,不覆盖
            os.makedirs(os.path.dirname(dst), exist_ok=True)
            shutil.copy2(p, dst)
            made.append(rel)
    return made


def count_occurrences(text, prefix):
    return text.count(prefix)


def do_report():
    state = load_state()
    cur = state.get("current_prefix", ORIGIN_PREFIX)
    print("=" * 68)
    print("当前状态")
    print("=" * 68)
    print(f"  当前 URL 前缀 : {cur}")
    print(f"  原始 URL 前缀 : {ORIGIN_PREFIX}")
    print(f"  是否已替换    : {'是' if cur != ORIGIN_PREFIX else '否(仍是原始远程地址)'}")
    print(f"  备份目录      : {BACKUP_DIR if os.path.isdir(BACKUP_DIR) else '(尚无备份)'}")
    print()
    print("  各文件中的 URL 数量:")
    total = 0
    for p in collect_files(include_raw=True):
        text = open(p, encoding="utf-8", errors="replace").read()
        n_cur = count_occurrences(text, cur)
        n_org = count_occurrences(text, ORIGIN_PREFIX)
        rel = os.path.relpath(p, BASE)
        if n_cur or n_org:
            print(f"    {rel:<44} 当前前缀 {n_cur:>3} 处 / 原始前缀 {n_org:>3} 处")
            total += max(n_cur, n_org)
    print(f"    {'合计':<44} {total} 处")
    if state.get("history"):
        print()
        print("  历史记录:")
        for h in state["history"][-5:]:
            print(f"    {h['time']}  {h['from']}  ->  {h['to']}")
    return 0


def do_rewrite(new_prefix, dry_run=False, include_raw=False):
    if not new_prefix.endswith("/"):
        new_prefix += "/"
    state = load_state()
    cur = state.get("current_prefix", ORIGIN_PREFIX)

    if cur == new_prefix:
        print(f"当前已经是 {new_prefix},无需修改。")
        return 0

    files = collect_files(include_raw)
    if not files:
        print("没有找到需要处理的文件。")
        return 1

    print("=" * 68)
    print(f"替换:  {cur}")
    print(f"   ->  {new_prefix}")
    print("=" * 68)
    print(f"处理文件 {len(files)} 个" + ("(含 raw/)" if include_raw else "(不含 raw/,它保持原样作基准)"))
    print()

    planned = []
    for p in files:
        text = open(p, encoding="utf-8", errors="replace").read()
        n = count_occurrences(text, cur)
        if n:
            planned.append((p, n, text.replace(cur, new_prefix)))
    total = sum(n for _, n, _ in planned)
    for p, n, _ in planned:
        print(f"  {os.path.relpath(p, BASE):<44} {n:>3} 处")
    print(f"\n  合计 {total} 处")

    if total == 0:
        print("\n没有找到可替换的内容 —— 请检查当前前缀是否正确(见 --report)。")
        return 1

    if dry_run:
        print("\n[dry-run] 未写入任何文件。")
        return 0

    made = backup(files)
    if made:
        print(f"\n已备份 {len(made)} 个原始文件 -> {os.path.relpath(BACKUP_DIR, BASE)}/")
        for m in made:
            print(f"    {m}")

    for p, _, new_text in planned:
        with open(p, "w", encoding="utf-8", newline="\n") as f:
            f.write(new_text)

    state["current_prefix"] = new_prefix
    state.setdefault("history", []).append({
        "time": __import__("time").strftime("%Y-%m-%d %H:%M:%S"),
        "from": cur, "to": new_prefix, "count": total,
        "files": [os.path.relpath(p, BASE) for p, _, _ in planned],
    })
    save_state(state)

    print(f"\n完成:{total} 处 URL 已更新。")
    print("\n提醒:")
    print("  1. 图片文件在 images/ 目录,记得一并上传到你的服务器或对象存储")
    print("  2. 若新前缀是 http://(非 https),HarmonyOS 需额外允许明文流量")
    print("  3. 恢复原始地址: py -3.13 rewrite_urls.py --restore")
    return 0


def do_restore():
    if not os.path.isdir(BACKUP_DIR):
        print("没有备份,无法恢复。")
        return 1
    files = collect_files(include_raw=True)
    n = 0
    print("=" * 68)
    print("从备份恢复")
    print("=" * 68)
    for p in files:
        rel = os.path.relpath(p, BASE)
        src = os.path.join(BACKUP_DIR, rel)
        if os.path.exists(src):
            shutil.copy2(src, p)
            print(f"  恢复 {rel}")
            n += 1
    state = load_state()
    state["current_prefix"] = ORIGIN_PREFIX
    state.setdefault("history", []).append({
        "time": __import__("time").strftime("%Y-%m-%d %H:%M:%S"),
        "from": state.get("current_prefix"), "to": ORIGIN_PREFIX, "action": "restore",
    })
    save_state(state)
    print(f"\n已恢复 {n} 个文件为原始远程地址。")
    return 0


def main():
    ap = argparse.ArgumentParser(
        description="把存档数据里的远程图片 URL 批量替换成你自己的地址",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    ap.add_argument("--to", metavar="PREFIX", help="新的 URL 前缀,例如 http://localhost:8080/images/")
    ap.add_argument("--report", action="store_true", help="显示当前状态,不做修改")
    ap.add_argument("--restore", action="store_true", help="从备份恢复原始远程地址")
    ap.add_argument("--dry-run", action="store_true", help="只预览,不写入")
    ap.add_argument("--include-raw", action="store_true", help="连同 raw/ 一起处理(默认保持原样)")
    args = ap.parse_args()

    if args.report:
        return do_report()
    if args.restore:
        return do_restore()
    if args.to:
        return do_rewrite(args.to, dry_run=args.dry_run, include_raw=args.include_raw)
    ap.print_help()
    return 0


if __name__ == "__main__":
    sys.exit(main())
