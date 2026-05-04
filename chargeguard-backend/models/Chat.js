const mongoose = require('mongoose');
const chatSchema = new mongoose.Schema({
  user:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  text:  { type: String, required: true },
  isBot: { type: Boolean, default: false },
}, { timestamps: true });
module.exports = mongoose.model('Chat', chatSchema);