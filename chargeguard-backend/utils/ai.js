// Anthropic Claude integration for ChargeGuard.
// Two surfaces:
//   - recommendStation(user, stations) → { stationId, reason } | null
//   - summarizeRoute(payload)          → string | null
//
// Both gracefully return null when ANTHROPIC_API_KEY is missing or the call
// fails. Callers must handle the null path with a deterministic fallback.

const Anthropic = require('@anthropic-ai/sdk');

// Default to Haiku 4.5 — fast, cheap, and good enough for these short tasks.
// Override via ANTHROPIC_MODEL env var (e.g. claude-opus-4-7 for max quality).
// Pricing: $1/$5 per 1M tokens (haiku) vs $5/$25 (opus). New Anthropic
// accounts get ~$5 in free credits which is plenty for a student project.
const MODEL = process.env.ANTHROPIC_MODEL || 'claude-haiku-4-5';

const SYSTEM_RECOMMEND =
  'You are ChargeGuard\'s AI assistant helping electric vehicle drivers in ' +
  'Palestine choose the best charging station right now.\n\n' +
  'Given a list of currently available stations and the driver\'s profile, ' +
  'select the SINGLE best station for them. Consider in this priority:\n' +
  '1. Connector compatibility — must match if possible.\n' +
  '2. Battery urgency — if battery is low (<30%), prefer faster chargers (50+ kW).\n' +
  '3. Price per kWh — cheaper is better, all else equal.\n' +
  '4. Power output — faster is better for time-sensitive trips.\n' +
  '5. Station rating — higher is better as a tiebreaker.\n\n' +
  'Return the station\'s _id exactly as provided and a short, friendly ' +
  'one-sentence explanation in English (max 90 characters) for the driver.';

const SYSTEM_ROUTE =
  'You are ChargeGuard\'s AI trip planner for EV drivers in Palestine.\n\n' +
  'Given a planned trip with charging stops and totals, write a SHORT ' +
  '(1–2 sentences, max 240 characters) friendly summary for the driver.\n\n' +
  'Mention: feasibility, number of stops if any, and one practical tip ' +
  '(e.g. fastest charger to use, when to leave). Be concrete and actionable. ' +
  'Avoid restating numbers the UI already shows. Respond in English.';

let _client = null;
function client() {
  if (_client) return _client;
  if (!process.env.ANTHROPIC_API_KEY) return null;
  try {
    _client = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
    return _client;
  } catch (e) {
    console.error('Anthropic init failed:', e.message);
    return null;
  }
}

function isEnabled() { return client() !== null; }

// Compact representation — keep tokens small.
function stationsTable(stations) {
  return stations.slice(0, 30).map(function(s, i) {
    var addr = s.location && s.location.address ? s.location.address : '';
    return (i + 1) + '. _id=' + s._id +
      ' | ' + s.name +
      ' | connector=' + s.connector +
      ' | power=' + s.power +
      ' | price=' + s.price + ' NIS/kWh' +
      ' | rating=' + (s.rating || 5) +
      ' | occupancy=' + (s.occupancy || 'free') +
      (addr ? ' | ' + addr : '');
  }).join('\n');
}

async function recommendStation(user, stations) {
  var c = client();
  if (!c) return null;
  if (!stations || stations.length === 0) return null;

  var userText =
    'Driver profile:\n' +
    '- Connector: ' + (user.connector || 'CCS2') + '\n' +
    '- Current battery: ' + (user.batteryPct != null ? user.batteryPct : 65) + '%\n' +
    '- Region: ' + (user.region || 'Palestine') + '\n' +
    '- Wallet balance: ' + (user.balance || 0) + ' NIS';

  try {
    var msg = await c.messages.create({
      model: MODEL,
      max_tokens: 400,
      output_config: {
        format: {
          type: 'json_schema',
          schema: {
            type: 'object',
            properties: {
              stationId: { type: 'string', description: 'Station _id from the list' },
              reason:    { type: 'string', description: 'One-sentence explanation, max 90 chars' },
            },
            required: ['stationId', 'reason'],
            additionalProperties: false,
          },
        },
      },
      system: SYSTEM_RECOMMEND,
      messages: [{
        role: 'user',
        content: userText + '\n\nAvailable stations:\n' + stationsTable(stations),
      }],
    });
    var block = msg.content && msg.content.find(function(b) { return b.type === 'text'; });
    if (!block) return null;
    var parsed;
    try { parsed = JSON.parse(block.text); }
    catch (e) { console.error('AI recommend: invalid JSON:', e.message); return null; }
    if (!parsed.stationId || !parsed.reason) return null;
    return parsed;
  } catch (e) {
    console.error('AI recommend failed:', e.message);
    return null;
  }
}

async function summarizeRoute(payload) {
  var c = client();
  if (!c) return null;
  try {
    var msg = await c.messages.create({
      model: MODEL,
      max_tokens: 200,
      system: SYSTEM_ROUTE,
      messages: [{
        role: 'user',
        content:
          'Total distance: ' + payload.totalDistanceKm + ' km\n' +
          'Direct range: ' + payload.directRangeKm + ' km\n' +
          'Starting battery: ' + payload.startBatteryPct + '%\n' +
          'Feasible: ' + payload.feasible + '\n' +
          'Stops (' + (payload.stops || []).length + '): ' +
            JSON.stringify((payload.stops || []).map(function(s) {
              return {
                name: s.name,
                legKm: s.legKm,
                arriveBatteryPct: s.arrivalBatteryPct,
                chargeMin: s.estimatedChargeMinutes,
                chargeKwh: s.kwhCharged,
                cost: s.estimatedCost,
                power: s.power,
              };
            })) + '\n' +
          'Total time: ' + payload.totalMinutes + ' min ' +
            '(' + payload.drivingMinutes + ' driving + ' + payload.chargingMinutes + ' charging)\n' +
          'Total cost: ' + payload.totalCost + ' NIS\n' +
          'Total energy: ' + payload.totalKwh + ' kWh',
      }],
    });
    var block = msg.content && msg.content.find(function(b) { return b.type === 'text'; });
    return block ? block.text.trim() : null;
  } catch (e) {
    console.error('AI route summary failed:', e.message);
    return null;
  }
}

module.exports = { recommendStation, summarizeRoute, isEnabled };
