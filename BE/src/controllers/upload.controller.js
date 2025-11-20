import { v2 as cloudinary } from "cloudinary";
import dotenv from "dotenv";
dotenv.config();

// Cấu hình Cloudinary
cloudinary.config({
  cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
  api_key: process.env.CLOUDINARY_API_KEY,
  api_secret: process.env.CLOUDINARY_API_SECRET,
  secure: true
});

// ----------------------------
// 1) UPLOAD ẢNH + TẠO FOLDER
// ----------------------------
export const uploadImage = async (req, res) => {
  try {
    const { categorySlug } = req.body;

    const folderPath = categorySlug
      ? `products/${categorySlug}`
      : "general";

    const fileStr = req.file.buffer.toString("base64");

    const uploaded = await cloudinary.uploader.upload(
      `data:image/jpeg;base64,${fileStr}`,
      { folder: folderPath }
    );

    return res.json({
      url: uploaded.secure_url,
      public_id: uploaded.public_id,
      folder: folderPath,
    });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// ----------------------------
// 2) XOÁ ẢNH THEO PUBLIC_ID
// ----------------------------
export const deleteImage = async (req, res) => {
  try {
    const { public_id } = req.params;

    await cloudinary.uploader.destroy(public_id);

    return res.json({
      message: "Image deleted",
      public_id
    });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// ----------------------------
// 3) THAY ẢNH (XOÁ CŨ + UPLOAD MỚI)
// ----------------------------
export const replaceImage = async (req, res) => {
  try {
    const { old_public_id, categorySlug } = req.body;

    if (!old_public_id)
      return res.status(400).json({ message: "Missing old_public_id" });

    // Xoá ảnh cũ
    await cloudinary.uploader.destroy(old_public_id);

    // Upload ảnh mới
    const folderPath = categorySlug
      ? `products/${categorySlug}`
      : "general";

    const fileStr = req.file.buffer.toString("base64");

    const uploaded = await cloudinary.uploader.upload(
      `data:image/jpeg;base64,${fileStr}`,
      { folder: folderPath }
    );

    return res.json({
      message: "Image replaced",
      new_url: uploaded.secure_url,
      new_public_id: uploaded.public_id
    });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};

// ----------------------------
// 4) LẤY DANH SÁCH ẢNH TRONG FOLDER
// ----------------------------
export const listImagesByFolder = async (req, res) => {
  try {
    const { folder } = req.query;

    if (!folder)
      return res.status(400).json({ message: "Missing folder" });

    const result = await cloudinary.search
      .expression(`folder:${folder}`)
      .sort_by("created_at", "desc")
      .max_results(100)
      .execute();

    return res.json({
      count: result.resources.length,
      images: result.resources
    });

  } catch (err) {
    return res.status(500).json({ message: err.message });
  }
};
