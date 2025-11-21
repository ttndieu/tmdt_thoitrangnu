import Product from "../models/Product.js";
import Category from "../models/Category.js";
import slugify from "slugify";

// GET ALL PRODUCTS
export const getAllProducts = async (req, res) => {
  try {
    const products = await Product.find()
      .populate("category", "name slug");

    return res.json({ products });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// GET BY ID
export const getProductById = async (req, res) => {
  try {
    const prod = await Product.findById(req.params.id)
      .populate("category", "name slug");

    if (!prod) return res.status(404).json({ message: "Product not found" });

    return res.json({ product: prod });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// CREATE PRODUCT
export const createProduct = async (req, res) => {
  try {
    const { name, description, category, variants, images } = req.body;

    const cat = await Category.findOne({ slug: category });
    if (!cat)
      return res.status(400).json({ message: "Category not found" });

    const product = await Product.create({
      name,
      slug: slugify(name, { lower: true }),
      description,
      images,      // MUST BE array of {url, public_id}
      variants,
      category: cat._id,
    });

    return res.status(201).json({ product });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// UPDATE PRODUCT
export const updateProduct = async (req, res) => {
  try {
    const { name, description, category, variants, images } = req.body;

    let cat = null;
    if (category) {
      cat = await Category.findOne({ slug: category });
      if (!cat) return res.status(400).json({ message: "Category not found" });
    }

    const updated = await Product.findByIdAndUpdate(
      req.params.id,
      {
        name,
        slug: slugify(name, { lower: true }),
        description,
        images,    // MUST BE array of objects
        variants,
        category: cat ? cat._id : undefined,
      },
      { new: true }
    );

    return res.json({ product: updated });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// DELETE PRODUCT
export const deleteProduct = async (req, res) => {
  try {
    await Product.findByIdAndDelete(req.params.id);
    return res.json({ message: "Product deleted" });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
