import Cart from "../models/Cart.js";
import Product from "../models/Product.js";

// GET /api/cart
export const getCart = async (req, res) => {
  try {
    const cart = await Cart.findOne({ user: req.user._id })
      .populate("items.product");

    return res.json({ cart: cart || { items: [] } });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// POST /api/cart (add item)
export const addToCart = async (req, res) => {
  try {
    const { productId, size, color, quantity } = req.body;

    const product = await Product.findById(productId);
    if (!product) return res.status(404).json({ message: "Product not found" });

    // check variant
    const variant = product.variants.find(
      (v) => v.size === size && v.color === color
    );
    if (!variant) return res.status(400).json({ message: "Variant not found" });

    if (quantity > variant.stock)
      return res.status(400).json({ message: "Not enough stock" });

    let cart = await Cart.findOne({ user: req.user._id });

    if (!cart) {
      // create new cart
      cart = await Cart.create({
        user: req.user._id,
        items: [{ product: productId, size, color, quantity }],
      });
    } else {
      // check if item exists
      const existing = cart.items.find(
        (i) =>
          i.product.toString() === productId &&
          i.size === size &&
          i.color === color
      );

      if (existing) {
        // increase quantity
        const newQty = existing.quantity + quantity;
        if (newQty > variant.stock)
          return res.status(400).json({ message: "Not enough stock" });

        existing.quantity = newQty;
      } else {
        cart.items.push({ product: productId, size, color, quantity });
      }

      await cart.save();
    }

    return res.json({ cart });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// PUT /api/cart (update quantity)
export const updateCart = async (req, res) => {
  try {
    const { productId, size, color, quantity } = req.body;

    const cart = await Cart.findOne({ user: req.user._id });
    if (!cart) return res.status(404).json({ message: "Cart not found" });

    const item = cart.items.find(
      (i) =>
        i.product.toString() === productId &&
        i.size === size &&
        i.color === color
    );

    if (!item) return res.status(404).json({ message: "Item not found" });

    // check stock
    const product = await Product.findById(productId);
    const variant = product.variants.find(
      (v) => v.size === size && v.color === color
    );

    if (quantity > variant.stock)
      return res.status(400).json({ message: "Not enough stock" });

    item.quantity = quantity;

    await cart.save();

    return res.json({ cart });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// DELETE /api/cart/item
export const removeItem = async (req, res) => {
  try {
    const { productId, size, color } = req.body;

    const cart = await Cart.findOne({ user: req.user._id });

    cart.items = cart.items.filter(
      (i) =>
        !(
          i.product.toString() === productId &&
          i.size === size &&
          i.color === color
        )
    );

    await cart.save();

    return res.json({ cart });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// DELETE /api/cart/clear
export const clearCart = async (req, res) => {
  try {
    await Cart.findOneAndUpdate(
      { user: req.user._id },
      { items: [] }
    );

    return res.json({ message: "Cart cleared" });
  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
