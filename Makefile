prefix = /usr/local
bindir = $(prefix)/bin
sharedir = $(prefix)/share

name = $(notdir $(CURDIR))
script = $(name).sh
installed_script = $(bindir)/$(name)

include_path = $(sharedir)/$(name)

.PHONY: test
test:
	$(CURDIR)/test.sh

.PHONY: install
install: $(include_path)
	install $(script) $(installed_script)
	sed -i -e 's#\(\./\)\?$(script)#$(name)#g' $(installed_script)
	install --mode 644 shell-includes/error.sh $(include_path)
	install --mode 644 shell-includes/usage.sh $(include_path)
	install --mode 644 shell-includes/variables.sh $(include_path)
	install --mode 644 shell-includes/verbose_echo.sh $(include_path)
	sed -i -e 's#^\(includes=\).*#\1"$(include_path)"#g' $(installed_script)
	install --mode 644 etc/bash_completion.d/$(name) /etc/bash_completion.d/ || echo 'Could not install Bash completion'

$(include_path):
	mkdir $(include_path)

include tools.mk
