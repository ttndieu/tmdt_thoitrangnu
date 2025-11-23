// backend/controllers/wishlist.controller.js

import User from "../models/User.js";
import Product from "../models/Product.js";

// Lấy danh sách yêu thích (FIXED)
export const getWishlist = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate({
      path: "wishlist",
      populate: [
        { 
          path: "category", 
          select: "name slug" 
        },
        { 
          path: "images",
          select: "url alt"
        }
      ]
    });

    if (!user) {
      return res.status(404).json({ message: "User not found" });
    }

    // Filter out null products (nếu product đã bị xóa)
    const validWishlist = user.wishlist.filter(item => item !== null);

    return res.json({ 
      success: true,
      wishlist: validWishlist 
    });
  } catch (err) {
    console.error("❌ Get wishlist error:", err);
    return res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
};

// Thêm sản phẩm vào wishlist (FIXED)
export const addWishlist = async (req, res) => {
  try {
    const { productId } = req.params;

    // Check product exists
    const product = await Product.findById(productId);
    if (!product) {
      return res.status(404).json({ 
        success: false,
        message: "Product not found" 
      });
    }

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: "User not found" 
      });
    }

    // Check if already in wishlist
    if (user.wishlist.includes(productId)) {
      return res.status(400).json({ 
        success: false,
        message: "Product already in wishlist" 
      });
    }

    // Add to wishlist
    user.wishlist.push(productId);
    await user.save();

    // Populate and return
    await user.populate({
      path: "wishlist",
      populate: [
        { path: "category", select: "name slug" },
        { path: "images", select: "url alt" }
      ]
    });

    return res.json({ 
      success: true,
      message: "Added to wishlist",
      wishlist: user.wishlist 
    });
  } catch (err) {
    console.error("Add wishlist error:", err);
    return res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
};

// Xóa 1 sản phẩm khỏi wishlist (FIXED)
export const removeWishlist = async (req, res) => {
  try {
    const { productId } = req.params;

    const user = await User.findById(req.user._id);
    if (!user) {
      return res.status(404).json({ 
        success: false,
        message: "User not found" 
      });
    }

    // Remove from wishlist
    user.wishlist = user.wishlist.filter(
      (id) => id.toString() !== productId
    );

    await user.save();

    // Populate and return
    await user.populate({
      path: "wishlist",
      populate: [
        { path: "category", select: "name slug" },
        { path: "images", select: "url alt" }
      ]
    });

    return res.json({ 
      success: true,
      message: "Removed from wishlist",
      wishlist: user.wishlist 
    });
  } catch (err) {
    console.error("Remove wishlist error:", err);
    return res.status(500).json({ 
      success: false,
      message: err.message 
    });
  }
};