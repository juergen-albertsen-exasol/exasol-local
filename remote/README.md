# Remote Test Machine

This directory holds credentials for the Linux machine used to run integration tests.
**The contents of this directory (except this README) are gitignored.**

## Required files

| File | Contents |
|------|----------|
| `remote/host` | Hostname or IP address of the remote Linux machine (e.g. `192.168.1.42` or `my-linux-box.example.com`) |
| `remote/key.pem` | SSH private key (PEM format) with access to that machine |

## Setup

```bash
echo "your-hostname-or-ip" > remote/host
cp /path/to/your-key.pem remote/key.pem
chmod 600 remote/key.pem
```

## Running e2e tests

```bash
make e2e-tests
```

This runs the e2e test suite locally. Each test SSHes to the remote machine and executes
`curl ... | sh` as a real user would, then checks the resulting container state.
The remote machine must have Docker Engine installed.
