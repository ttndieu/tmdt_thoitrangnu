// be/src/services/notification.service.js

import Notification from "../models/Notification.js";

export const createNotification = async (userId, type, title, message, data = {}) => {
  try {
    const notification = await Notification.create({
      user: userId,
      type,
      title,
      message,
      data,
    });
    return notification;
  } catch (err) {
    console.error("Create notification error:", err);
  }
};

// Helper functions cho từng loại notification

export const notifyOrderStatusChange = async (userId, orderId, status) => {
  const titles = {
    confirmed: "✅ Đơn hàng đã được xác nhận",
    shipping: "🚚 Đơn hàng đang được vận chuyển",
    completed: "🎉 Đơn hàng đã được giao thành công",
    cancelled: "❌ Đơn hàng đã bị hủy",
  };

  const messages = {
    confirmed: `Đơn hàng #${orderId.toString().slice(-6)} đã được xác nhận và đang được chuẩn bị.`,
    shipping: `Đơn hàng #${orderId.toString().slice(-6)} đang trên đường giao đến bạn.`,
    completed: `Đơn hàng #${orderId.toString().slice(-6)} đã được giao thành công. Cảm ơn bạn đã mua hàng!`,
    cancelled: `Đơn hàng #${orderId.toString().slice(-6)} đã bị hủy. Liên hệ chúng tôi nếu cần hỗ trợ.`,
  };

  await createNotification(
    userId,
    "order",
    titles[status],
    messages[status],
    { orderId: orderId.toString(), status }
  );
};

export const notifyNewOrder = async (userId, orderId, totalAmount) => {
  await createNotification(
    userId,
    "order",
    "📦 Đơn hàng đã được tạo",
    `Đơn hàng #${orderId.toString().slice(-6)} với tổng giá trị ${totalAmount.toLocaleString()}đ đã được tạo thành công.`,
    { orderId: orderId.toString(), totalAmount }
  );
};

export const notifyNewVoucher = async (userId, voucherCode, discountPercent) => {
  await createNotification(
    userId,
    "promotion",
    "🎁 Mã giảm giá mới dành cho bạn",
    `Sử dụng mã ${voucherCode} để được giảm ${discountPercent}% cho đơn hàng tiếp theo!`,
    { voucherCode, discountPercent }
  );
};

export const notifyWishlistBackInStock = async (userId, productId, productName) => {
  await createNotification(
    userId,
    "product",
    "🔥 Sản phẩm yêu thích đã về hàng",
    `${productName} đã quay lại kho. Đặt hàng ngay kẻo hết!`,
    { productId: productId.toString() }
  );
};

export const notifyVoucherExpiring = async (userId, voucherCode, daysLeft) => {
  await createNotification(
    userId,
    "promotion",
    "⏰ Mã giảm giá sắp hết hạn",
    `Mã ${voucherCode} sẽ hết hạn trong ${daysLeft} ngày. Sử dụng ngay!`,
    { voucherCode, daysLeft }
  );
};