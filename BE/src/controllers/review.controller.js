import Review from "../models/Review.js";
import Order from "../models/Order.js";

// --------------------------
// 1. User tạo review
// --------------------------
export const createReview = async (req, res) => {
  try {
    const { productId, rating, comment } = req.body;

    // Kiểm tra user đã mua sản phẩm chưa
    const purchased = await Order.findOne({
      user: req.user._id,
      "items.product": productId,
      status: { $in: ["completed", "shipping", "confirmed"] }
    });

    if (!purchased) {
      return res.status(403).json({
        message: "Bạn phải mua sản phẩm này mới được đánh giá"
      });
    }

    // Check nếu user đã review rồi
    const existing = await Review.findOne({
      user: req.user._id,
      product: productId,
    });

    if (existing) {
      return res.status(400).json({
        message: "Bạn đã review sản phẩm này rồi"
      });
    }

    const review = await Review.create({
      product: productId,
      user: req.user._id,
      rating,
      comment,
    });

    return res.status(201).json({ review });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// --------------------------
// 2. User xoá review
// --------------------------
export const deleteReview = async (req, res) => {
  try {
    const { reviewId } = req.params;

    const review = await Review.findById(reviewId);

    if (!review || review.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        message: "Không thể xoá review này"
      });
    }

    await review.deleteOne();

    return res.json({ message: "Đã xoá review" });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// --------------------------
// 3. User cập nhật review
// --------------------------
export const updateReview = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { rating, comment } = req.body;

    const review = await Review.findById(reviewId);

    if (!review || review.user.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        message: "Không thể sửa review này"
      });
    }

    review.rating = rating;
    review.comment = comment;

    await review.save();

    return res.json({ review });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};


// --------------------------
// 4. Lấy review theo sản phẩm
// --------------------------
export const getReviewsByProduct = async (req, res) => {
  try {
    const { productId } = req.params;

    const reviews = await Review.find({ product: productId })
      .populate("user", "name avatar");

    return res.json({ count: reviews.length, reviews });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
