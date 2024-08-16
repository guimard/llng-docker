#!/usr/bin/node

const supertest = require('supertest');
const assert = require('assert');
const request = supertest.agent('http://auth.example.com');
const express = require('express');

const app = express();
app.get('/', function (req, res) {
  res.status(200).json({ name: 'john' });
})
app.listen(3000)

describe('LLNG portal', () => {
  before(function (done) {
    setTimeout(done, 5000); // Wait 5 secondes
  });

  let token=''
  let llid=''
  it('should return 401 to unauthenticated JSON request', done => {
    request.get('/')
      .set('Accept','application/json')
      .expect(401,done)
  })
  it('should give token', (done) => {
    request.get('/')
      .expect(200)
      .then(res => {
        assert.ok(res.text.match(/name="token" value="(.*?)"/s), 'Found token')
        token = RegExp.$1
        done()
      })
  })
  it('should authenticate', (done) => {
    request.post('/')
      .field('user',    'dwho')
      .field('password','dwho')
      .field('token',   token)
      .expect('set-cookie', /lemonldap=/)
      .expect(302)
      .then( res => {
        cookies = request.jar.getCookies({domain:'example.com',path:'/',secure:false,script:false}).toValueString()
        assert.ok( cookies.match(/lemonldap=[0-9a-f]+/) )
        done()
      })
  })
  it('should return 200 to authenticated JSON request', done => {
    request.get('/')
      .set('Accept','application/json')
      .expect(200,done)
  })
  it('should logout', (done) => {
    request.get('/?logout=1')
      .expect(200,done)
  })
  it('should have disconnect agent', done => {
    request.get('/')
      .set('Accept','application/json')
      .expect(401,done)
  })
})
describe('RELAY', () => {
  const request = supertest.agent('http://foo.example.com')
  it('should find /languages/fr.json', (done) => {
    request.get('/')
      .set('Accept', 'application/json')
      .expect('Content-Type', /json/)
      .expect(200)
      .then(res => {
        expect(res.body.name).toEqual('john');
        done();
      })
      .catch(done)
  });
})
