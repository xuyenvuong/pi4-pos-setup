const express = require('express');
const app = express();
const db = require('./persistence');
const getParams = require('./routes/getParams');
const addParam = require('./routes/addParam');
const updateParam = require('./routes/updateParam');
const deleteParam = require('./routes/deleteParam');

app.use(require('body-parser').json());
app.use(express.static(__dirname + '/static'));

app.get('/params', getParams);
app.post('/params', addParam);
app.put('/params/:id', updateParam);
app.delete('/params/:id', deleteParam);

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
