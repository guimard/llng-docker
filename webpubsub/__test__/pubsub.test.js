const { expect } = require('chai');
const WebSocket = require('ws');
const axios = require('axios');

const server = 'pubsub:8080';

describe('WebSocket Pub/Sub integration test', function () {
  const wsUrl = `ws://${server}/subscribe?channels=chan1,chan2`;  // Change si besoin
  const postUrl = `http://${server}/publish`;
  const testPayload = { message: 'Hello WebSocket', "channel": "chan1" };

  let ws;
  let receivedMessage;

  beforeEach(function (done) {
    ws = new WebSocket(wsUrl, {
      headers: {
        'Authorization': 'Bearer qwerty'
      }
    });

    ws.on('open', () => {
      console.log('WebSocket connected');
    });

    ws.on('message', (data) => {
      receivedMessage = JSON.parse(data);
    });

    ws.on('error', (err) => {
      done(err); // Fait échouer le test si erreur de connexion
    });
      done();  // Signal que le test peut continuer une fois le message reçu
  });

  afterEach(function () {
    if (ws && ws.readyState === WebSocket.OPEN) {
      ws.close();
    }
  });

  it('should receive the same JSON over WebSocket after POST', async function () {
    // Lance la requête POST pendant que WebSocket écoute
    await axios.post(postUrl, testPayload, {
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer qwerty'
      }
    });

    // Attend que le WebSocket ait reçu le message
    await new Promise((resolve) => setTimeout(resolve, 300)); // Donne un petit délai

    expect(receivedMessage).to.deep.equal(testPayload);
  });
});
