import Order from "../models/Order.js";
import Cart from "../models/Cart.js";
import Product from "../models/Product.js";
import { sendOrderEmail } from "../services/mail.service.js";
import { notifyNewOrder, notifyOrderStatusChange } from "../services/notification.service.js";

// POST /api/orders
export const createOrder = async (req, res) => {
  try {
    const { paymentMethod, shippingAddress } = req.body;

    const cart = await Cart.findOne({ user: req.user._id }).populate("items.product");

    if (!cart || cart.items.length === 0)
      return res.status(400).json({ message: "Cart is empty" });

    let total = 0;

    // Check tồn kho và tính tổng tiền
    for (let item of cart.items) {
      const product = item.product;
      const variant = product.variants.find(
        (v) => v.size === item.size && v.color === item.color
      );

      if (!variant || variant.stock < item.quantity)
        return res.status(400).json({ message: `Not enough stock for ${product.name}` });

      total += variant.price * item.quantity;
    }

    // Trừ tồn kho
    for (let item of cart.items) {
      await Product.updateOne(
        {
          _id: item.product._id,
          "variants.size": item.size,
          "variants.color": item.color,
        },
        {
          $inc: { "variants.$.stock": -item.quantity },
        }
      );
    }

    // Tạo order
    const order = await Order.create({
      user: req.user._id,
      items: cart.items.map((i) => ({
        product: i.product._id,
        quantity: i.quantity,
        size: i.size,
        color: i.color,
        price: i.product.variants.find(
          (v) => v.size === i.size && v.color === i.color
        ).price,
      })),
      totalAmount: total,
      paymentMethod,
      shippingAddress,
      status: "pending",
    });

    // Gửi notification cho user
    await notifyNewOrder(req.user._id, order._id, total);
    // Gửi email cho user
await sendOrderEmail(req.user.email, order);

    // Xóa giỏ hàng sau khi đặt hàng thành công
    cart.items = [];
    await cart.save();

    return res.status(201).json({ order });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// GET /api/orders (user orders)
export const getMyOrders = async (req, res) => {
  try {
    const orders = await Order.find({ user: req.user._id }).populate(
      "items.product",
      "name images"
    );

    return res.json({ orders });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// GET /api/orders/admin (admin only)
export const getAllOrders = async (req, res) => {
  try {
    const orders = await Order.find()
      .populate("user", "name email")
      .populate("items.product", "name images");

    return res.json({ count: orders.length, orders });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// PUT /api/orders/:id/status (admin updates status)
// PUT /api/orders/:id/status
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
    ).populate("user", "email");

    if (!order)
      return res.status(404).json({ message: "Order not found" });

    // Gửi notification khi trạng thái thay đổi
    if (["confirmed", "shipping", "completed", "cancelled"].includes(status)) {
      await notifyOrderStatusChange(order.user._id, order._id, status);
    }

    return res.json({ order });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
