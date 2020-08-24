const waitPort = require('wait-port');
const fs = require('fs');
const mysql = require('mysql');

const {
    MYSQL_HOST: HOST,
    MYSQL_HOST_FILE: HOST_FILE,
    MYSQL_USER: USER,
    MYSQL_USER_FILE: USER_FILE,
    MYSQL_PASSWORD: PASSWORD,
    MYSQL_PASSWORD_FILE: PASSWORD_FILE,
    MYSQL_DB: DB,
    MYSQL_DB_FILE: DB_FILE,
} = process.env;

let pool;

async function init() {
    const host = HOST_FILE ? fs.readFileSync(HOST_FILE) : HOST;
    const user = USER_FILE ? fs.readFileSync(USER_FILE) : USER;
    const password = PASSWORD_FILE ? fs.readFileSync(PASSWORD_FILE) : PASSWORD;
    const database = DB_FILE ? fs.readFileSync(DB_FILE) : DB;

    await waitPort({ host, port : 3306});

    pool = mysql.createPool({
        connectionLimit: 5,
        host,
        user,
        password,
        database,
    });

    return new Promise((acc, rej) => {
        pool.query(
            'CREATE TABLE IF NOT EXISTS pryms_config_params (id varchar(36), name varchar(128), type varchar(36), description varchar(1024), default_value varchar(1024), value varchar(1024), locked boolean)',
            err => {
                if (err) return rej(err);

                console.log(`Connected to mysql db at host ${HOST}`);
                acc();
            },
        );
    });
}

async function teardown() {
    return new Promise((acc, rej) => {
        pool.end(err => {
            if (err) rej(err);
            else acc();
        });
    });
}

async function getParams() {
    return new Promise((acc, rej) => {
        pool.query('SELECT * FROM pryms_config_params', (err, rows) => {
            if (err) return rej(err);
            acc(
                rows.map(param =>
                    Object.assign({}, param, {
                        locked: param.locked === 1,
                    }),
                ),
            );
        });
    });
}

async function getParam(id) {
    return new Promise((acc, rej) => {
        pool.query('SELECT * FROM pryms_config_params WHERE id=?', [id], (err, rows) => {
            if (err) return rej(err);
            acc(
                rows.map(param =>
                    Object.assign({}, param, {
                        locked: param.locked === 1,
                    }),
                )[0],
            );
        });
    });
}

async function storeParam(param) {
    return new Promise((acc, rej) => {
        pool.query(
            'INSERT INTO pryms_config_params (id, name, type, description, default_value, value, locked) VALUES (?, ?, ?, ?, ?, ?, ?)',
            [param.id, param.name, param.type, param.description, param.defaulValue, param.value, param.locked ? 1 : 0],
            err => {
                if (err) return rej(err);
                acc();
            },
        );
    });
}

async function updateParam(id, param) {
    return new Promise((acc, rej) => {
        pool.query(
            'UPDATE pryms_config_params SET name=?, description=?, type=?, default_value=?, value=?, locked=? WHERE id=?',            
			[param.name, param.description, param.type, param.defaulValue, param.value, param.locked ? 1 : 0, id],
            err => {
                if (err) return rej(err);
                acc();
            },
        );
    });
}

async function removeParam(id) {
    return new Promise((acc, rej) => {
        pool.query('DELETE FROM pryms_config_params WHERE id = ?', [id], err => {
            if (err) return rej(err);
            acc();
        });
    });
}

module.exports = {
    init,
    teardown,
    getParams,
    getParam,
    storeParam,
    updateParam,
    removeParam,
};