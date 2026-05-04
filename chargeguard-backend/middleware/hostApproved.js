// Middleware: ensure host is approved before accessing host routes
async function hostApproved(req, res, next) {
  if (req.user.role !== 'host') {
    return res.status(403).json({ message: 'Access denied. Hosts only.' });
  }
  if (req.user.hostStatus !== 'Approved') {
    return res.status(403).json({
      message: 'Your host account is not approved yet.',
      status: req.user.hostStatus,
    });
  }
  next();
}
module.exports = hostApproved;