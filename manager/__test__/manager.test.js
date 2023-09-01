#!/usr/bin/node

const supertest = require('supertest')
const assert = require('assert')

describe('LLNG portal', () => {
  before(function (done) {
    setTimeout(done, 5000); // Wait 5 secondes
  });

  const request = supertest.agent('http://auth.example.com')
  let token=''
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
})
describe('LLNG manager', () => {
  const request = supertest.agent('http://manager.example.com')
  it('should accept connection', (done) => {
    request.get('/')
      .expect(200)
      .then(res => { done() })
      .catch(done)
  })
})
