// 登录态本地存储：用 Preferences 保存 token 与手机号
// 接口文档说明：登录成功后，前端把 token 存在本地，后续访问用户相关接口都要携带 token 验证
import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

// 本地数据库文件（store）名
const SESSION_STORE: string = 'coffee_session';
// 字段 key
const KEY_TOKEN: string = 'token';
const KEY_PHONE: string = 'phone';

/** 登录成功后调用：把 token 和手机号落盘 */
export async function saveLoginSession(context: common.UIAbilityContext, token: string, phone: string): Promise<void> {
  try {
    const store: preferences.Preferences = await preferences.getPreferences(context, SESSION_STORE);
    await store.put(KEY_TOKEN, token);
    await store.put(KEY_PHONE, phone);
    await store.flush(); // 同步到磁盘
  } catch (err) {
    // 本地存储失败不该打断登录流程，只打日志方便排查
    console.error(`saveLoginSession failed, err=${JSON.stringify(err)}`);
  }
}

/** 读取本地保存的 token，没有则返回空串（用于启动页判断是否已登录） */
export async function loadSavedToken(context: common.UIAbilityContext): Promise<string> {
  try {
    const store: preferences.Preferences = await preferences.getPreferences(context, SESSION_STORE);
    return (await store.get(KEY_TOKEN, '')) as string;
  } catch (err) {
    console.error(`loadSavedToken failed, err=${JSON.stringify(err)}`);
    return '';
  }
}

/** 读取本地保存的手机号，没有则返回空串（登录页回填用） */
export async function loadSavedPhone(context: common.UIAbilityContext): Promise<string> {
  try {
    const store: preferences.Preferences = await preferences.getPreferences(context, SESSION_STORE);
    return (await store.get(KEY_PHONE, '')) as string;
  } catch (err) {
    console.error(`loadSavedPhone failed, err=${JSON.stringify(err)}`);
    return '';
  }
}

/** 退出登录时调用：清空本地登录态 */
export async function clearLoginSession(context: common.UIAbilityContext): Promise<void> {
  try {
    const store: preferences.Preferences = await preferences.getPreferences(context, SESSION_STORE);
    await store.delete(KEY_TOKEN);
    await store.delete(KEY_PHONE);
    await store.flush();
  } catch (err) {
    console.error(`clearLoginSession failed, err=${JSON.stringify(err)}`);
  }
}
