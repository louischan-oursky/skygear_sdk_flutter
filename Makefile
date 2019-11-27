.PHONY: format
format:
	dartfmt --overwrite --fix --set-exit-if-changed lib test
