const Notification = require('../models/Notification');
async function notify(userId, title, body, type, link) {
  if (!userId) return null;
  try {
    return await Notification.create({
      user: userId,
      title: title,
      body:  body || '',
      type:  type || 'system',
      link:  link || '',
    });
  } catch (err) {
    console.error('notify() failed:', err.message);
    return null;
  }
}
module.exports = notify;
