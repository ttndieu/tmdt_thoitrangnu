// BE/src/services/vnpay.service.js

import crypto from "crypto";
import querystring from "querystring";  // CHANGE FROM "qs" TO "querystring"
import moment from "moment";

class VNPayService {
  constructor() {
    this.vnp_TmnCode = process.env.VNPAY_TMN_CODE;
    this.vnp_HashSecret = process.env.VNPAY_HASH_SECRET;
    this.vnp_Url = process.env.VNPAY_URL;
    this.vnp_ReturnUrl = process.env.VNPAY_RETURN_URL;

    console.log('\n🔧 ========== VNPAY CONFIG ==========');
    console.log('TMN Code:', this.vnp_TmnCode ? '✅' : '❌ MISSING');
    console.log('Hash Secret:', this.vnp_HashSecret ? '✅' : '❌ MISSING');
    console.log('URL:', this.vnp_Url || '❌ MISSING');
    console.log('Return URL:', this.vnp_ReturnUrl || '❌ MISSING');
    console.log('🔧 ========== VNPAY CONFIG END ==========\n');
  }

  /**
   * TẠO PAYMENT URL
   */
  createPaymentUrl(intentId, amount, orderInfo, ipAddr) {
    try {
      console.log('\n💳 ========== VNPAY CREATE URL ==========');
      console.log('🎯 Intent ID:', intentId);
      console.log('💰 Amount (input):', amount);
      console.log('📝 Order Info (original):', orderInfo);
      console.log('🌐 IP:', ipAddr);

      // ✅ VALIDATE CONFIG
      if (!this.vnp_TmnCode || !this.vnp_HashSecret || !this.vnp_Url || !this.vnp_ReturnUrl) {
        throw new Error('VNPay config chưa đầy đủ. Check .env file.');
      }

      // ✅ FORMAT AMOUNT (VNPay yêu cầu số nguyên * 100)
      const vnpAmount = Math.round(amount * 100);
      console.log('💰 Amount (VNPay format):', vnpAmount);

      // ✅ GENERATE TXN REF
      const txnRef = `VNPAY${moment().format('YYYYMMDDHHmmss')}${Math.floor(Math.random() * 1000)}`;
      console.log('🔗 TxnRef:', txnRef);

      // ✅ CREATE DATE
      const createDate = moment().format('YYYYMMDDHHmmss');
      console.log('📅 Create Date:', createDate);

      // ✅ REMOVE SPACES FROM ORDER INFO
      const cleanOrderInfo = orderInfo.replace(/\s+/g, '-');
      console.log('📝 Order Info (cleaned):', cleanOrderInfo);

      // ✅ BUILD PARAMS
      let vnp_Params = {
        vnp_Version: '2.1.0',
        vnp_Command: 'pay',
        vnp_TmnCode: this.vnp_TmnCode,
        vnp_Locale: 'vn',
        vnp_CurrCode: 'VND',
        vnp_TxnRef: txnRef,
        vnp_OrderInfo: cleanOrderInfo,
        vnp_OrderType: 'other',
        vnp_Amount: vnpAmount,
        vnp_ReturnUrl: this.vnp_ReturnUrl,
        vnp_IpAddr: ipAddr,
        vnp_CreateDate: createDate,
      };

      console.log('📦 VNPay Params (before sort):');
      console.log(JSON.stringify(vnp_Params, null, 2));

      // ✅ SORT PARAMS
      vnp_Params = this.sortObject(vnp_Params);

      console.log('📦 VNPay Params (after sort):');
      console.log(JSON.stringify(vnp_Params, null, 2));

      // ✅ CREATE SIGNATURE - USING BUILT-IN querystring
      const signData = querystring.stringify(vnp_Params);  // ✅ NO OPTIONS - USE DEFAULT
      console.log('🔐 Sign Data:');
      console.log(signData);

      const hmac = crypto.createHmac('sha512', this.vnp_HashSecret);
      const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');
      console.log('🔐 Signature:', signed);

      vnp_Params['vnp_SecureHash'] = signed;

      // ✅ BUILD URL
      const paymentUrl = this.vnp_Url + '?' + querystring.stringify(vnp_Params);
      
      console.log('✅ Payment URL created successfully');
      console.log('🔗 URL length:', paymentUrl.length);
      console.log('🔗 Full URL (first 200 chars):');
      console.log(paymentUrl.substring(0, 200) + '...');
      console.log('💳 ========== VNPAY CREATE URL END ==========\n');

      return {
        success: true,
        paymentUrl,
        txnRef,
      };
    } catch (error) {
      console.error('❌ Create VNPay URL error:', error);
      return {
        success: false,
        message: error.message,
      };
    }
  }

  /**
   * VERIFY CALLBACK
   */
  verifyCallback(vnpParams) {
    try {
      console.log('\n🔄 ========== VERIFY CALLBACK ==========');
      console.log('📦 Params:', JSON.stringify(vnpParams, null, 2));

      const secureHash = vnpParams['vnp_SecureHash'];
      delete vnpParams['vnp_SecureHash'];
      delete vnpParams['vnp_SecureHashType'];

      const sortedParams = this.sortObject(vnpParams);
      const signData = querystring.stringify(sortedParams);  // ✅ NO OPTIONS
      
      console.log('🔐 Sign Data:', signData);

      const hmac = crypto.createHmac('sha512', this.vnp_HashSecret);
      const signed = hmac.update(Buffer.from(signData, 'utf-8')).digest('hex');

      console.log('🔐 Calculated Signature:', signed);
      console.log('🔐 Received Signature:', secureHash);

      const isValid = secureHash === signed;
      console.log(`🔐 Signature ${isValid ? 'VALID ✅' : 'INVALID ❌'}`);

      if (!isValid) {
        return {
          success: false,
          message: 'Invalid signature',
        };
      }

      const responseCode = vnpParams['vnp_ResponseCode'];
      const isPaymentSuccess = responseCode === '00';

      console.log(`💳 Payment ${isPaymentSuccess ? 'SUCCESS ✅' : 'FAILED ❌'}`);
      console.log('🔄 ========== VERIFY CALLBACK END ==========\n');

      return {
        success: true,
        isPaymentSuccess,
        data: {
          txnRef: vnpParams['vnp_TxnRef'],
          transactionNo: vnpParams['vnp_TransactionNo'],
          amount: parseInt(vnpParams['vnp_Amount']) / 100,
          responseCode: responseCode,
          bankCode: vnpParams['vnp_BankCode'],
          cardType: vnpParams['vnp_CardType'],
        },
      };
    } catch (error) {
      console.error('❌ Verify callback error:', error);
      return {
        success: false,
        message: error.message,
      };
    }
  }

  /**
   * HANDLE IPN
   */
  async handleIPN(vnpParams) {
    try {
      console.log('\n📡 ========== HANDLE IPN ==========');
      
      const verification = this.verifyCallback(vnpParams);

      if (!verification.success) {
        return {
          RspCode: '97',
          Message: 'Invalid Signature',
        };
      }

      console.log('✅ IPN verified successfully');
      console.log('📡 ========== HANDLE IPN END ==========\n');

      return {
        RspCode: '00',
        Message: 'Success',
      };
    } catch (error) {
      console.error('❌ Handle IPN error:', error);
      return {
        RspCode: '99',
        Message: 'Unknown error',
      };
    }
  }

  /**
   * SORT OBJECT
   */
  sortObject(obj) {
    const sorted = {};
    const keys = Object.keys(obj).sort();
    keys.forEach((key) => {
      sorted[key] = obj[key];
    });
    return sorted;
  }
}

export default new VNPayService();