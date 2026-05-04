const mongoose = require('mongoose');
const bookmarkSchema = new mongoose.Schema({
  user:    { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  station: { type: mongoose.Schema.Types.ObjectId, ref: 'Station', required: true },
}, { timestamps: true });
bookmarkSchema.index({ user: 1, station: 1 }, { unique: true });
module.exports = mongoose.model('Bookmark', bookmarkSchema);