{
  "ignition": { "version": "3.0.0" },
  "passwd": {
    "users": [
      {
        "name": "root",
        "sshAuthorizedKeys": [
          "${public_key}"
        ]
      }
    ]
  }
}