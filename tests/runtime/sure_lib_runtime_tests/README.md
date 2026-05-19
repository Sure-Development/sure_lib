# sure_lib Runtime Tests

This is a small FiveM resource for testing `sure_lib` inside a real server runtime.

## Setup

1. Copy or symlink this folder into your server resources as `sure_lib_runtime_tests`.
2. Ensure dependencies first:

```cfg
ensure ox_lib
ensure es_extended
ensure sure_lib
ensure sure_lib_runtime_tests
```

## Commands

Run server-side tests from the server console:

```text
suretest:server
```

Run client-side tests from the in-game F8 console:

```text
suretest:client
```

Run both from a player command:

```text
suretest:all
```

## Database Tests

Database write tests are opt-in because they create and drop a temporary table named `sure_lib_runtime_users`.

Enable them with:

```cfg
setr sure_lib_runtime_db true
```

Then restart the test resource and run `suretest:server`.
