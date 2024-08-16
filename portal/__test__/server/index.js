#!/usr/bin/node

const express = require('express');

const app = express();
app.get('/', function (req, res) {
  res.status(200).json({ name: 'john' });
})
app.listen(3000)
