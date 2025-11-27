// be/src/controllers/admin.controller.js
import Order from "../models/Order.js";
import Product from "../models/Product.js";
import User from "../models/User.js";
import Category from "../models/Category.js";

export const getDashboardStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const totalOrders = await Order.countDocuments();
    const totalProducts = await Product.countDocuments();

    const totalRevenueAgg = await Order.aggregate([
      { $match: { status: "completed" } },
      { $group: { _id: null, revenue: { $sum: "$totalAmount" } } }
    ]);
    const totalRevenue = totalRevenueAgg[0]?.revenue || 0;

    const statusAgg = await Order.aggregate([
      { $group: { _id: "$status", count: { $sum: 1 } } }
    ]);

    const orders = { pending: 0, confirmed: 0, shipping: 0, completed: 0, cancelled: 0 };
    statusAgg.forEach(s => orders[s._id] = s.count);

    return res.json({
      totalUsers,
      totalOrders,
      totalProducts,
      totalRevenue,
      orders
    });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


export const getRevenueByMonth = async (req, res) => {
  try {
    const agg = await Order.aggregate([
      { $match: { status: "completed" } },
      {
        $group: {
          _id: { year: { $year: "$createdAt" }, month: { $month: "$createdAt" } },
          revenue: { $sum: "$totalAmount" }
        }
      },
      { $sort: { "_id.year": 1, "_id.month": 1 } },
    ]);

    const out = agg.map(a => {
      const y = a._id.year;
      const m = String(a._id.month).padStart(2, "0");
      return { month: `${y}-${m}`, revenue: a.revenue };
    });

    return res.json(out);

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


export const getRevenueByCategory = async (req, res) => {
  try {
    const agg = await Order.aggregate([
      { $match: { status: "completed" } },
      { $unwind: "$items" },
      {
        $group: {
          _id: "$items.product",
          revenue: { $sum: { $multiply: ["$items.price", "$items.quantity"] } }
        }
      },
      {
        $lookup: {
          from: "products",
          localField: "_id",
          foreignField: "_id",
          as: "product"
        }
      },
      { $unwind: "$product" },
      {
        $lookup: {
          from: "categories",
          localField: "product.category",
          foreignField: "_id",
          as: "category"
        }
      },
      { $unwind: { path: "$category", preserveNullAndEmptyArrays: true } },
      {
        $group: {
          _id: "$category._id",
          name: { $first: "$category.name" },
          revenue: { $sum: "$revenue" }
        }
      },
      { $sort: { revenue: -1 } }
    ]);

    return res.json(agg.map(a => ({
      categoryId: a._id,
      name: a.name || "Uncategorized",
      revenue: a.revenue
    })));

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


export const getTopProducts = async (req, res) => {
  try {
    const agg = await Order.aggregate([
      { $unwind: "$items" },
      { $group: { _id: "$items.product", sold: { $sum: "$items.quantity" } } },
      { $sort: { sold: -1 } },
      { $limit: 10 },
      {
        $lookup: {
          from: "products",
          localField: "_id",
          foreignField: "_id",
          as: "product"
        }
      },
      { $unwind: "$product" },
      {
        $project: {
          _id: 0,
          productId: "$product._id",
          name: "$product.name",
          images: "$product.images",
          sold: 1
        }
      }
    ]);

    return res.json(agg);

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// import Order from "../models/Order.js";
// import Product from "../models/Product.js";
// import User from "../models/User.js";

// // 1) Dashboard tổng quan
// export const getDashboardStats = async (req, res) => {
//   try {
//     const totalUsers = await User.countDocuments();
//     const totalOrders = await Order.countDocuments();
//     const totalProducts = await Product.countDocuments();

//     const totalRevenue = await Order.aggregate([
//       { $match: { status: "completed" } },
//       { $group: { _id: null, revenue: { $sum: "$totalAmount" } } }
//     ]);

//     return res.json({
//       totalUsers,
//       totalOrders,
//       totalProducts,
//       totalRevenue: totalRevenue[0]?.revenue || 0
//     });

//   } catch (err) {
//     return res.status(500).json({ message: err.message });
//   }
// };


// // 2) Top sản phẩm bán chạy
// export const getTopProducts = async (req, res) => {
//   try {
//     const top = await Order.aggregate([
//       { $unwind: "$items" },
//       { $group: { _id: "$items.product", sold: { $sum: "$items.quantity" } } },
//       { $sort: { sold: -1 } },
//       { $limit: 10 }
//     ]);

//     return res.json({ top });
//   } catch (err) {
//     return res.status(500).json({ message: err.message });
//   }
// };


// // 3) Doanh thu theo tháng
// export const getRevenueByMonth = async (req, res) => {
//   try {
//     const revenue = await Order.aggregate([
//       { $match: { status: "completed" } },
//       {
//         $group: {
//           _id: { $month: "$createdAt" },
//           revenue: { $sum: "$totalAmount" }
//         }
//       },
//       { $sort: { "_id": 1 } }
//     ]);

//     return res.json(revenue);

//   } catch (err) {
//     return res.status(500).json({ message: err.message });
//   }
// };
