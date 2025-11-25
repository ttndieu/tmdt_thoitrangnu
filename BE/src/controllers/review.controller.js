import Review from "../models/Review.js";
import Product from "../models/Product.js";
import Order from "../models/Order.js";

// ------------------------------------------------------
// CREATE REVIEW (USER)
// ------------------------------------------------------
export const createReview = async (req, res) => {
  try {
    const { productId, orderId, rating, comment, images } = req.body;
    const userId = req.user._id;

    console.log(`\n⭐ ========== CREATE REVIEW ==========`);
    console.log(`👤 User: ${userId}`);
    console.log(`📦 Product: ${productId}`);
    console.log(`📝 Order: ${orderId}`);
    console.log(`⭐ Rating: ${rating}`);

    // ✅ VALIDATE required fields
    if (!productId || !orderId || !rating) {
      return res.status(400).json({
        message: "Thiếu thông tin bắt buộc (productId, orderId, rating)",
      });
    }

    // ✅ CHECK: Order có tồn tại và thuộc về user không?
    const order = await Order.findOne({
      _id: orderId,
      user: userId,
      status: "completed", // Chỉ review được khi order completed
    }).populate("items.product");

    if (!order) {
      return res.status(404).json({
        message: "Không tìm thấy đơn hàng hoặc đơn hàng chưa hoàn thành",
      });
    }

    // ✅ CHECK: Order có chứa product này không?
    const hasProduct = order.items.some(
      (item) => item.product._id.toString() === productId
    );

    if (!hasProduct) {
      return res.status(400).json({
        message: "Sản phẩm không có trong đơn hàng này",
      });
    }

    // ✅ CHECK: User đã review product này chưa?
    const existingReview = await Review.findOne({
      user: userId,
      product: productId,
    });

    if (existingReview) {
      return res.status(400).json({
        message: "Bạn đã đánh giá sản phẩm này rồi",
      });
    }

    // ✅ VALIDATE rating
    if (rating < 1 || rating > 5) {
      return res.status(400).json({
        message: "Rating phải từ 1-5 sao",
      });
    }

    // ✅ CREATE REVIEW
    const review = await Review.create({
      user: userId,
      product: productId,
      order: orderId,
      rating,
      comment: comment || "",
      images: images || [],
    });

    // ✅ UPDATE PRODUCT RATING
    await updateProductRating(productId);

    // Load review với thông tin user
    const fullReview = await Review.findById(review._id)
      .populate("user", "name avatar")
      .populate("product", "name images");

    console.log(`✅ Review created: ${review._id}`);
    console.log(`⭐ ========== CREATE REVIEW END ==========\n`);

    return res.status(201).json({ review: fullReview });
  } catch (err) {
    console.error("❌ Create review error:", err);
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// GET REVIEWS BY PRODUCT
// ------------------------------------------------------
export const getReviewsByProduct = async (req, res) => {
  try {
    const { productId } = req.params;
    const { page = 1, limit = 10, sort = "newest" } = req.query;

    console.log(`\n📋 Fetching reviews for product: ${productId}`);
    console.log(`📄 Page: ${page}, Limit: ${limit}, Sort: ${sort}`);

    let sortOption = { createdAt: -1 }; // Mặc định: mới nhất

    if (sort === "oldest") {
      sortOption = { createdAt: 1 };
    } else if (sort === "highest") {
      sortOption = { rating: -1, createdAt: -1 };
    } else if (sort === "lowest") {
      sortOption = { rating: 1, createdAt: -1 };
    }

    const reviews = await Review.find({ product: productId })
      .populate("user", "name avatar")
      .sort(sortOption)
      .limit(limit * 1)
      .skip((page - 1) * limit);

    const count = await Review.countDocuments({ product: productId });

    console.log(`✅ Found ${reviews.length} reviews (Total: ${count})`);

    return res.json({
      reviews,
      totalPages: Math.ceil(count / limit),
      currentPage: parseInt(page),
      total: count,
    });
  } catch (err) {
    console.error("❌ Get reviews error:", err);
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// GET MY REVIEWS (USER)
// ------------------------------------------------------
export const getMyReviews = async (req, res) => {
  try {
    const userId = req.user._id;

    console.log(`\n📋 Fetching reviews for user: ${userId}`);

    const reviews = await Review.find({ user: userId })
      .populate("product", "name images")
      .sort({ createdAt: -1 });

    console.log(`✅ Found ${reviews.length} reviews`);

    return res.json({ reviews });
  } catch (err) {
    console.error("❌ Get my reviews error:", err);
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// UPDATE REVIEW (USER)
// ------------------------------------------------------
export const updateReview = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const { rating, comment, images } = req.body;
    const userId = req.user._id;

    console.log(`\n✏️ Updating review: ${reviewId}`);

    const review = await Review.findById(reviewId);

    if (!review) {
      return res.status(404).json({ message: "Không tìm thấy đánh giá" });
    }

    // ✅ CHECK: Review có thuộc về user này không?
    if (review.user.toString() !== userId.toString()) {
      return res.status(403).json({
        message: "Bạn không có quyền sửa đánh giá này",
      });
    }

    // Update fields
    if (rating) {
      if (rating < 1 || rating > 5) {
        return res.status(400).json({
          message: "Rating phải từ 1-5 sao",
        });
      }
      review.rating = rating;
    }
    if (comment !== undefined) review.comment = comment;
    if (images !== undefined) review.images = images;

    await review.save();

    // ✅ UPDATE PRODUCT RATING
    await updateProductRating(review.product);

    const updatedReview = await Review.findById(reviewId)
      .populate("user", "name avatar")
      .populate("product", "name images");

    console.log(`✅ Review updated: ${reviewId}`);

    return res.json({ review: updatedReview });
  } catch (err) {
    console.error("❌ Update review error:", err);
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// DELETE REVIEW (USER or ADMIN)
// ------------------------------------------------------
export const deleteReview = async (req, res) => {
  try {
    const { reviewId } = req.params;
    const userId = req.user._id;
    const userRole = req.user.role;

    console.log(`\n🗑️ Deleting review: ${reviewId}`);

    const review = await Review.findById(reviewId);

    if (!review) {
      return res.status(404).json({ message: "Không tìm thấy đánh giá" });
    }

    // ✅ CHECK: User sở hữu review hoặc là admin
    if (review.user.toString() !== userId.toString() && userRole !== "admin") {
      return res.status(403).json({
        message: "Bạn không có quyền xóa đánh giá này",
      });
    }

    const productId = review.product;
    await Review.findByIdAndDelete(reviewId);

    // ✅ UPDATE PRODUCT RATING
    await updateProductRating(productId);

    console.log(`✅ Review deleted: ${reviewId}`);

    return res.json({ message: "Đã xóa đánh giá" });
  } catch (err) {
    console.error("❌ Delete review error:", err);
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// CHECK CAN REVIEW (USER)
// ------------------------------------------------------
export const checkCanReview = async (req, res) => {
  try {
    const { productId } = req.params;
    const userId = req.user._id;

    console.log(`\n🔍 Checking can review for product: ${productId}`);

    // ✅ CHECK: User có order completed chứa product này không?
    const completedOrder = await Order.findOne({
      user: userId,
      status: "completed",
      "items.product": productId,
    }).sort({ createdAt: -1 });

    if (!completedOrder) {
      console.log(`❌ User hasn't purchased this product`);
      return res.json({
        canReview: false,
        reason: "Bạn chưa mua sản phẩm này",
      });
    }

    // ✅ CHECK: User đã review chưa?
    const existingReview = await Review.findOne({
      user: userId,
      product: productId,
    });

    if (existingReview) {
      console.log(`❌ User already reviewed this product`);
      return res.json({
        canReview: false,
        reason: "Bạn đã đánh giá sản phẩm này",
        existingReview: {
          id: existingReview._id,
          rating: existingReview.rating,
          comment: existingReview.comment,
        },
      });
    }

    console.log(`✅ User can review this product`);
    console.log(`📝 Order ID: ${completedOrder._id}`);

    return res.json({
      canReview: true,
      orderId: completedOrder._id,
    });
  } catch (err) {
    console.error("❌ Check can review error:", err);
    return res.status(500).json({ message: err.message });
  }
};

// ------------------------------------------------------
// HELPER: UPDATE PRODUCT RATING
// ------------------------------------------------------
async function updateProductRating(productId) {
  try {
    const reviews = await Review.find({ product: productId });

    if (reviews.length === 0) {
      await Product.findByIdAndUpdate(productId, {
        averageRating: 0,
        reviewCount: 0,
      });
      console.log(`✅ Reset rating for product ${productId}`);
      return;
    }

    const totalRating = reviews.reduce((sum, review) => sum + review.rating, 0);
    const averageRating = totalRating / reviews.length;

    await Product.findByIdAndUpdate(productId, {
      averageRating: Math.round(averageRating * 10) / 10, // Round to 1 decimal
      reviewCount: reviews.length,
    });

    console.log(
      `✅ Updated product ${productId} rating: ${averageRating.toFixed(1)} (${reviews.length} reviews)`
    );
  } catch (err) {
    console.error(`❌ Error updating product rating:`, err);
  }
}