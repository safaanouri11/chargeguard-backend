const mongoose = require('mongoose');
const notificationSchema = new mongoose.Schema({
  user:  { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  title: { type: String, required: true },
  body:  { type: String, default: '' },
  type:  { type: String, default: 'system' }, // booking, payout, host, review, referral, system
  read:  { type: Boolean, default: false },
  link:  { type: String, default: '' },
}, { timestamps: true });
module.exports = mongoose.model('Notification', notificationSchema);
