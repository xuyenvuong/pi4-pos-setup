const express = require('express');
const app = express();
const db = require('./persistence');
const getConfigParams = require('./routes/getConfigParams');
const addConfigParam = require('./routes/addConfigParam');
const updateConfigParam = require('./routes/updateConfigParam');
const deleteConfigParam = require('./routes/deleteConfigParam');

app.use(require('body-parser').json());
app.use(express.static(__dirname + '/static'));

app.get('/params', getConfigParams);
app.post('/params', addConfigParam);
app.put('/params/:id', updateConfigParam);
app.delete('/params/:id', deleteConfigParam);

db.init().then(() => {
    app.listen(42069, () => console.log('Listening on port 42069'));
}).catch((err) => {
    console.error(err);
    process.exit(1);
});

const gracefulShutdown = () => {
    db.teardown()
        .catch(() => {})
        .then(() => process.exit());
};

process.on('SIGINT', gracefulShutdown);
process.on('SIGTERM', gracefulShutdown);
process.on('SIGUSR2', gracefulShutdown); // Sent by nodemon
