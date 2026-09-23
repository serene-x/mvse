const { test } = require('node:test'),
  assert = require('node:assert/strict');
const { validateReport } = require('../services/manualShadeReports');
const valid = {
  sourceUrl: 'https://www.tiktok.com/@creator/video/123456?share=1',
  confirmed: true,
  evidence: 'At 0:12 both foundations are described as skin matches.',
  pairs: [
    { productId: 'a', shade: '1N' },
    { productId: 'b', shade: '2' },
  ],
};
test('canonicalizes the public source URL for deduplication', () => {
  assert.equal(
    validateReport(valid).source,
    'https://www.tiktok.com/@creator/video/123456',
  );
});
test('rejects an unreviewed report and duplicate product claims', () => {
  assert.throws(() => validateReport({ ...valid, confirmed: false }));
  assert.throws(() =>
    validateReport({ ...valid, pairs: [valid.pairs[0], valid.pairs[0]] }),
  );
  assert.throws(() =>
    validateReport({
      ...valid,
      sourceUrl: 'https://tiktok.com.evil.example/@creator/video/123456',
    }),
  );
});
