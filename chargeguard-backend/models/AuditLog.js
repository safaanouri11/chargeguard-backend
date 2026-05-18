const mongoose = require('mongoose');

// AuditLog: every admin action is recorded for accountability.
// Kept lightweight — admin id + action verb + target ref + a free-text detail.
const auditLogSchema = new mongoose.Schema({
  admin:      { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, index: true },
  adminEmail: { type: String, default: '' },
  action:     { type: String, required: true }, // e.g. 'approve_host', 'delete_user', 'edit_balance'
  targetType: { type: String, default: '' },    // 'user', 'station', 'payout', 'ticket', 'promo', 'config'
  targetId:   { type: String, default: '' },
  detail:     { type: String, default: '' },    // human-readable summary
  before:     { type: mongoose.Schema.Types.Mixed, default: null },
  after:      { type: mongoose.Schema.Types.Mixed, default: null },
  ip:         { type: String, default: '' },
}, { timestamps: true });

module.exports = mongoose.model('AuditLog', auditLogSchema);
