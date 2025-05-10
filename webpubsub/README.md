# yadd/lemonldap-ng-webpubsub

Web Pub/Sub server for [LemonLDAP::NG](https://lemonldap-ng.org)

## Synopsys

### Run the server

```shell
$ docker run -p 8080:8080 -e PUBSUB_TOKEN=qwerty yadd/lemonldap-ng-webpubsub
```

### Test it

* Reader
```shell
$ wscat -H 'Authorization: Bearer qwerty' -c ws://localhost:8080/subscribe?channels=chan1
```

* Publisher
```shell
$ curl -XPOST -d '{"foo":"bar","bar":"baz","baz":"foo","channel":"chan1"}' -H 'Authorization: Bearer qwerty' http://localhost:8080/publish
```

## Variables

- `PUBSUG_ACCESS_LOG`, default STDERR _(to get access logs on docker console)_
- `PUBSUB_CERT`
- `PUBSUB_DEBUG`
- `PUBSUB_KEY`
- `PUBSUB_MAX_REQUEST_SIZE`, default 8192
- `PUBSUB_MAX_REQUEST_TIME`, default 5
- `PUBSUB_QUIET`, default 1
- `PUBSUB_PORT`, default: 8443 if `PUBSUB_CERT` and `PUBSUB_KEY` are set, 8080 else
- `PUBSUB_TOKEN`

## API

### Publisher

- URL: `/publish`
- Method: POST
- Headers:
    - **Authorization** _(optional)_: f a token is required, set it here in the form:
```
Authorization: Bearer <value>
```
- Request body: JSON content with at least a "**channel**" key
_(the channel where the message will be published)_

### Reader _(websockets)_

- URL: `/subscribe` _(this opens the websocket)_
- Method: GET
- Headers:
    - **Authorization** _(optional)_: f a token is required, set it here in the form:
```
Authorization: Bearer <value>
```
- Query _(GET parameters)_:
  - **channels** _(required)_: comma separated list of channels to subscribe to.
