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

    // ✅ CHECK TỒN KHO & TÍNH TỔNG
    let originalAmount = 0;

    console.log(`\n🔍 ========== VALIDATE STOCK ==========`);
    for (let item of itemsToOrder) {
      const product = item.product;
      
      console.log(`\n📦 Product: ${product.name || product._id}`);
      console.log(`   Size: ${item.size}`);
      console.log(`   Color: ${item.color}`);
      console.log(`   Quantity: ${item.quantity}`);
      
      // ✅ CHECK: Product có variants không?
      if (!product.variants || !Array.isArray(product.variants)) {
        console.log(`❌ Product ${product._id} has no variants array!`);
        return res.status(400).json({
          message: `Sản phẩm ${product.name} không có thông tin variants`
        });
      }
      
      console.log(`   Available variants count: ${product.variants.length}`);
      
      // ✅ TÌM VARIANT
      const variant = product.variants.find(
        (v) => v.size === item.size && v.color === item.color
      );

      if (!variant) {
        console.log(`❌ Variant NOT FOUND!`);
        console.log(`   Available variants:`, product.variants.map(v => ({
          size: v.size,
          color: v.color,
          stock: v.stock
        })));
        
        return res.status(400).json({
          message: `Không tìm thấy size ${item.size} màu ${item.color} cho ${product.name}`
        });
      }
      
      console.log(`   ✅ Variant found:`);
      console.log(`      Current stock: ${variant.stock}`);
      console.log(`      Price: ${variant.price}`);
      
      if (variant.stock < item.quantity) {
        console.log(`❌ Not enough stock! (Need ${item.quantity}, Have ${variant.stock})`);
        return res.status(400).json({
          message: `Không đủ hàng cho ${product.name} (Còn ${variant.stock})`
        });
      }

      originalAmount += variant.price * item.quantity;
      console.log(`   Subtotal: ${variant.price * item.quantity}`);
    }

    console.log(`\n💰 Original amount: ${originalAmount}`);
    console.log(`🔍 ========== VALIDATE STOCK END ==========\n`);

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

    // ✅ TRỪ STOCK (CHỈ COD, VNPAY SẼ TRỪ SAU)
    if (paymentMethod === 'cod') {
      console.log('\n📦 ========== DEDUCT STOCK (COD) ==========');
      console.log(`Processing ${itemsToOrder.length} items...`);
      
      for (let i = 0; i < itemsToOrder.length; i++) {
        const item = itemsToOrder[i];
        const product = item.product;
        
        console.log(`\n[${i+1}/${itemsToOrder.length}] Processing: ${product.name}`);
        console.log(`   Product ID: ${product._id}`);
        console.log(`   Size: ${item.size}`);
        console.log(`   Color: ${item.color}`);
        console.log(`   Quantity: ${item.quantity}`);
        
        try {
          // ✅ TRỪ STOCK - DÙNG arrayFilters
          const stockUpdateResult = await Product.updateOne(
            {
              _id: product._id
            },
            { 
              $inc: { "variants.$[elem].stock": -item.quantity } 
            },
            {
              arrayFilters: [
                { 
                  "elem.size": item.size,
                  "elem.color": item.color
                }
              ]
            }
          );
          
          console.log(`   Stock update result:`, {
            matched: stockUpdateResult.matchedCount,
            modified: stockUpdateResult.modifiedCount,
            acknowledged: stockUpdateResult.acknowledged
          });
          
          if (stockUpdateResult.modifiedCount === 0) {
            console.log(`   ⚠️ WARNING: Stock NOT modified!`);
            console.log(`   ⚠️ This variant may not exist or arrayFilters didn't match`);
          } else {
            console.log(`   ✅ Stock deducted: -${item.quantity}`);
          }
          
          // ✅ TĂNG SOLD
          const soldUpdateResult = await Product.findByIdAndUpdate(
            product._id,
            { $inc: { sold: item.quantity } },
            { new: true, select: 'sold' }
          );
          
          console.log(`   Sold updated:`, {
            newSold: soldUpdateResult?.sold,
            increment: item.quantity
          });
          
          if (!soldUpdateResult) {
            console.log(`   ⚠️ WARNING: Product not found for sold update!`);
          } else {
            console.log(`   ✅ Sold increased: +${item.quantity} (Total: ${soldUpdateResult.sold})`);
          }
          
          // ✅ VERIFY: Fetch lại product để check
          const verifyProduct = await Product.findById(product._id);
          const verifyVariant = verifyProduct.variants.find(
            v => v.size === item.size && v.color === item.color
          );
          console.log(`   🔍 VERIFY: Stock after update = ${verifyVariant?.stock}`);
          
        } catch (updateError) {
          console.error(`   ❌ Error updating product ${product._id}:`, updateError);
          console.error(`   ❌ Error message:`, updateError.message);
          console.error(`   ❌ Error stack:`, updateError.stack);
        }
      }
      
      console.log('\n✅ Stock deduction completed');
      console.log('📦 ========== DEDUCT STOCK (COD) END ==========\n');
      
    } else {
      console.log('🏦 VNPay payment - Stock will be deducted after payment success');
    }

    // ✅ Tạo đơn hàng
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
      status: "pending",
      paymentStatus: paymentMethod === 'vnpay' ? 'pending' : 'pending',
    });

    // Load order với product info
    const fullOrder = await Order.findById(order._id)
      .populate("items.product", "name images")
      .populate("voucher");

    console.log(`✅ Order created: ${order._id}`);
    console.log(`📊 Status: ${order.status}`);
    console.log(`💳 Payment status: ${order.paymentStatus}`);

    // ✅ XỬ LÝ CART
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
        // Hoàn stock - DÙNG arrayFilters
        await Product.updateOne(
          {
            _id: item.product._id
          },
          { 
            $inc: { "variants.$[elem].stock": item.quantity } 
          },
          {
            arrayFilters: [
              { 
                "elem.size": item.size,
                "elem.color": item.color
              }
            ]
          }
        );
        
        // ✅ Giảm sold count
        await Product.findByIdAndUpdate(
          item.product._id,
          { $inc: { sold: -item.quantity } }
        );
        
        console.log(`✅ Hoàn lại ${item.quantity} sản phẩm ${item.product.name}`);
        console.log(`✅ Giảm ${item.quantity} sold count`);
      } catch (productErr) {
        console.error(`❌ Error restoring stock for product ${item.product._id}:`, productErr);
      }
    }

    // ✅ HOÀN LẠI VOUCHER (NẾU CÓ)
    if (order.voucher) {
      console.log(`🎫 Hoàn lại voucher: ${order.voucherCode}`);
      
      try {
        const voucher = await Voucher.findById(order.voucher);
        
        if (voucher) {
          voucher.quantity += 1;
          
          if (voucher.usedBy && Array.isArray(voucher.usedBy)) {
            voucher.usedBy = voucher.usedBy.filter(
              uid => uid.toString() !== userId.toString()
            );
          }
          
          await voucher.save();
          
          console.log(`✅ Đã hoàn lại voucher ${order.voucherCode}`);
        } else {
          console.log(`⚠️ Voucher ${order.voucher} not found, skipping restore`);
        }
      } catch (voucherErr) {
        console.error(`❌ Error restoring voucher:`, voucherErr);
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

// ------------------------------------------------------
// ✅ TẠO ORDER TỪ PAYMENT INTENT (VNPAY)
// ------------------------------------------------------
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

    // ✅ VALIDATE STOCK
    console.log('\n🔍 ========== VALIDATE STOCK ==========');
    for (let item of intent.items) {
      const product = await Product.findById(item.product._id);
      
      if (!product) {
        console.log(`❌ Product not found: ${item.product._id}`);
        return res.status(400).json({
          success: false,
          message: `Product ${item.product.name} not found`,
        });
      }
      
      console.log(`\n📦 Product: ${product.name}`);
      console.log(`   Size: ${item.size}`);
      console.log(`   Color: ${item.color}`);
      console.log(`   Quantity: ${item.quantity}`);

      const variant = product.variants.find(
        (v) => v.size === item.size && v.color === item.color
      );

      if (!variant) {
        console.log(`❌ Variant NOT FOUND!`);
        console.log(`   Available variants:`, product.variants.map(v => ({
          size: v.size,
          color: v.color,
          stock: v.stock
        })));
        
        return res.status(400).json({
          success: false,
          message: `Không tìm thấy size ${item.size} màu ${item.color} cho ${product.name}`,
        });
      }
      
      console.log(`   ✅ Variant found:`);
      console.log(`      Current stock: ${variant.stock}`);
      
      if (variant.stock < item.quantity) {
        console.log(`❌ Not enough stock! (Need ${item.quantity}, Have ${variant.stock})`);
        return res.status(400).json({
          success: false,
          message: `Not enough stock for ${product.name}`,
        });
      }
    }

    console.log("✅ Stock validated");
    console.log('🔍 ========== VALIDATE STOCK END ==========\n');

    // ✅ TRỪ STOCK VÀ TĂNG SOLD
    console.log('\n📦 ========== DEDUCT STOCK (VNPAY) ==========');
    console.log(`Processing ${intent.items.length} items...`);

    for (let i = 0; i < intent.items.length; i++) {
      const item = intent.items[i];
      const product = await Product.findById(item.product._id);
      
      if (!product) {
        console.log(`❌ Product not found: ${item.product._id}`);
        continue;
      }
      
      console.log(`\n[${i+1}/${intent.items.length}] Processing: ${product.name}`);
      console.log(`   Product ID: ${product._id}`);
      console.log(`   Size: ${item.size}`);
      console.log(`   Color: ${item.color}`);
      console.log(`   Quantity: ${item.quantity}`);
      
      try {
        // ✅ TRỪ STOCK - DÙNG arrayFilters
        const stockUpdateResult = await Product.updateOne(
          {
            _id: product._id
          },
          { 
            $inc: { "variants.$[elem].stock": -item.quantity } 
          },
          {
            arrayFilters: [
              { 
                "elem.size": item.size,
                "elem.color": item.color
              }
            ]
          }
        );
        
        console.log(`   Stock update result:`, {
          matched: stockUpdateResult.matchedCount,
          modified: stockUpdateResult.modifiedCount,
          acknowledged: stockUpdateResult.acknowledged
        });
        
        if (stockUpdateResult.modifiedCount === 0) {
          console.log(`   ⚠️ WARNING: Stock NOT modified!`);
        } else {
          console.log(`   ✅ Stock deducted: -${item.quantity}`);
        }

        // ✅ TĂNG SOLD
        const soldUpdateResult = await Product.findByIdAndUpdate(
          product._id,
          { $inc: { sold: item.quantity } },
          { new: true, select: 'sold' }
        );
        
        console.log(`   Sold updated:`, {
          newSold: soldUpdateResult?.sold,
          increment: item.quantity
        });
        
        if (!soldUpdateResult) {
          console.log(`   ⚠️ WARNING: Product not found for sold update!`);
        } else {
          console.log(`   ✅ Sold increased: +${item.quantity} (Total: ${soldUpdateResult.sold})`);
        }

        // ✅ VERIFY: Fetch lại product để check
        const verifyProduct = await Product.findById(product._id);
        const verifyVariant = verifyProduct.variants.find(
          v => v.size === item.size && v.color === item.color
        );
        console.log(`   🔍 VERIFY: Stock after update = ${verifyVariant?.stock}`);

      } catch (productErr) {
        console.error(`   ❌ Error updating product ${product._id}:`, productErr);
        console.error(`   ❌ Error message:`, productErr.message);
      }
    }

    console.log('\n✅ Stock deduction completed');
    console.log('📦 ========== DEDUCT STOCK (VNPAY) END ==========\n');

    // ✅ TẠO ORDER
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

    // ✅ XÓA ITEMS KHỎI CART
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

    // ✅ GỬI NOTIFICATION & EMAIL
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
    console.error("❌ Error stack:", error.stack);
    return res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};