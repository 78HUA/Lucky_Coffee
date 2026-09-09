import { http } from '@kit.NetworkKit'

//请求基地址
const BASEURL: string = "https://kf.webxyq.com";
//请求appkey
const APPKEY: string = "U2FsdGVkX19WSQ59Cg+Fj9jNZPxRC5y0xB1iV06BeNA=";

/**
 * 手动把对象参数拼成 "参数1=值1&参数2=值2" 的查询串
 * 接口文档规定：POST 请求参数必须是这种 x-www-form-urlencoded 格式
 * @param obj 待转换的对象
 * @returns 拼接好的查询串
 */
function objectToQueryString(obj: object): string {
  // Object.entries：把对象整理成二维数组 [["key","value"],...]
  return Object.entries(obj)
    // 过滤空值（null / undefined 的参数不发送）
    .filter((item: string[]) => item[1] !== null && item[1] !== undefined)
    // 把 ["key","value"] 拼成 "key=value"，键和值都要 encodeURIComponent，
    // 否则特殊字符（如 appkey 里的 + =）会破坏参数解析
    .map((item: string[]) => {
      return encodeURIComponent(item[0]) + '=' + encodeURIComponent(String(item[1]));
    })
    // 用 & 连接所有键值对
    .join('&');
}

/**
 *  封装网络请求
 * @param url 请求地址，如 /banner
 * @param method 请求方式 GET / POST
 * @param params 请求参数
 * @returns Promise<http.HttpResponse>
 */
let request = (url: string, method: string = "GET", params: object = Object({})): Promise<http.HttpResponse> => {
  //创建请求实例
  let httpRequest = http.createHttp();
  //请求方式
  let type = method == "GET" ? http.RequestMethod.GET : http.RequestMethod.POST
  //给参数params添加一个appkey属性（所有接口都需要）
  Object(params).appkey = APPKEY;

  // POST 请求体必须是 "a=1&b=2" 形式的字符串；GET 参数交给 SDK 拼到 url 上
  let body: string | object = params;
  if (method == "POST") {
    body = objectToQueryString(Object(params));
  }

  //用实例发起网络请求
  return httpRequest.request(BASEURL + url, {
    //请求方式
    method: type, // 可选，默认为http.RequestMethod.GET。
    //请求头
    header: {
      "Content-Type": "application/x-www-form-urlencoded"
    },
    //请求参数：POST 用序列化后的查询串，GET 用对象
    extraData: body,
    //请求成功 返回数据格式
    expectDataType: http.HttpDataType.OBJECT, // 可选，指定返回数据的类型。
  })
  //请求结束后销毁实例
    .finally(() => {
      httpRequest.destroy();
    })
}

//导出网络请求
export default request;
