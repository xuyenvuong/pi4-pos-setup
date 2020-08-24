const db = require('../persistence');

module.exports = async (req, res) => {
    const items = await db.getParams();
    res.send(items);
};
