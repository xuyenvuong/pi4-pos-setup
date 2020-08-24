const db = require('../persistence');

module.exports = async (req, res) => {
    await db.removeParam(req.params.id);
    res.sendStatus(200);
};