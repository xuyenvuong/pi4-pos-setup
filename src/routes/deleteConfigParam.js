const db = require('../persistence');

module.exports = async (req, res) => {
    await db.removeConfigParam(req.params.id);
    res.sendStatus(200);
};