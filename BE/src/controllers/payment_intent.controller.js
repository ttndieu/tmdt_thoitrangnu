// BE/src/controllers/payment_intent.controller.js

import PaymentIntent from "../models/PaymentIntent.js";
import Cart from "../models/Cart.js";
import Product from "../models/Product.js";
import Voucher from "../models/Voucher.js";

class PaymentIntentController {
  /**
   * Tạo Payment Intent từ Cart
   * POST /api/payment/intent/create
   */
  static async createIntent(req, res) {
    try {
      const { paymentMethod, shippingAddress, voucherId, selectedItemIds } = req.body;
      const userId = req.user._id;

      if (!["cod", "vnpay"].includes(paymentMethod)) {
        return res.status(400).json({
          success: false,
          message: "Invalid payment method",
        });
      }

      if (!shippingAddress || !shippingAddress.fullName) {
        return res.status(400).json({
          success: false,
          message: "Shipping address is required",
        });
      }

      const cart = await Cart.findOne({ user: userId }).populate("items.product");

      if (!cart || cart.items.length === 0) {
        return res.status(400).json({
          success: false,
          message: "Cart is empty",
        });
      }

      let itemsToProcess = cart.items;

      if (selectedItemIds && Array.isArray(selectedItemIds) && selectedItemIds.length > 0) {
        itemsToProcess = cart.items.filter((item) =>
          selectedItemIds.includes(item._id.toString())
        );

        if (itemsToProcess.length === 0) {
          return res.status(400).json({
            success: false,
            message: "No valid items selected",
          });
        }
      }

      let originalAmount = 0;
      const intentItems = [];

      for (let item of itemsToProcess) {
        const product = item.product;

        const variant = product.variants.find(
          (v) => v.size === item.size && v.color === item.color
        );

        if (!variant) {
          return res.status(400).json({
            success: false,
            message: `Variant not found for ${product.name}`,
          });
        }

        if (variant.stock < item.quantity) {
          return res.status(400).json({
            success: false,
            message: `Not enough stock for ${product.name} (${item.size}/${item.color})`,
          });
        }

        const itemPrice = variant.price * item.quantity;
        originalAmount += itemPrice;

        intentItems.push({
          product: product._id,
          quantity: item.quantity,
          price: variant.price,
          size: item.size,
          color: item.color,
        });
      }

      // APPLY VOUCHER
      let discount = 0;
      let voucher = null;
      let voucherCode = null;

      if (voucherId) {
        voucher = await Voucher.findById(voucherId);

        if (!voucher) {
          return res.status(404).json({
            success: false,
            message: "Voucher not found",
          });
        }

        if (!voucher.active) {
          return res.status(400).json({
            success: false,
            message: "Voucher không khả dụng",
          });
        }

        if (voucher.quantity <= 0) {
          return res.status(400).json({
            success: false,
            message: "Voucher đã hết lượt sử dụng",
          });
        }

        if (new Date() > voucher.expiredAt) {
          return res.status(400).json({
            success: false,
            message: "Voucher đã hết hạn",
          });
        }

        if (originalAmount < voucher.minOrderValue) {
          return res.status(400).json({
            success: false,
            message: `Đơn hàng tối thiểu ${voucher.minOrderValue.toLocaleString("vi-VN")}đ`,
          });
        }

        discount = Math.min(
          (originalAmount * voucher.discountPercent) / 100,
          voucher.maxDiscount
        );

        voucherCode = voucher.code;

        voucher.quantity -= 1;
        await voucher.save();
      }

      // CRITICAL FIX: ADD SHIPPING FEE
      const shippingFee = 15000; // VND

      // CALCULATE TOTAL WITH SHIPPING FEE
      const totalAmount = originalAmount - discount + shippingFee;
      
      // CREATE INTENT WITH SHIPPING FEE
      const intent = await PaymentIntent.create({
        user: userId,
        items: intentItems,
        voucher: voucherId || null,
        voucherCode: voucherCode || null,
        discount: discount,
        shippingFee: shippingFee, 
        originalAmount: originalAmount,
        totalAmount: totalAmount, 
        paymentMethod,
        shippingAddress,
        paymentStatus: "pending",
      });

      res.status(201).json({
        success: true,
        intent: {
          id: intent._id,
          totalAmount: intent.totalAmount,
          originalAmount: intent.originalAmount,
          discount: intent.discount,
          shippingFee: intent.shippingFee, 
          voucherCode: intent.voucherCode,
          paymentMethod: intent.paymentMethod,
          paymentStatus: intent.paymentStatus,
          shippingAddress: intent.shippingAddress,
          expiresAt: intent.expiresAt,
        },
      });
    } catch (error) {
      console.error("Create intent error:", error);
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }

  /**
   * Lấy thông tin intent
   * GET /api/payment/intent/:id
   */
  static async getIntent(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user._id;

      const intent = await PaymentIntent.findById(id)
        .populate("items.product", "name images")
        .populate("voucher");

      if (!intent) {
        return res.status(404).json({
          success: false,
          message: "Intent not found",
        });
      }

      if (intent.user.toString() !== userId.toString()) {
        return res.status(403).json({
          success: false,
          message: "Unauthorized",
        });
      }

      res.json({
        success: true,
        intent,
      });
    } catch (error) {
      console.error("Get intent error:", error);
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }

  /**
   * Hủy intent
   * PUT /api/payment/intent/:id/cancel
   */
  static async cancelIntent(req, res) {
    try {
      const { id } = req.params;
      const userId = req.user._id;

      const intent = await PaymentIntent.findById(id)
        .populate("items.product", "name")
        .populate("voucher");

      if (!intent) {
        return res.status(404).json({
          success: false,
          message: "Intent not found",
        });
      }

      if (intent.user.toString() !== userId.toString()) {
        return res.status(403).json({
          success: false,
          message: "Unauthorized",
        });
      }

      if (intent.order) {
        console.log("Intent already has order:", intent.order);
        return res.status(400).json({
          success: false,
          message: "Intent đã được tạo order, không thể hủy",
        });
      }

      if (intent.voucher) {
        
        try {
          const voucher = await Voucher.findById(intent.voucher);
          if (voucher) {
            voucher.quantity += 1;
            await voucher.save();
          }
        } catch (voucherErr) {
          console.error("Error restoring voucher:", voucherErr);
        }
      }

      intent.paymentStatus = "cancelled";
      await intent.save();

      if (intent.paymentMethod === "vnpay" && intent.vnpTransactionNo) {
        
        return res.json({
          success: true,
          intent,
          message: "Yêu cầu hủy đã được ghi nhận. Tiền sẽ được hoàn trong 1-3 ngày làm việc.",
          requiresRefund: true,
        });
      }

      res.json({
        success: true,
        intent,
        message: "Đã hủy thành công",
      });
    } catch (error) {
      console.error("Cancel intent error:", error);
      res.status(500).json({
        success: false,
        message: error.message,
      });
    }
  }
}

export default PaymentIntentController;