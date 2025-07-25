export class ConfigUtil {
  static readonly SERVER = "http://10.136.247.115:3000"
  static readonly SERVERURL = "http://10.136.247.115:3000/uploads/"
  static readonly HTTP_CODE_200 = 200

  /**
   * 成功失败提示
   */
  static readonly SERVER_NET_SUCCESS: string = '请求数据成功';
  static readonly SERVER_NET_ERROR: string = '请求失败请检查网络';

  static readonly HTTP_CONNECT_TIMEOUT: number = 10000;
  static readonly HTTP_READ_TIMEOUT: number = 10000;
}