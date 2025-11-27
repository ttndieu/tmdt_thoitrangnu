// be/src/controllers/order.controller.js

import Order from "../models/Order.js";
import Cart from "../models/Cart.js";
import Product from "../models/Product.js";
import { sendOrderEmail } from "../services/mail.service.js";
import {
  notifyNewOrder,
  notifyOrderStatusChange
} from "../services/notification.service.js";
import Voucher from "../models/Voucher.js";
import PaymentIntent from "../models/PaymentIntent.js";

// ------------------------------------------------------
// CREATE ORDER (USER)
// ------------------------------------------------------
export const createOrder = async (req, res) => {
  try {
    const { paymentMethod, shippingAddress, voucherId, selectedItemIds } = req.body;

    console.log(`\n📦 ========== CREATE ORDER ==========`);
    console.log(`👤 User: ${req.user._id}`);
    console.log(`💳 Payment method: ${paymentMethod}`);
    console.log(`🎫 Voucher ID: ${voucherId || 'None'}`);
    console.log(`🛒 Selected Item IDs: ${selectedItemIds ? JSON.stringify(selectedItemIds) : 'All'}`);

    const cart = await Cart.findOne({ user: req.user._id })
      .populate("items.product");

    if (!cart || cart.items.length === 0) {
      return res.status(400).json({ message: "Cart is empty" });
    }

    // FILTER: Chỉ lấy items được chọn
    let itemsToOrder = cart.items;

    if (selectedItemIds && Array.isArray(selectedItemIds) && selectedItemIds.length > 0) {
      itemsToOrder = cart.items.filter(item => 
        selectedItemIds.includes(item._id.toString())
      );
      
      console.log(`✅ Filtered ${itemsToOrder.length} selected items from ${cart.items.length} total items`);
      
      if (itemsToOrder.length === 0) {
        return res.status(400).json({ message: "No valid items selected" });
      }
    } else {
      console.log(`⚠️ No selectedItemIds provided, using all cart items`);
    }

    let originalAmount = 0;

    // Check tồn kho & tính tổng
    for (let item of itemsToOrder) {
      const product = item.product;

      const variant = product.variants.find(
        (v) => v.size === item.size && v.color === item.color
      );

      if (!variant || variant.stock < item.quantity) {
        return res.status(400).json({
          message: `Not enough stock for ${product.name}`
        });
      }

      originalAmount += variant.price * item.quantity;
    }

    console.log(`💰 Original amount: ${originalAmount}`);

    // ✅ APPLY VOUCHER
    let discount = 0;
    let voucher = null;
    let voucherCode = null;

    if (voucherId) {
      voucher = await Voucher.findById(voucherId);

      if (!voucher) {
        return res.status(404).json({ message: "Voucher not found" });
      }

      // Validate
      if (!voucher.active) {
        return res.status(400).json({ message: "Voucher không khả dụng" });
      }

      if (voucher.quantity <= 0) {
        return res.status(400).json({ message: "Voucher đã hết lượt sử dụng" });
      }

      if (new Date() > voucher.expiredAt) {
        return res.status(400).json({ message: "Voucher đã hết hạn" });
      }

      if (originalAmount < voucher.minOrderValue) {
        return res.status(400).json({ 
          message: `Đơn hàng tối thiểu ${voucher.minOrderValue.toLocaleString('vi-VN')}đ` 
        });
      }

      // Calculate discount
      discount = Math.min(
        (originalAmount * voucher.discountPercent) / 100,
        voucher.maxDiscount
      );

      voucherCode = voucher.code;
      console.log(`🎫 Applied: ${voucherCode} → Discount: ${discount}`);

      // Giảm số lượng voucher
      voucher.quantity -= 1;
      await voucher.save();
    }

    const totalAmount = originalAmount - discount;
    console.log(`💵 Total amount: ${totalAmount}`);

    // ✅ QUAN TRỌNG: CHỈ TRỪ STOCK NẾU LÀ COD
    // VNPay sẽ trừ stock khi callback thành công
    if (paymentMethod === 'cod') {
      console.log('💵 COD payment - Deducting stock now');
      
      // Trừ tồn kho VÀ tăng sold
      for (let item of itemsToOrder) {
        // Trừ stock của variant
        await Product.updateOne(
          {
            _id: item.product._id,
            "variants.size": item.size,
            "variants.color": item.color
          },
          { $inc: { "variants.$.stock": -item.quantity } }
        );
        
        // Tăng sold count của product
        await Product.findByIdAndUpdate(
          item.product._id,
          { $inc: { sold: item.quantity } }
        );
        
        console.log(`✅ Product ${item.product._id}: -${item.quantity} stock, +${item.quantity} sold`);
      }
    } else {
      console.log('🏦 VNPay payment - Stock will be deducted after payment success');
    }

    // ✅ Tạo đơn hàng với status phù hợp
    const order = await Order.create({
      user: req.user._id,
      items: itemsToOrder.map((i) => ({
        product: i.product._id,
        quantity: i.quantity,
        size: i.size,
        color: i.color,
        price: i.product.variants.find(
          (v) => v.size === i.size && v.color === i.color
        ).price,
      })),
      voucher: voucherId || null,
      voucherCode: voucherCode || null,
      discount: discount,
      originalAmount: originalAmount,
      totalAmount: totalAmount,
      paymentMethod,
      shippingAddress,
      status: "pending",  // ✅ Luôn là pending ban đầu
      paymentStatus: paymentMethod === 'vnpay' ? 'pending' : 'pending',  // ✅ Cả 2 đều pending
    });

    // Load order với product info
    const fullOrder = await Order.findById(order._id)
      .populate("items.product", "name images")
      .populate("voucher");

    console.log(`✅ Order created: ${order._id}`);
    console.log(`📊 Status: ${order.status}`);
    console.log(`💳 Payment status: ${order.paymentStatus}`);

    // ✅ QUAN TRỌNG: XỬ LÝ CART DỰA TRÊN PAYMENT METHOD
    if (paymentMethod === 'cod') {
      // COD: Xóa items ngay
      if (selectedItemIds && selectedItemIds.length > 0) {
        cart.items = cart.items.filter(item => 
          !selectedItemIds.includes(item._id.toString())
        );
        console.log(`🗑️ COD - Removed ${selectedItemIds.length} items from cart`);
      } else {
        cart.items = [];
        console.log(`🗑️ COD - Cleared entire cart`);
      }
      await cart.save();
      
      // Gửi notification & email cho COD
      await notifyNewOrder(req.user._id, fullOrder);
      await sendOrderEmail(req.user.email, fullOrder);
    } else {
      // VNPay: GIỮ items trong cart
      console.log(`⏳ VNPay - Items kept in cart (will be removed after payment success)`);
      // KHÔNG gửi notification/email, sẽ gửi khi callback thành công
    }

    console.log(`📦 ========== CREATE ORDER END ==========\n`);

    return res.status(201).json({ 
      success: true,
      order: fullOrder 
    });

  } catch (err) {
    console.error('❌ Create order error:', err);
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// USER GET ORDERS
// ------------------------------------------------------
export const getMyOrders = async (req, res) => {
  try {
    const orders = await Order.find({ user: req.user._id })
      .populate("items.product", "name images")
      .sort({ createdAt: -1 });

    return res.json({ orders });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// ADMIN GET ALL ORDERS
// ------------------------------------------------------
export const getAllOrders = async (req, res) => {
  try {
    const orders = await Order.find()
      .populate("user", "name email")
      .populate("items.product", "name images")
      .sort({ createdAt: -1 });

    return res.json({ count: orders.length, orders });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// ADMIN UPDATE STATUS
// ------------------------------------------------------
export const updateOrderStatus = async (req, res) => {
  try {
    const { status } = req.body;

    const allowed = ["pending", "confirmed", "shipping", "completed", "cancelled"];
    if (!allowed.includes(status))
      return res.status(400).json({ message: "Invalid status" });

    const order = await Order.findByIdAndUpdate(
      req.params.id,
      { status },
      { new: true }
    )
      .populate("user", "email")
      .populate("items.product", "name");

    if (!order)
      return res.status(404).json({ message: "Order not found" });

    // Thông báo thay đổi trạng thái
    await notifyOrderStatusChange(order.user._id, order, status);

    return res.json({ order });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// ✅ USER CANCEL ORDER
// ------------------------------------------------------
export const cancelOrder = async (req, res) => {
  try {
    const orderId = req.params.id;
    const userId = req.user._id;

    console.log(`\n🚫 ========== CANCEL ORDER ==========`);
    console.log(`👤 User: ${userId}`);
    console.log(`📦 Order ID: ${orderId}`);

    // ✅ Tìm order VÀ populate items.product
    const order = await Order.findById(orderId).populate("items.product");

    if (!order) {
      console.log('❌ Order not found');
      return res.status(404).json({ message: "Đơn hàng không tồn tại" });
    }

    console.log(`✅ Found order: ${order._id}`);
    console.log(`📊 Order status: ${order.status}`);
    console.log(`👤 Order user: ${order.user}`);

    // ✅ CHECK: Order thuộc về user này không?
    if (order.user.toString() !== userId.toString()) {
      console.log('❌ Unauthorized user');
      return res.status(403).json({ message: "Bạn không có quyền hủy đơn hàng này" });
    }

    // ✅ CHECK: Chỉ hủy được đơn ở trạng thái pending
    if (order.status !== "pending") {
      console.log(`❌ Cannot cancel. Status: ${order.status}`);
      return res.status(400).json({ 
        message: "Chỉ có thể hủy đơn hàng ở trạng thái chờ xác nhận" 
      });
    }

    // ✅ HOÀN LẠI TỒN KHO VÀ GIẢM SOLD
console.log(`📦 Hoàn lại tồn kho...`);
for (let item of order.items) {
  try {
    // Hoàn stock
    await Product.updateOne(
      {
        _id: item.product._id,
        "variants.size": item.size,
        "variants.color": item.color
      },
      { $inc: { "variants.$.stock": item.quantity } }
    );
    
    // ✅ THÊM: Giảm sold count
    await Product.findByIdAndUpdate(
      item.product._id,
      { $inc: { sold: -item.quantity } }
    );
    
    console.log(`✅ Hoàn lại ${item.quantity} sản phẩm ${item.product.name}`);
    console.log(`✅ Giảm ${item.quantity} sold count`);
  } catch (productErr) {
    console.error(`❌ Error restoring stock for product ${item.product._id}:`, productErr);
    // Continue even if one product fails
  }
}

    // ✅ HOÀN LẠI VOUCHER (NẾU CÓ)
    if (order.voucher) {
      console.log(`🎫 Hoàn lại voucher: ${order.voucherCode}`);
      
      try {
        const voucher = await Voucher.findById(order.voucher);
        
        if (voucher) {
          // Tăng quantity
          voucher.quantity += 1;
          
          // Xóa user khỏi danh sách usedBy (nếu có field này)
          if (voucher.usedBy && Array.isArray(voucher.usedBy)) {
            voucher.usedBy = voucher.usedBy.filter(
              uid => uid.toString() !== userId.toString()
            );
          }
          
          await voucher.save();
          
          console.log(`✅ Đã hoàn lại voucher ${order.voucherCode}`);
          console.log(`✅ Quantity: ${voucher.quantity}`);
          if (voucher.usedBy) {
            console.log(`✅ UsedBy length: ${voucher.usedBy.length}`);
          }
        } else {
          console.log(`⚠️ Voucher ${order.voucher} not found, skipping restore`);
        }
      } catch (voucherErr) {
        console.error(`❌ Error restoring voucher:`, voucherErr);
        // Continue even if voucher restore fails
      }
    }

    // ✅ UPDATE STATUS
    order.status = "cancelled";
    await order.save();

    console.log(`✅ Order ${orderId} đã bị hủy`);
    console.log(`🚫 ========== CANCEL ORDER END ==========\n`);

    // Thông báo hủy đơn
    try {
      await notifyOrderStatusChange(userId, order, "cancelled");
    } catch (notifyErr) {
      console.error('❌ Error sending notification:', notifyErr);
      // Continue even if notification fails
    }

    // Load lại order với đầy đủ thông tin
    const cancelledOrder = await Order.findById(orderId)
      .populate("items.product", "name images")
      .populate("voucher");

    return res.json({ 
      message: "Đã hủy đơn hàng thành công",
      order: cancelledOrder 
    });

  } catch (err) {
    console.error('❌ Cancel order error:', err);
    console.error('❌ Error stack:', err.stack);
    return res.status(500).json({ 
      message: err.message || "Lỗi server khi hủy đơn hàng"
    });
  }
};

/**
 * TẠO ORDER TỪ PAYMENT INTENT
 * POST /api/orders/create-from-intent
 */
export const createOrderFromIntent = async (req, res) => {
  try {
    const { intentId } = req.body;
    const userId = req.user._id;

    console.log("\n🎯 ========== CREATE ORDER FROM INTENT ==========");
    console.log("👤 User:", userId);
    console.log("🎯 Intent ID:", intentId);

    if (!intentId) {
      return res.status(400).json({
        success: false,
        message: "Intent ID is required",
      });
    }

    const intent = await PaymentIntent.findById(intentId)
      .populate("items.product")
      .populate("voucher");

    if (!intent) {
      return res.status(404).json({
        success: false,
        message: "Payment intent not found",
      });
    }

    console.log("✅ Found intent:", intent._id);

    if (intent.user.toString() !== userId.toString()) {
      console.log("❌ Unauthorized user");
      return res.status(403).json({
        success: false,
        message: "Unauthorized",
      });
    }

    if (intent.paymentStatus !== "paid") {
      console.log(`❌ Intent not paid. Status: ${intent.paymentStatus}`);
      return res.status(400).json({
        success: false,
        message: "Payment chưa hoàn tất",
      });
    }

    if (intent.order) {
      console.log(`⚠️ Order already created: ${intent.order}`);
      const existingOrder = await Order.findById(intent.order)
        .populate("items.product", "name images")
        .populate("voucher");
      
      return res.json({
        success: true,
        order: existingOrder,
        message: "Order đã được tạo trước đó",
      });
    }

    console.log("✅ Intent validated. Creating order...");

    for (let item of intent.items) {
      const product = await Product.findById(item.product._id);
      
      if (!product) {
        return res.status(400).json({
          success: false,
          message: `Product ${item.product.name} not found`,
        });
      }

      const variant = product.variants.find(
        (v) => v.size === item.size && v.color === item.color
      );

      if (!variant || variant.stock < item.quantity) {
        return res.status(400).json({
          success: false,
          message: `Not enough stock for ${product.name}`,
        });
      }
    }

    console.log("✅ Stock validated");

    console.log("📦 Deducting stock...");
    for (let item of intent.items) {
      try {
        await Product.updateOne(
          {
            _id: item.product._id,
            "variants.size": item.size,
            "variants.color": item.color,
          },
          { $inc: { "variants.$.stock": -item.quantity } }
        );

        await Product.findByIdAndUpdate(item.product._id, {
          $inc: { sold: item.quantity },
        });

        console.log(`✅ ${item.product.name}: -${item.quantity} stock, +${item.quantity} sold`);
      } catch (productErr) {
        console.error(`❌ Error updating product ${item.product._id}:`, productErr);
      }
    }

    const order = await Order.create({
      user: userId,
      items: intent.items.map((item) => ({
        product: item.product._id,
        quantity: item.quantity,
        size: item.size,
        color: item.color,
        price: item.price,
      })),
      voucher: intent.voucher || null,
      voucherCode: intent.voucherCode || null,
      discount: intent.discount,
      originalAmount: intent.originalAmount,
      totalAmount: intent.totalAmount,
      paymentMethod: intent.paymentMethod,
      shippingAddress: intent.shippingAddress,
      status: "confirmed",
      paymentStatus: "paid",
    });

    console.log("✅ Order created:", order._id);

    intent.order = order._id;
    await intent.save();

    console.log("✅ Intent linked to order");

    const fullOrder = await Order.findById(order._id)
      .populate("items.product", "name images")
      .populate("voucher");

    console.log("🗑️ Removing items from cart...");
    try {
      const cart = await Cart.findOne({ user: userId });

      if (cart) {
        const orderProductIds = order.items.map((item) =>
          item.product.toString()
        );

        const beforeCount = cart.items.length;
        cart.items = cart.items.filter((cartItem) => {
          const productId = cartItem.product.toString();
          return !orderProductIds.includes(productId);
        });

        await cart.save();

        const removedCount = beforeCount - cart.items.length;
        console.log(`✅ Removed ${removedCount} items from cart`);
      }
    } catch (cartErr) {
      console.error("❌ Error removing cart items:", cartErr);
    }

    console.log("📧 Sending notifications...");
    try {
      await sendOrderEmail(req.user.email, fullOrder);
      await notifyNewOrder(userId, fullOrder);
      console.log("✅ Notifications sent");
    } catch (notifyErr) {
      console.error("❌ Error sending notifications:", notifyErr);
    }

    console.log("🎯 ========== CREATE ORDER FROM INTENT END ==========\n");

    return res.status(201).json({
      success: true,
      order: fullOrder,
      message: "Đặt hàng thành công",
    });
  } catch (error) {
    console.error("❌ Create order from intent error:", error);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};