import Category from "../models/Category.js";
import Product from "../models/Product.js"; 
import slugify from "slugify";

// GET /api/category
export const getAllCategories = async (req, res) => {
  try {
    // Lấy danh sách category
    const categories = await Category.find().sort({ createdAt: -1 });

    // Thêm số lượng sản phẩm trong mỗi danh mục
    const data = await Promise.all(
      categories.map(async (c) => {
        const count = await Product.countDocuments({ category: c._id  });
        return {
          ...c.toObject(),
          count,
        };
      })
    );

    return res.json({ success: true, data });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// POST /api/category
export const createCategory = async (req, res) => {
  try {
    const { name } = req.body;

    const slug = slugify(name, { lower: true });

    const exists = await Category.findOne({ slug });
    if (exists) return res.status(400).json({ message: "Category exists" });

    const category = await Category.create({ name, slug });

    return res.status(201).json({ success: true, data: category });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// PUT /api/category/:id
export const updateCategory = async (req, res) => {
  try {
    const { name } = req.body;

    const slug = slugify(name, { lower: true });

    const updated = await Category.findByIdAndUpdate(
      req.params.id,
      { name, slug },
      { new: true }
    );

    return res.json({ success: true, data: updated });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// DELETE /api/category/:id
export const deleteCategory = async (req, res) => {
  try {
    await Category.findByIdAndDelete(req.params.id);
    return res.json({ success: true, message: "Category deleted" });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
