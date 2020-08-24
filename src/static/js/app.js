function App() {
    const { Container, Row, Col } = ReactBootstrap;
    return (
        <Container>
            <Row>
                <Col md={{ offset: 3, span: 6 }}>
                    <ParamListCard />
                </Col>
            </Row>
        </Container>
    );
}

function ParamListCard() {
    const [params, setParams] = React.useState(null);

    React.useEffect(() => {
        fetch('/params')
            .then(r => r.json())
            .then(setParams);
    }, []);

    const onNewParam = React.useCallback(
        newParam => {
            setParams([...params, newParam]);
        },
        [params],
    );

    const onParamUpdate = React.useCallback(
        param => {
            const index = params.findIndex(i => i.id === param.id);
            setParams([
                ...params.slice(0, index),
                param,
                ...params.slice(index + 1),
            ]);
        },
        [params],
    );

    const onParamRemoval = React.useCallback(
        param => {
            const index = params.findIndex(i => i.id === param.id);
            setParams([...params.slice(0, index), ...params.slice(index + 1)]);
        },
        [params],
    );

    if (params === null) return 'Loading...';

    return (
        <React.Fragment>
            <AddParamForm onNewParam={onNewParam} />
            {params.length === 0 && (
                <p className="text-center">No params yet! Add one above!</p>
            )}
            {params.map(param => (
                <ParamDisplay
                    param={param}
                    key={param.id}
                    onParamUpdate={onParamUpdate}
                    onParamRemoval={onParamRemoval}
                />
            ))}
        </React.Fragment>
    );
}

function AddParamForm({ onNewParam }) {
    const { Form, InputGroup, Button } = ReactBootstrap;

    const [newParam, setNewParam] = React.useState('');
    const [submitting, setSubmitting] = React.useState(false);

    const submitNewParam = e => {
        e.preventDefault();
        setSubmitting(true);
        fetch('/params', {
            method: 'POST',
            body: JSON.stringify({ name: newParam }),
            headers: { 'Content-Type': 'application/json' },
        })
            .then(r => r.json())
            .then(param => {
                onNewParam(param);
                setSubmitting(false);
                setNewParam('');
            });
    };

    return (
        <Form onSubmit={submitNewParam}>
            <InputGroup className="mb-3">
                <Form.Control
                    value={newParam}
                    onChange={e => setNewParam(e.target.value)}
                    type="text"
                    placeholder="New Param"
                    aria-describedby="basic-addon1"
                />
                <InputGroup.Append>
                    <Button
                        type="submit"
                        variant="success"
                        disabled={!newParam.length}
                        className={submitting ? 'disabled' : ''}
                    >
                        {submitting ? 'Adding...' : 'Add Param'}
                    </Button>
                </InputGroup.Append>
            </InputGroup>
        </Form>
    );
}

function ParamDisplay({ param, onParamUpdate, onParamRemoval }) {
    const { Container, Row, Col, Button } = ReactBootstrap;

    const toggleCompletion = () => {
        fetch(`/params/${param.id}`, {
            method: 'PUT',
            body: JSON.stringify({
                name: param.name,
                locked: !param.locked,
            }),
            headers: { 'Content-Type': 'application/json' },
        })
            .then(r => r.json())
            .then(onParamUpdate);
    };

    const removeParam = () => {
        fetch(`/params/${param.id}`, { method: 'DELETE' }).then(() =>
            onParamRemoval(param),
        );
    };

    return (
        <Container fluid className={`param ${param.completed && 'completed'}`}>
            <Row>
                <Col xs={1} className="text-center">
                    <Button
                        className="toggles"
                        size="sm"
                        variant="link"
                        onClick={toggleCompletion}
                        aria-label={
                            param.completed
                                ? 'Mark param as incomplete'
                                : 'Mark param as complete'
                        }
                    >
                        <i
                            className={`far ${
                                param.completed ? 'fa-check-square' : 'fa-square'
                            }`}
                        />
                    </Button>
                </Col>
                <Col xs={10} className="name">
                    {param.name}
                </Col>
                <Col xs={1} className="text-center remove">
                    <Button
                        size="sm"
                        variant="link"
                        onClick={removeParam}
                        aria-label="Remove Param"
                    >
                        <i className="fa fa-trash text-danger" />
                    </Button>
                </Col>
            </Row>
        </Container>
    );
}

ReactDOM.render(<App />, document.getElementById('root'));
