# its-package

## setup

```sh
. /etc/os-release \
&& wget \
	-O /tmp/bootstrap.sh \
	https://raw.githubusercontent.com/stvstnfrd/its-package/master/dist/${ID}/${VERSION_CODENAME}/Bootstrap.sh \
&& less -+F /tmp/bootstrap.sh \
&& sh /tmp/bootstrap.sh \
;
```

## install

```sh
sudo apt-get install its-package
```
