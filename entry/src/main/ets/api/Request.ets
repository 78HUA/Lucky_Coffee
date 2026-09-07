import { http } from '@kit.NetworkKit'
import { url } from '@kit.ArkTS'

//请求基地址
const BASEURL: string = "https://kf.webxyq.com";
//请求appkey
const APPKEY: string = "U2FsdGVkX19WSQ59Cg+Fj9jNZPxRC5y0xB1iV06BeNA=";


/**
 *  封装网络请求
 * @param url 请求地址
 * @param method 请求方式 GET Post
 * @param params  请求参数
 * @returns Promise<ResponseType>
 */
let request = (url: string, method: string = "GET", params: object = Object({})): Promise<http.HttpResponse> => {
  //创建请求实例
  let httpRequest = http.createHttp();
  //请求方式
  let type = method == "GET" ? http.RequestMethod.GET : http.RequestMethod.POST
//给参数params添加一个appkey属性
  Object(params).appkey = APPKEY;
  //用实例发起网络请求
  return  httpRequest.request(BASEURL + url, {
    //请求方式
    method: type, // 可选，默认为http.RequestMethod.GET。
    //请求头
    header:{
      "Content-Type": "application/x-www-form-urlencoded"
    },
    extraData:params,
    //请求成功 返回数据格式
    expectDataType: http.HttpDataType.OBJECT, // 可选，指定返回数据的类型。
  })
    //请求结束后销毁实例
    .finally(() => {httpRequest.destroy();})
}
//导出网络请求
export default request;