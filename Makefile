.PHONY: default
default: install

.PHONY: install
install:
	sh make.sh install

.PHONY: prepare
prepare:
	sh make.sh prepare

.PHONY: clean
clean:
	sh make.sh clean
