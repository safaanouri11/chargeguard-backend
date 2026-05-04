const User = require('../models/User');
const ALPHABET = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // no I/O/0/1
function randomCode(len) {
  var s = '';
  for (var i = 0; i < len; i++) {
    s += ALPHABET.charAt(Math.floor(Math.random() * ALPHABET.length));
  }
  return s;
}
async function generateUniqueCode() {
  for (var i = 0; i < 10; i++) {
    var code = randomCode(7);
    var exists = await User.exists({ referralCode: code });
    if (!exists) return code;
  }
  // fallback: longer code
  return randomCode(10);
}
module.exports = { generateUniqueCode };
