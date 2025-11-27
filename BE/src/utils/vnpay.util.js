import crypto from "crypto";
import querystring from "querystring";

class VNPayUtil {
  /**
   * Sắp xếp object theo alphabet
   */
  static sortObject(obj) {
    const sorted = {};
    const keys = Object.keys(obj).sort();
    keys.forEach((key) => {
      sorted[key] = obj[key];
    });
    return sorted;
  }

  /**
   * Tạo secure hash SHA512
   */
  static createSecureHash(data, secretKey) {
    const sortedData = this.sortObject(data);
    const signData = querystring.stringify(sortedData, { encode: false });
    const hmac = crypto.createHmac("sha512", secretKey);
    return hmac.update(Buffer.from(signData, "utf-8")).digest("hex");
  }

  /**
   * Verify secure hash từ VNPay
   */
  static verifySecureHash(data, secureHash, secretKey) {
    const { vnp_SecureHash, vnp_SecureHashType, ...paramsToHash } = data;
    const calculatedHash = this.createSecureHash(paramsToHash, secretKey);
    return calculatedHash === secureHash;
  }

  /**
   * Format số tiền (VNPay yêu cầu nhân 100, không có số thập phân)
   */
  static formatAmount(amount) {
    return Math.floor(amount * 100);
  }

  /**
   * Format ngày giờ theo VNPay (yyyyMMddHHmmss)
   */
  static formatDate(date = new Date()) {
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, "0");
    const day = String(date.getDate()).padStart(2, "0");
    const hour = String(date.getHours()).padStart(2, "0");
    const minute = String(date.getMinutes()).padStart(2, "0");
    const second = String(date.getSeconds()).padStart(2, "0");
    return `${year}${month}${day}${hour}${minute}${second}`;
  }

  /**
   * Tạo mã giao dịch unique
   */
  static generateTxnRef(orderId) {
    return `${orderId}_${Date.now()}`;
  }
}

export default VNPayUtil;