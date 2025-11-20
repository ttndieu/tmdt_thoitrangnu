import Order from "../models/Order.js";
import Product from "../models/Product.js";
import User from "../models/User.js";

// 1) Dashboard tổng quan
export const getDashboardStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalOrders = await Order.countDocuments();
    const totalProducts = await Product.countDocuments();

    const totalRevenue = await Order.aggregate([
      { $match: { status: "completed" } },
      { $group: { _id: null, revenue: { $sum: "$totalAmount" } } }
    ]);

    return res.json({
      totalUsers,
      totalOrders,
      totalProducts,
      totalRevenue: totalRevenue[0]?.revenue || 0
    });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// 2) Top sản phẩm bán chạy
export const getTopProducts = async (req, res) => {
  try {
    const top = await Order.aggregate([
      { $unwind: "$items" },
      { $group: { _id: "$items.product", sold: { $sum: "$items.quantity" } } },
      { $sort: { sold: -1 } },
      { $limit: 10 }
    ]);

    return res.json({ top });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// 3) Doanh thu theo tháng
export const getRevenueByMonth = async (req, res) => {
  try {
    const revenue = await Order.aggregate([
      { $match: { status: "completed" } },
      {
        $group: {
          _id: { $month: "$createdAt" },
          revenue: { $sum: "$totalAmount" }
        }
      },
      { $sort: { "_id": 1 } }
    ]);

    return res.json(revenue);

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
