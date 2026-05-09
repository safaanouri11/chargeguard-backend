// Loyalty tier logic — computed from User.points.

const TIERS = [
  { name: 'Bronze', min: 0,    max: 499,    discountPct: 0,  color: '#CD7F32' },
  { name: 'Silver', min: 500,  max: 1999,   discountPct: 5,  color: '#C0C0C0' },
  { name: 'Gold',   min: 2000, max: Infinity, discountPct: 10, color: '#FFD700' },
];

function tierFor(points) {
  var p = points || 0;
  for (var i = TIERS.length - 1; i >= 0; i--) {
    if (p >= TIERS[i].min) return TIERS[i];
  }
  return TIERS[0];
}

function loyaltyState(points) {
  var p = points || 0;
  var current = tierFor(p);
  var idx = TIERS.findIndex(function(t) { return t.name === current.name; });
  var next = idx < TIERS.length - 1 ? TIERS[idx + 1] : null;
  return {
    points:        p,
    tier:          current.name,
    discountPct:   current.discountPct,
    color:         current.color,
    nextTier:      next ? next.name : null,
    pointsToNext:  next ? Math.max(0, next.min - p) : 0,
    progressPct:   next ? Math.min(100, Math.round(((p - current.min) / (next.min - current.min)) * 100)) : 100,
  };
}

module.exports = { tierFor, loyaltyState, TIERS };
