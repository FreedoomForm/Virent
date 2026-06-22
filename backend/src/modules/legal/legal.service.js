const { getDb } = require('../../shared/db.js');
const legalService = {
  getTerms: async function(res, lang = 'ru') {
    const db = await getDb();
    const doc = await db.collection('legal_documents').findOne({ type: 'terms', status: 'active' }, { sort: { version: -1 } });
    if (!doc) return res.status(200).json({ data: { type: 'terms', version: '1.0', title: 'Пользовательское соглашение', body: 'Используя Virent...', updated_at: new Date() }});
    return res.status(200).json({ data: { type: 'terms', version: doc.version, title: doc.title, body: doc.body, updated_at: doc.updated_at }});
  },
  getPrivacy: async function(res, lang = 'ru') {
    const db = await getDb();
    const doc = await db.collection('legal_documents').findOne({ type: 'privacy', status: 'active' }, { sort: { version: -1 } });
    if (!doc) return res.status(200).json({ data: { type: 'privacy', version: '1.0', title: 'Политика конфиденциальности', body: 'Мы защищаем данные...', updated_at: new Date() }});
    return res.status(200).json({ data: { type: 'privacy', version: doc.version, title: doc.title, body: doc.body, updated_at: doc.updated_at }});
  },
  saveTerms: async function(res, body) {
    const db = await getDb();
    await db.collection('legal_documents').updateMany({ type: 'terms', status: 'active' }, { $set: { status: 'archived' } });
    await db.collection('legal_documents').insertOne({ type: 'terms', version: body.version || '1.0', title: body.title, body: body.body, status: 'active', created_at: new Date(), updated_at: new Date() });
    return res.status(201).json({ data: { type: 'success', message: 'Terms updated' }});
  },
};
module.exports = legalService;
