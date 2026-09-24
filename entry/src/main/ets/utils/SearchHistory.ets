// 搜索历史（存本地 Preferences，最多保留 MAX_HISTORY 条，最新的排最前）
// 和 utils/Session.ets 用的是同一套 preferences 写法
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

const HISTORY_STORE: string = 'coffee_search_history';
const KEY_HISTORY: string = 'history';
// 最多记这么多条，超出的丢掉最旧的
const MAX_HISTORY: number = 10;

// 把整个列表写回本地
async function saveHistory(context: common.UIAbilityContext, list: string[]): Promise<void> {
  try {
    const store = await preferences.getPreferences(context, HISTORY_STORE);
    await store.put(KEY_HISTORY, JSON.stringify(list));
    await store.flush();
  } catch (err) {
    console.error(`saveHistory failed, err=${JSON.stringify(err)}`);
  }
}

// 读历史（读不到就返回空列表）
export async function loadSearchHistory(context: common.UIAbilityContext): Promise<string[]> {
  try {
    const store = await preferences.getPreferences(context, HISTORY_STORE);
    const raw: string = await store.get(KEY_HISTORY, '[]') as string;
    const list: string[] = JSON.parse(raw) as string[];
    return Array.isArray(list) ? list : [];
  } catch (err) {
    console.error(`loadSearchHistory failed, err=${JSON.stringify(err)}`);
    return [];
  }
}

// 记一条搜索：去重（重复的提到最前）+ 截断，返回更新后的完整列表
export async function addSearchHistory(context: common.UIAbilityContext,
  keyword: string): Promise<string[]> {
  const list: string[] = await loadSearchHistory(context);
  const next: string[] = [keyword];
  for (const item of list) {
    if (item !== keyword) {
      next.push(item);
    }
  }
  const trimmed: string[] = next.slice(0, MAX_HISTORY);
  await saveHistory(context, trimmed);
  return trimmed;
}

// 删掉一条
export async function removeSearchHistory(context: common.UIAbilityContext,
  keyword: string): Promise<string[]> {
  const list: string[] = await loadSearchHistory(context);
  const next: string[] = list.filter((item: string) => item !== keyword);
  await saveHistory(context, next);
  return next;
}

// 清空
export async function clearSearchHistory(context: common.UIAbilityContext): Promise<void> {
  await saveHistory(context, []);
}
