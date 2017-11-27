const express = require('express');
const morgan = require('morgan');
const bodyParser = require('body-parser')

const poolConfig = [{
    host: "127.0.0.1",
    port: 8080,
    name: "dev-1"
  },{
    host: "127.0.0.1",
    port: 8081,
    name: "dev-2"
  }];

poolConfig.forEach((config) => {
  let app = express();

  // Expand on headers/body that are printed
  app.use(morgan('combined'));
  app.use(bodyParser.urlencoded({ extended: false }));
  app.use(bodyParser.json());

  responseCb = (req, res) => {
    res.send('Hello World from ' + config.name);
  }
  app.get('*', responseCb);
  app.post('*', responseCb);
  app.put('*', responseCb);
  app.delete('*', responseCb);

  app.listen(config.port, () => console.log(config.name + ' listening on port ' + config.port));
});
