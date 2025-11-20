import User from "../models/User.js";
import Product from "../models/Product.js";


// Lấy danh sách yêu thích
export const getWishlist = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).populate("wishlist");
    return res.json({ wishlist: user.wishlist });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// Thêm sản phẩm vào wishlist
export const addWishlist = async (req, res) => {
  try {
    const { productId } = req.params;

    const user = await User.findById(req.user._id);

    // Nếu sản phẩm không tồn tại
    const product = await Product.findById(productId);
    if (!product)
      return res.status(404).json({ message: "Product not found" });

    // Nếu chưa có sản phẩm trong wishlist
    if (!user.wishlist.includes(productId)) {
      user.wishlist.push(productId);
      await user.save();
    }

    return res.json({ wishlist: user.wishlist });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// Xóa 1 sản phẩm khỏi wishlist
export const removeWishlist = async (req, res) => {
  try {
    const { productId } = req.params;

    const user = await User.findById(req.user._id);

    user.wishlist = user.wishlist.filter(
      (id) => id.toString() !== productId
    );

    await user.save();

    return res.json({ wishlist: user.wishlist });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
