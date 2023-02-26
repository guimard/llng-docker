#!/usr/bin/node

const supertest = require('supertest');
const assert = require('assert');
const request = supertest.agent('http://auth.example.com');

describe('LLNG portal', () => {
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
