const db = require('../persistence');
const uuid = require('uuid/v4');

module.exports = async (req, res) => {
    const item = {
        id: uuid(),
        name: req.body.name,
		type: req.body.type,
		description: req.body.description,
		defaultValue: req.body.defaultValue,
		value: req.body.value,
        locked: false
    };

    await db.storeConfigParam(item);
    res.send(item);
};