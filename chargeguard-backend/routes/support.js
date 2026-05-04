const express = require('express');
const Ticket  = require('../models/Ticket');
const Chat    = require('../models/Chat');
const protect = require('../middleware/protect');
const router = express.Router();
var anthropic = null;
try {
  var Anthropic = require('@anthropic-ai/sdk');
  anthropic = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY || '' });
} catch (e) {
  console.log('Anthropic SDK not installed - using fallback replies');
}
// POST /api/support/ticket
router.post('/ticket', protect, async function(req, res) {
  try {
    var ticket = await Ticket.create({
      user: req.user._id,
      category: req.body.category || 'General',
      subject:  req.body.subject,
      message:  req.body.message,
    });
    console.log('Ticket created: ' + ticket.subject);
    res.status(201).json({ message: 'Ticket submitted!', ticket });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// GET /api/support/chat
router.get('/chat', protect, async function(req, res) {
  try {
    var messages = await Chat.find({ user: req.user._id }).sort({ createdAt: 1 }).limit(50);
    res.json(messages);
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
// POST /api/support/chat
router.post('/chat', protect, async function(req, res) {
  try {
    var userMsg = await Chat.create({ user: req.user._id, text: req.body.text, isBot: false });
    var botText = 'Thank you for your message. A support agent will assist you shortly.';
    if (anthropic) {
      try {
        var aiRes = await anthropic.messages.create({
          model: 'claude-haiku-4-5-20251001',
          max_tokens: 300,
          system: 'You are a helpful customer support agent for ChargeGuard, an EV charging app in Palestine. ' +
                  'Answer questions about: booking stations, charging sessions, payments, wallet top-up, ' +
                  'cancellations (5 NIS refund), loyalty points, and app features. ' +
                  'Keep answers short, friendly, and helpful. Reply in the same language as the user.',
          messages: [{ role: 'user', content: req.body.text }],
        });
        botText = aiRes.content[0].text;
      } catch (aiErr) {
        console.error('AI error:', aiErr.message);
      }
    }
    var botMsg = await Chat.create({ user: req.user._id, text: botText, isBot: true });
    res.json({ userMessage: userMsg, botMessage: botMsg });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});
module.exports = router;