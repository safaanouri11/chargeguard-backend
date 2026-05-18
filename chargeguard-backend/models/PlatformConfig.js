const mongoose = require('mongoose');

// PlatformConfig: a single document holding tunable platform-wide settings.
// Loaded/cached by routes that need it. Get-or-create pattern in getConfig().
const platformConfigSchema = new mongoose.Schema({
  // Commission the platform takes per transaction (percent, 0-100)
  commissionRate:        { type: Number, default: 15 },
  // Booking constraints
  minBookingMinutes:     { type: Number, default: 15 },
  maxBookingMinutes:     { type: Number, default: 240 },
  cancellationWindowMin: { type: Number, default: 30 },
  // Loyalty
  pointsPerKwh:          { type: Number, default: 1 },
  // Feature toggles
  aiFeaturesEnabled:     { type: Boolean, default: true },
  reviewsEnabled:        { type: Boolean, default: true },
  referralsEnabled:      { type: Boolean, default: true },
  // Referral bonus (NIS) credited to both inviter and invitee
  referralBonus:         { type: Number, default: 10 },
  // Maintenance mode — when true, drivers see a banner
  maintenanceMode:       { type: Boolean, default: false },
  maintenanceMessage:    { type: String,  default: '' },
}, { timestamps: true });

platformConfigSchema.statics.getConfig = async function() {
  let cfg = await this.findOne();
  if (!cfg) cfg = await this.create({});
  return cfg;
};

module.exports = mongoose.model('PlatformConfig', platformConfigSchema);
