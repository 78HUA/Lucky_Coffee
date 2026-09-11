// 表单校验工具：登录 / 注册 / 以后的个人资料页 都能复用
// 后端实测（2025 课程接口 kf.webxyq.com）：注册不强制密码复杂度，
// 这里取一个折中规则：6-16 位，且同时包含字母和数字。
// 若想用老师那种更严的规则（必须含字母+数字+符号），改 validatePassword 即可。

// 手机号正则：1 开头、第二位 3-9，共 11 位数字
const PHONE_REG: RegExp = /^1[3-9]\d{9}$/;

/** 校验手机号：合法返回 true */
export function validatePhone(phone: string): boolean {
  return PHONE_REG.test(phone);
}

/**
 * 校验密码：6-16 位，且同时包含字母和数字
 * @param pwd 待校验密码
 * @returns 通过返回 true
 */
export function validatePassword(pwd: string): boolean {
  // 长度 6-16
  if (pwd.length < 6 || pwd.length > 16) {
    return false;
  }
  // 必须含字母
  if (!/[a-zA-Z]/.test(pwd)) {
    return false;
  }
  // 必须含数字
  if (!/\d/.test(pwd)) {
    return false;
  }
  return true;
}

/**
 * 校验昵称：至少 2 个字符，且不能包含空白字符
 * @param nickname 待校验昵称
 * @returns 通过返回 true
 */
export function validateNickName(nickname: string): boolean {
  // 至少 2 个字符
  if (nickname.length < 2) {
    return false;
  }
  // \s 匹配任意空白字符（空格、制表符等）
  return !/\s/.test(nickname);
}
