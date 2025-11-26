// BE/src/controllers/payment.controller.js

import VNPayService from "../services/vnpay.service.js";
import Payment from "../models/Payment.js";
import PaymentIntent from "../models/PaymentIntent.js";
import Order from "../models/Order.js";

class PaymentController {
  /**
   * TẠO VNPAY URL TỪ PAYMENT INTENT
   * POST /api/payment/vnpay/create
   */
  async createVNPayPayment(req, res) {
    try {
      console.log('\n💳 ========== CREATE VNPAY PAYMENT ==========');
      
      const { intentId } = req.body;
      const userId = req.user.id;
      
      // ✅ GET IP ADDRESS - CONVERT IPv6 to IPv4
      let ipAddr = req.headers['x-forwarded-for'] 
        || req.connection.remoteAddress 
        || req.socket.remoteAddress 
        || req.ip;
      
      // ✅ CRITICAL FIX - REMOVE ::ffff: PREFIX
      if (ipAddr && ipAddr.includes('::ffff:')) {
        ipAddr = ipAddr.replace('::ffff:', '');
      }
      
      // ✅ CONVERT ::1 (localhost IPv6) → 127.0.0.1
      if (!ipAddr || ipAddr === '::1') {
        ipAddr = '127.0.0.1';
      }

      // ✅ VALIDATE IP FORMAT (must be IPv4)
      const ipv4Regex = /^(\d{1,3}\.){3}\d{1,3}$/;
      if (!ipv4Regex.test(ipAddr)) {
        console.warn('⚠️ Invalid IP format, using default:', ipAddr);
        ipAddr = '127.0.0.1';
      }

      console.log('🎯 Intent ID:', intentId);
      console.log('👤 User ID:', userId);
      console.log('🌐 IP Address (cleaned):', ipAddr);

      // ✅ FIND INTENT
      const intent = await PaymentIntent.findById(intentId);
      
      if (!intent) {
        return res.status(404).json({
          success: false,
          message: 'Payment intent không tồn tại',
        });
      }

      if (intent.user.toString() !== userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Không có quyền truy cập intent này',
        });
      }

      if (intent.paymentStatus !== 'pending') {
        return res.status(400).json({
          success: false,
          message: `Intent đã ${intent.paymentStatus}`,
        });
      }

      console.log('✅ Intent validated');
      console.log('   Total Amount:', intent.totalAmount);
      console.log('   Payment Method:', intent.paymentMethod);

      // ✅ CREATE ORDER INFO - INCLUDE INTENT ID (CRITICAL!)
      const orderInfo = `Thanh-toan-intent-${intentId}`;
      console.log('📝 Order Info:', orderInfo);

      // ✅ CREATE VNPAY URL
      const result = VNPayService.createPaymentUrl(
        intentId,
        intent.totalAmount,
        orderInfo,
        ipAddr
      );

      if (!result.success) {
        console.error('❌ Failed to create VNPay URL');
        return res.status(500).json({
          success: false,
          message: result.message || 'Không thể tạo link thanh toán',
        });
      }

      // ✅ CRITICAL: SAVE TRANSACTION ID TO INTENT
      intent.transactionId = result.txnRef;
      await intent.save();
      console.log('✅ Intent updated with txnRef:', result.txnRef);

      console.log('✅ Payment URL created successfully');
      console.log('🔗 TxnRef:', result.txnRef);
      console.log('💳 ========== CREATE VNPAY PAYMENT END ==========\n');

