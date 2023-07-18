# Developer documentation
This documentation is not for using but for developing this library.

## Setup
To setup with dependencies, run the following command:
```
yarn install --ignore-engines
```
Or even set this to the config permanently:
```
yarn config set ignore-engines true
```

We ignore engines, as the `jasmine` dependency "requires" a even version of node (12, 14, 16) which is bullshit.