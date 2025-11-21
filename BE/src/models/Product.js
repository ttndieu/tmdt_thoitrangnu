import mongoose from "mongoose";

// Schema Variant
const variantSchema = mongoose.Schema({
  size: { type: String, enum: ["S", "M", "L"], required: true },
  color: { type: String, required: true },
  stock: { type: Number, default: 0 },
  price: { type: Number, required: true },
});

// Schema Image
const imageSchema = mongoose.Schema({
  url: { type: String, required: true },
  public_id: { type: String, required: true }
});

// MAIN Product schema
const productSchema = mongoose.Schema(
  {
    name: { type: String, required: true },
    slug: { type: String, unique: true, required: true },
    description: { type: String },

    images: [imageSchema],   // ⬅️ Sửa từ [String] thành [imageSchema]

    category: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Category",
    },

    variants: [variantSchema],

    sold: { type: Number, default: 0 },
  },
  { timestamps: true }
);

productSchema.index({ name: "text" });

export default mongoose.model("Product", productSchema);
