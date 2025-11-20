import mongoose from "mongoose";

// Schema cho các variant (size, color, stock, price)
const variantSchema = mongoose.Schema({
  size: { type: String, enum: ["S", "M", "L"], required: true },
  color: { type: String, required: true },
  stock: { type: Number, default: 0 },
  price: { type: Number, required: true },
});

// Schema chính Product
const productSchema = mongoose.Schema(
  {
    name: { type: String, required: true },
    slug: { type: String, unique: true, required: true },
    description: { type: String },
    images: [String],
    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Category",
    },
    variants: [variantSchema],
    sold: { type: Number, default: 0 },
  },
  { timestamps: true }
);

// Tạo index tìm kiếm text trên name
productSchema.index({ name: "text" });

// Export model
export default mongoose.model("Product", productSchema);
