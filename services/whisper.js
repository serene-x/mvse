const fs = require('node:fs');
const OpenAI = require('openai');

let cached;
function client() {
  if (cached) return cached;
  if (!process.env.OPENAI_API_KEY) throw new Error('OPENAI_API_KEY missing');
  cached = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });
  return cached;
}

async function transcribe(audioFilePath, { language = 'en' } = {}) {
  const resp = await client().audio.transcriptions.create({
    file: fs.createReadStream(audioFilePath),
    model: 'whisper-1',
    language,
    response_format: 'json',
  });
  return resp.text ?? '';
}

module.exports = { transcribe };
