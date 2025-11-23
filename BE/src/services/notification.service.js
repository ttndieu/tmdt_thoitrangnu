import Notification from "../models/Notification.js";

// -------------------------------------------
// NOTIFICATION RIÊNG → dành cho đơn hàng, admin
// -------------------------------------------
export const createNotification = async (
  userId,
  type,
  title,
  message,
  data = {}
) => {
  try {
    return await Notification.create({
      user: userId,
      audience: "user",
      type,
      title,
      message,
      data,
    });
  } catch (err) {
    console.error("Create notification error:", err);
  }
};

// -------------------------------------------
// ORDER STATUS
// -------------------------------------------
export const notifyOrderStatusChange = async (userId, order, status) => {
  const titles = {
    confirmed: "✅ Đơn hàng đã được xác nhận",
    shipping: "🚚 Đơn hàng đang được vận chuyển",
    completed: "🎉 Đơn hàng đã được giao thành công",
    cancelled: "❌ Đơn hàng đã bị hủy",
  };

  const messages = {
    confirmed: `Đơn hàng #${order._id.toString().slice(-6)} đã được xác nhận.`,
    shipping: `Đơn hàng #${order._id.toString().slice(-6)} đang được vận chuyển.`,
    completed: `Đơn hàng #${order._id.toString().slice(-6)} đã hoàn thành.`,
    cancelled: `Đơn hàng #${order._id.toString().slice(-6)} đã bị hủy.`,
  };

  await createNotification(
    userId,
    "order",
    titles[status],
    messages[status],
    { orderId: order._id.toString(), status }
  );
};

// -------------------------------------------
// ORDER CREATED FOR USER & ADMIN
// -------------------------------------------
export const notifyNewOrder = async (userId, order) => {
  const shortId = order._id.toString().slice(-6);

  await createNotification(
    userId,
    "order",
    "📦 Đơn hàng đã được tạo",
    `Đơn hàng #${shortId} đã được đặt thành công.`,
    { orderId: order._id.toString(), totalAmount: order.totalAmount }
  );

  const ADMIN_ID = process.env.ADMIN_USER_ID;
  if (ADMIN_ID) {
    await createNotification(
      ADMIN_ID,
      "system",
      "🛒 Có đơn hàng mới",
      `Đơn hàng #${shortId} vừa được tạo.`,
      { orderId: order._id.toString(), fromUser: userId.toString() }
    );
  }
};

// -------------------------------------------
// BROADCAST VOUCHER — chỉ 1 record
// -------------------------------------------
export const notifyAllUsers = async (type, title, message, data = {}) => {
  try {
    await Notification.create({
      audience: "all",
      type,
      title,
      message,
      data,
    });
  } catch (err) {
    console.error("Notify all users error:", err);
  }
};
