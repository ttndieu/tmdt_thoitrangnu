import Product from "../models/Product.js";
import Category from "../models/Category.js";

// GET /api/products
export const getAllProducts = async (req, res) => {
  try {
    const { keyword, category, size } = req.query;

    let filters = {};

    // Search theo tên
    if (keyword) {
      filters.name = { $regex: keyword, $options: "i" };
    }

    // Lọc theo category
    if (category) {
      const cat = await Category.findOne({ slug: category });
      if (cat) filters.category = cat._id;
    }

    // Lọc theo size
    if (size) {
      filters["variants.size"] = size;
    }

    const products = await Product.find(filters).populate("category", "name slug");

    return res.json({ count: products.length, products });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// GET /api/products/:id
export const getProductById = async (req, res) => {
  try {
    const prod = await Product.findById(req.params.id).populate("category", "name");

    if (!prod) return res.status(404).json({ message: "Product not found" });

    return res.json({ product: prod });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// POST /api/products (admin)
export const createProduct = async (req, res) => {
  try {
    const { name, slug, description, category, variants, images } = req.body;

    const cat = await Category.findOne({ slug: category });
    if (!cat) return res.status(400).json({ message: "Category not found" });

    const product = await Product.create({
      name,
      slug,
      description,
      category: cat._id,
      variants,
      images,
    });

    return res.status(201).json({ product });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// PUT /api/products/:id (admin)
export const updateProduct = async (req, res) => {
  try {
    const updated = await Product.findByIdAndUpdate(
      req.params.id,
      req.body,
      { new: true }
    );

    return res.json({ product: updated });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// DELETE /api/products/:id (admin)
export const deleteProduct = async (req, res) => {
  try {
    await Product.findByIdAndDelete(req.params.id);
    return res.json({ message: "Product deleted" });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