      return res.status(200).json({
        success: true,
        paymentUrl: result.paymentUrl,
        txnRef: result.txnRef,
      });

    } catch (error) {
      console.error('❌ Create VNPay payment error:', error);
      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }

  /**
   * CALLBACK TỪ VNPAY
   * GET /api/payment/vnpay/callback
   */
  async vnpayCallback(req, res) {
    try {
      const vnpParams = req.query;

      console.log("\n🔄 ========== VNPAY CALLBACK ==========");
      console.log("📦 TxnRef:", vnpParams.vnp_TxnRef);
      console.log("💰 Amount:", vnpParams.vnp_Amount);
      console.log("📊 Response Code:", vnpParams.vnp_ResponseCode);
      console.log("📝 Order Info:", vnpParams.vnp_OrderInfo);

      // ✅ VERIFY SIGNATURE
      const verification = VNPayService.verifyCallback(vnpParams);

      if (!verification.success) {
        console.log("❌ Invalid signature");
        return res.redirect(
          `myapp://payment/result?success=false&message=Invalid-signature`
        );
      }

      const { txnRef, transactionNo, responseCode } = verification.data;
      const isSuccess = verification.isPaymentSuccess;

      console.log(`💳 Payment ${isSuccess ? "SUCCESS ✅" : "FAILED ❌"}`);

      // ✅ CRITICAL FIX: EXTRACT INTENT ID FROM ORDER INFO
      const orderInfo = vnpParams.vnp_OrderInfo || "";
      console.log("📝 Processing Order Info:", orderInfo);
      
      // Format: "Thanh-toan-intent-69272b029d055002295efe2c"
      // Extract last part after last dash
      const parts = orderInfo.split('-');
      const intentId = parts[parts.length - 1];
      
      console.log("🎯 Extracted Intent ID:", intentId);

      if (!intentId || intentId.length !== 24) {
        console.log("❌ Invalid Intent ID format:", intentId);
        return res.redirect(
          `myapp://payment/result?success=false&message=Invalid-intent-id`
        );
      }

      // ✅ FIND INTENT BY ID (NOT BY TRANSACTION ID)
      const intent = await PaymentIntent.findById(intentId);

      if (!intent) {
        console.log("❌ Intent not found for ID:", intentId);
        return res.redirect(
          `myapp://payment/result?success=false&message=Intent-not-found`
        );
      }

      console.log("✅ Intent found:", intent._id);
      console.log("   Current status:", intent.paymentStatus);
      console.log("   User:", intent.user);

      // ✅ UPDATE INTENT STATUS
      intent.paymentStatus = isSuccess ? "paid" : "failed";
      intent.transactionId = txnRef;
      intent.vnpTransactionNo = transactionNo;
      intent.responseCode = responseCode;
      intent.bankCode = vnpParams.vnp_BankCode;
      intent.cardType = vnpParams.vnp_CardType;
      intent.vnpayData = vnpParams;
      
      await intent.save();

      console.log(`✅ Intent status updated: ${intent.paymentStatus}`);
      console.log("🔄 ========== VNPAY CALLBACK END ==========\n");

      // ✅ REDIRECT TO APP WITH DEEP LINK
      const deepLink = `myapp://payment/result?success=${isSuccess}&intentId=${intent._id}&txnRef=${txnRef}&responseCode=${responseCode}`;
      console.log("🔗 Redirecting to:", deepLink);
      
      return res.redirect(deepLink);

    } catch (error) {
      console.error("❌ VNPay callback error:", error);
      console.error("   Stack:", error.stack);
      
      return res.redirect(
        `myapp://payment/result?success=false&message=${encodeURIComponent(error.message)}`
      );
    }
  }

  /**
   * IPN từ VNPay (Server-to-Server)
   * GET /api/payment/vnpay/ipn
   */
  async vnpayIPN(req, res) {
    try {
      const vnpParams = req.query;
      
      console.log("\n📡 ========== VNPAY IPN ==========");
      console.log("📦 TxnRef:", vnpParams.vnp_TxnRef);
      console.log("📊 Response Code:", vnpParams.vnp_ResponseCode);
      console.log("📝 Order Info:", vnpParams.vnp_OrderInfo);

      // ✅ VERIFY SIGNATURE
      const verification = VNPayService.verifyCallback(vnpParams);

      if (!verification.success) {
        console.log("❌ IPN: Invalid signature");
        return res.json({
          RspCode: '97',
          Message: 'Invalid Signature',
        });
      }

      const { txnRef, transactionNo, responseCode } = verification.data;
      const isSuccess = verification.isPaymentSuccess;

      console.log(`💳 IPN Payment ${isSuccess ? "SUCCESS ✅" : "FAILED ❌"}`);

      // ✅ EXTRACT INTENT ID FROM ORDER INFO
      const orderInfo = vnpParams.vnp_OrderInfo || "";
      const parts = orderInfo.split('-');
      const intentId = parts[parts.length - 1];
      
      console.log("🎯 IPN Extracted Intent ID:", intentId);

      if (!intentId || intentId.length !== 24) {
        console.log("❌ IPN: Invalid Intent ID format");
        return res.json({
          RspCode: '99',
          Message: 'Invalid Intent ID',
        });
      }

      // ✅ FIND AND UPDATE INTENT
      const intent = await PaymentIntent.findById(intentId);

      if (!intent) {
        console.log("❌ IPN: Intent not found:", intentId);
        return res.json({
          RspCode: '01',
          Message: 'Order not found',
        });
      }

      // ✅ CHECK IF ALREADY PROCESSED
      if (intent.paymentStatus === 'paid' && isSuccess) {
        console.log("⚠️ IPN: Already processed");
        return res.json({
          RspCode: '00',
          Message: 'Success',
        });
      }

      // ✅ UPDATE INTENT
      intent.paymentStatus = isSuccess ? "paid" : "failed";
      intent.transactionId = txnRef;
      intent.vnpTransactionNo = transactionNo;
      intent.responseCode = responseCode;
      intent.bankCode = vnpParams.vnp_BankCode;
      intent.cardType = vnpParams.vnp_CardType;
      intent.vnpayData = vnpParams;
      
      await intent.save();

      console.log(`✅ IPN: Intent status updated: ${intent.paymentStatus}`);
      console.log("📡 ========== VNPAY IPN END ==========\n");

      return res.json({
        RspCode: '00',
        Message: 'Success',
      });

    } catch (error) {
      console.error("❌ VNPay IPN error:", error);
      console.error("   Stack:", error.stack);
      
      return res.json({
        RspCode: '99',
        Message: 'Unknown error',
      });
    }
  }

  /**
   * GET PAYMENT INTENT INFO
   * GET /api/payment/intent/:id
   */
  async getPaymentIntent(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user.id;

      console.log('\n📋 ========== GET PAYMENT INTENT ==========');
      console.log('🎯 Intent ID:', id);
      console.log('👤 User ID:', userId);

      const intent = await PaymentIntent.findById(id);

      if (!intent) {
        return res.status(404).json({
          success: false,
          message: 'Payment intent không tồn tại',
        });
      }

      if (intent.user.toString() !== userId.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Không có quyền truy cập',
        });
      }

      console.log('✅ Intent found');
      console.log('   Status:', intent.paymentStatus);
      console.log('   Amount:', intent.totalAmount);
      console.log('📋 ========== GET PAYMENT INTENT END ==========\n');

      return res.status(200).json({
        success: true,
        intent: {
          id: intent._id,
          paymentStatus: intent.paymentStatus,
          paymentMethod: intent.paymentMethod,
          totalAmount: intent.totalAmount,
          transactionId: intent.transactionId,
          vnpTransactionNo: intent.vnpTransactionNo,
          responseCode: intent.responseCode,
          bankCode: intent.bankCode,
          cardType: intent.cardType,
          createdAt: intent.createdAt,
          expiresAt: intent.expiresAt,
        },
      });

    } catch (error) {
      console.error('❌ Get payment intent error:', error);
      return res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }
}

export default new PaymentController();