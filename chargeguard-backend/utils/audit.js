const AuditLog = require('../models/AuditLog');

// Record an admin action. Best-effort — never blocks the response.
// Usage: await audit(req, { action, targetType, targetId, detail, before, after });
async function audit(req, opts) {
  try {
    if (!req || !req.user) return null;
    return await AuditLog.create({
      admin:      req.user._id,
      adminEmail: req.user.email || '',
      action:     opts.action,
      targetType: opts.targetType || '',
      targetId:   opts.targetId   || '',
      detail:     opts.detail     || '',
      before:     opts.before     || null,
      after:      opts.after      || null,
      ip:         (req.headers && (req.headers['x-forwarded-for'] || req.headers['x-real-ip'])) ||
                  (req.connection && req.connection.remoteAddress) ||
                  req.ip || '',
    });
  } catch (e) {
    console.error('audit() failed:', e.message);
    return null;
  }
}

module.exports = audit;
