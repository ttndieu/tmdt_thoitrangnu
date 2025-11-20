import multer from "multer";

const storage = multer.memoryStorage(); // cho cloudinary

export const upload = multer({ storage });
