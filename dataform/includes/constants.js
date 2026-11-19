// Shared constants and SQL helpers, available in every SQLX file as `constants`.

const CURRENCY = "EUR";
const VAT_RATE = 0.21;

// Order statuses accepted from the source and the ones that count as revenue.
const VALID_STATUSES = ["delivered", "shipped", "cancelled", "returned"];
const REVENUE_STATUSES = ["delivered", "shipped"];

// Incremental models re-process this many days to absorb late-arriving rows.
const INCREMENTAL_LOOKBACK_DAYS = 3;

/** Renders a JS array as a SQL list: ['a', 'b'] -> 'a', 'b' */
function sqlList(values) {
  return values.map((value) => `'${value}'`).join(", ");
}

/** Trims and title-cases a free-text column coming from a source system. */
function cleanText(column) {
  return `INITCAP(TRIM(${column}))`;
}

/** Safe division that returns NULL instead of failing on zero. */
function safeDivide(numerator, denominator) {
  return `SAFE_DIVIDE(${numerator}, ${denominator})`;
}

module.exports = {
  CURRENCY,
  VAT_RATE,
  VALID_STATUSES,
  REVENUE_STATUSES,
  INCREMENTAL_LOOKBACK_DAYS,
  sqlList,
  cleanText,
  safeDivide,
};
