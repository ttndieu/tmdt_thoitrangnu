import Category from "../models/Category.js";

// GET /api/category
export const getAllCategories = async (req, res) => {
  try {
    const categories = await Category.find();
    return res.json({ categories });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// POST /api/category (admin)
export const createCategory = async (req, res) => {
  try {
    const { name, slug } = req.body;

    const exists = await Category.findOne({ slug });
    if (exists) return res.status(400).json({ message: "Slug already exists" });

    const category = await Category.create({ name, slug });

    return res.status(201).json({ category });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// PUT /api/category/:id (admin)
export const updateCategory = async (req, res) => {
  try {
    const { name, slug } = req.body;

    const updated = await Category.findByIdAndUpdate(
      req.params.id,
      { name, slug },
      { new: true }
    );

    return res.json({ category: updated });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// DELETE /api/category/:id (admin)
export const deleteCategory = async (req, res) => {
  try {
    await Category.findByIdAndDelete(req.params.id);
    return res.json({ message: "Category deleted" });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
