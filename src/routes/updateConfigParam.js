const db = require('../persistence');

module.exports = async (req, res) => {
    await db.updateConfigParam(req.params.id, {
        name: req.body.name,
		type: req.body.type,
		description: req.body.description,
		defaultValue: req.body.defaultValue,
		value: req.body.value,
        locked: false		
    });
    const item = await db.getConfigParam(req.params.id);
    res.send(item);
};
